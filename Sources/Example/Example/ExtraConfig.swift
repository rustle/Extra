//
//  ExtraConfig.swift
//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import Extra
import ExtraShared

public struct ExtraConfig: XPCConfig {
    let connection: Connection
    public init() {
        connection = Connection(serviceName: "com.rustle.ExtraService")
        let uppercase = ExtraUppercase()
        connection.replyingInterfaces = [
            ExtraUppercase.identifier: AnyReplyingInterface(interface: uppercase),
        ]
        let debugPrint = ExtraDebugPrint()
        connection.onewayInterfaces = [
            ExtraDebugPrint.identifier: AnyOnewayVoidInterface(interface: debugPrint),
        ]
    }
    public func activate() {
        connection.activate()
    }
    public func doSomething() {
        do {
            try connection
                .send(interface: ExtraUppercase.self,
                      input: "extra") { result in
                    switch result {
                    case .success(let output):
                        self.handle(output: output)
                    case .failure(let error):
                        self.handle(error: error)
                    }
                }
            try connection
                .send(interface: ExtraDebugPrint.self,
                      input: "starting in \(getpid())")
        } catch {
            handle(error: error)
        }
    }
    func handle<E: Error>(error: E) {
        if let connectionError = error as? Connection.ConnectionError {
            switch connectionError {
            case .connectionInterrupted:
                debugPrint("Connection Interrupted")
            case .connectionInvalid:
                debugPrint("Connection Invalid")
            case .terminationImminent:
                debugPrint("Termination Imminent")
            case .unexpectedMessage(let message):
                debugPrint(String(cString: xpc_copy_description(message),
                                  encoding: .utf8) ?? "\(message)")
            case .other(let description):
                debugPrint(description)
            }
        } else {
            debugPrint(error)
        }
    }
    func handle(output: String) {
        debugPrint("Uppercase: \(output)")
    }
}
