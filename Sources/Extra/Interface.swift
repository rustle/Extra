//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import XPC
import CodableXPC

private extension String {
    // Any hash that will be the same in all your processes will do
    func stableHash() -> UInt64 {
        var hash = UInt64(14695981039346656037)
        for byte in self.utf8 {
            hash = hash &* UInt64(1099511628211) // &* means multiply with overflow
            hash ^= UInt64(byte)
        }
        return hash
    }
}

private extension UInt64 {
    func mix(_ mix: UInt64) -> UInt64 {
        let seed = UInt64(0x41B2E73FBFA0C587)
        var a = UInt64((self ^ mix) &* seed)
        a ^= (a >> 47)
        var b = UInt64((mix ^ a) &* seed)
        b ^= (b >> 47)
        b = b &* seed
        return b
    }
}

public typealias InterfaceIdentifier = UInt64

public protocol Interface {
    static var identifier: InterfaceIdentifier { get }
    associatedtype Input: Codable
    func encode(input: Message<Input>) throws -> xpc_object_t
    func decode(input: xpc_object_t) throws -> Message<Input>
}

public extension Interface {
    func encode(input: Message<Input>) throws -> xpc_object_t {
        try input.toXPC()
    }
    func decode(input: xpc_object_t) throws -> Message<Input> {
        try input.fromXPC(Message<Input>.self)
    }
}

public protocol OnewayVoidInterface: Interface {
    func receive(input: Input)
}

public extension OnewayVoidInterface {
    static var identifier: InterfaceIdentifier {
        // This is pretty gross.
        // Overriding this with something that isn't computed is a good idea.
        return String(describing: type(of: self)).stableHash()
            .mix(String(describing: Input.self).stableHash())
    }
}

public protocol ReplyingInterface: Interface {
    associatedtype Output: Codable
    func receive(input: Input,
                 outputHandler: @escaping (Result<Output, Error>) -> Void)
    func encode(output: Message<Output>) throws -> xpc_object_t
    func decode(output: xpc_object_t) throws -> Message<Output>
}

public extension ReplyingInterface {
    static var identifier: InterfaceIdentifier {
        // This is pretty gross.
        // Overriding this with something that isn't
        // computed is a good idea.
        return String(describing: type(of: self)).stableHash()
            .mix(String(describing: Input.self).stableHash())
            .mix(String(describing: Output.self).stableHash())
    }
    func encode(output: Message<Output>) throws -> xpc_object_t {
        try XPCEncoder.encode(output)
    }
    func decode(output: xpc_object_t) throws -> Message<Output> {
        try XPCDecoder.decode(Message<Output>.self,
                              message: output)
    }
}

public struct AnyOnewayVoidInterface {
    public let identifier: InterfaceIdentifier
    private let _receive: (xpc_object_t) -> Void
    public init<I: OnewayVoidInterface>(interface: I) {
        identifier = type(of: interface).identifier
        _receive = { input in
            let decodedInput: I.Input
            do {
                let message = try interface.decode(input: input)
                decodedInput = message.value
            } catch {
                fatalError("\(error)")
            }
            interface.receive(input: decodedInput)
        }
    }
    public func receive(input: xpc_object_t) {
        _receive(input)
    }
}

public struct AnyReplyingInterface {
    public let identifier: InterfaceIdentifier
    private let _receiveInput: (xpc_object_t, @escaping (Result<xpc_object_t, Error>) -> Void) -> Void
    public init<I: ReplyingInterface>(interface: I) {
        identifier = type(of: interface).identifier
        _receiveInput = { input, outputHandler in
            let decodedInput: I.Input
            do {
                let message = try interface.decode(input: input)
                decodedInput = message.value
            } catch {
                fatalError("\(error)")
            }
            interface.receive(input: decodedInput) { result in
                switch result {
                case .success(let value):
                    do {
                        let output = try interface.encode(output: Message(interface: type(of: interface),
                                                                          value: value))
                        outputHandler(.success(output))
                    } catch {
                        outputHandler(.failure(error))
                    }
                case .failure(let error):
                    outputHandler(.failure(error))
                }
            }
        }
    }
    func receive(input: xpc_object_t,
                 outputHandler: @escaping (Result<xpc_object_t, Error>) -> Void) {
        _receiveInput(input,
                      outputHandler)
    }
}
