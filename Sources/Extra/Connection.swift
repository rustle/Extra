//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import XPC
import CodableXPC

public class Connection {
    let connection: xpc_connection_t
    let canCreateListenerEndpoints: Bool
    @Atomic public var replyingInterfaces = [InterfaceIdentifier:AnyReplyingInterface]()
    @Atomic public var onewayInterfaces = [InterfaceIdentifier:AnyOnewayVoidInterface]()
    private let queue = DispatchQueue(label: "Extra.Connection",
                                      qos: .default,
                                      attributes: [],
                                      autoreleaseFrequency: .workItem,
                                      target: nil)
    public init(serviceName: String) {
        connection = xpc_connection_create(serviceName,
                                           queue)
        canCreateListenerEndpoints = false
        xpc_connection_set_event_handler(connection,
                                         receive(input:))
    }
    public init(machServiceName: String) {
        connection = xpc_connection_create_mach_service(machServiceName,
                                                        queue,
                                                        0)
        canCreateListenerEndpoints = true
        xpc_connection_set_event_handler(connection,
                                         receive(input:))
    }
    public init(endpoint: Endpoint) {
        connection =
            xpc_connection_create_from_endpoint(endpoint.endpoint)
        canCreateListenerEndpoints = false
        xpc_connection_set_event_handler(connection,
                                         receive(input:))
    }
    public init(connection: xpc_connection_t) {
        self.connection = connection
        canCreateListenerEndpoints = false
        xpc_connection_set_event_handler(connection,
                                         receive(input:))
    }
    init?(dictionary: xpc_object_t) {
        guard let connection = xpc_dictionary_get_remote_connection(dictionary) else {
            return nil
        }
        self.connection = connection
        canCreateListenerEndpoints = false
    }
    public func activate() {
        xpc_connection_activate(connection)
    }
    public func suspend() {
        xpc_connection_suspend(connection)
    }
    public func cancel() {
        xpc_connection_cancel(connection)
    }
    public enum ConnectionError: Error {
        case connectionInterrupted
        case connectionInvalid
        case terminationImminent
        case unexpectedMessage(xpc_object_t)
        case other(String)
    }
    private func decode<T: Codable>(type: T.Type,
                                    message: xpc_object_t) throws -> Message<T> {
        switch try message.getType() {
        case .error(let description):
            if message === XPC_ERROR_CONNECTION_INTERRUPTED {
                throw ConnectionError.connectionInterrupted
            } else if message === XPC_ERROR_CONNECTION_INVALID {
                throw ConnectionError.connectionInvalid
            } else if message === XPC_ERROR_TERMINATION_IMMINENT {
                throw ConnectionError.terminationImminent
            } else {
                throw ConnectionError.other(description)
            }
        case .dictionary:
            return try XPCDecoder.decode(Message<T>.self,
                                         message: message)
        default:
            throw ConnectionError.unexpectedMessage(message)
        }
    }
    public func send<I: ReplyingInterface>(interface: I.Type,
                                           input: I.Input,
                                           outputHandler: @escaping (Result<I.Output, Error>) -> Void) throws {
        let message = try Message(interface: interface,
                                  value: input)
            .toXPC()
        self.send(message: message) { replyMessage in
            do {
                let output = try self.decode(type: I.Output.self,
                                             message: replyMessage)
                outputHandler(.success(output.value))
            } catch {
                outputHandler(.failure(error))
            }
        }
    }
    public func send<I: OnewayVoidInterface>(interface: I.Type,
                                             input: I.Input) throws {
        let message = try Message(interface: interface,
                                  value: input)
            .toXPC()
        send(message: message)
    }
    func send(message: xpc_object_t,
              replyHandler: @escaping (xpc_object_t) -> Void) {
        assert(xpc_get_type(message) == XPC_TYPE_DICTIONARY)
        xpc_dictionary_set_bool(message,
                                "__extra__replying",
                                true)
        xpc_connection_send_message_with_reply(connection,
                                               message,
                                               queue,
                                               replyHandler)
    }
    func send(message: xpc_object_t) {
        xpc_connection_send_message(connection,
                                    message)
    }
    private func receive(input: xpc_object_t) {
        do {
            switch try input.getType() {
            case .error(let description):
                if input === XPC_ERROR_CONNECTION_INTERRUPTED {
                    throw ConnectionError.connectionInterrupted
                } else if input === XPC_ERROR_CONNECTION_INVALID {
                    throw ConnectionError.connectionInvalid
                } else if input === XPC_ERROR_TERMINATION_IMMINENT {
                    throw ConnectionError.terminationImminent
                } else {
                    throw ConnectionError.other(description)
                }
            case .dictionary:
                guard let identifier = input.unsignedInteger(for: "__extra__identifier") else {
                    throw ConnectionError.unexpectedMessage(input)
                }
                if input.bool(for: "__extra__replying") {
                    guard let interface = self.replyingInterfaces[identifier] else {
                        throw ConnectionError.unexpectedMessage(input)
                    }
                    interface.receive(input: input) { result in
                        self.receive(input: input,
                                     result: result)
                    }
                } else {
                    guard let interface = self.onewayInterfaces[identifier] else {
                        throw ConnectionError.unexpectedMessage(input)
                    }
                    interface.receive(input: input)
                }
            default:
                throw ConnectionError.unexpectedMessage(input)
            }
        } catch {
            debugPrint(error)
        }
    }
    private func receive(input: xpc_object_t,
                         result: Result<xpc_object_t, Error>) {
        guard
            let reply = xpc_dictionary_create_reply(input),
            let connection = Connection(dictionary: input)
        else {
            debugPrint("\(ConnectionError.unexpectedMessage(input))")
            return
        }
        switch result {
        case .success(let value):
            assert(xpc_get_type(value) == XPC_TYPE_DICTIONARY)
            xpc_dictionary_apply(value) { key, value in
                xpc_dictionary_set_value(reply,
                                         key,
                                         value)
                return true
            }
            connection.send(message: reply)
        case .failure(let error):
            debugPrint("\(error)")
        }
    }
}
