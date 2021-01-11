//
//  CXPCConfig.swift
//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import XPC
import CXPCShared

public struct CXPCConfig: XPCConfig {
    let connection: xpc_connection_t
    public init() {
        connection = xpc_connection_create("com.rustle.CXPCService",
                                           DispatchQueue.main)
        xpc_connection_set_event_handler(connection) { _ in }
    }
    public func activate() {
        xpc_connection_activate(connection)
    }
    public func doSomething() {
        uppercase()
        debugPrint()
    }
    func uppercase() {
        let message = xpc_dictionary_create(nil,
                                            nil,
                                            0)
        xpc_dictionary_set_string(message,
                                  "uppercase",
                                  "cxpc")
        xpc_dictionary_set_bool(message,
                                "replying",
                                true)
        xpc_dictionary_set_int64(message,
                                 "identifier",
                                 CXPCShared.Identifier.uppercase.rawValue)
        xpc_connection_send_message_with_reply(connection,
                                               message,
                                               DispatchQueue.main) { replyMessage in
            let type = xpc_get_type(replyMessage)
            switch type {
            case XPC_TYPE_ERROR:
                return
            case XPC_TYPE_CONNECTION:
                return
            case XPC_TYPE_DICTIONARY:
                guard let cString = xpc_dictionary_get_string(replyMessage,
                                                              "uppercase")  else {
                    fatalError()
                }
                guard let string = String(cString: cString,
                                          encoding: .utf8) else {
                    fatalError()
                }
                Swift.debugPrint("Uppercase: \(string)")
            default:
                return
            }
        }
    }
    func debugPrint() {
        let message = xpc_dictionary_create(nil,
                                            nil,
                                            0)
        xpc_dictionary_set_string(message,
                                  "value",
                                  "starting in \(getpid())")
        xpc_dictionary_set_int64(message,
                                 "identifier",
                                 CXPCShared.Identifier.debugPrint.rawValue)
        xpc_connection_send_message(connection,
                                    message)
    }
}
