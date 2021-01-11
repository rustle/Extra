//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import CXPCShared

func receive(connection: xpc_connection_t) {
    xpc_connection_set_event_handler(connection,
                                     receive(message:))
    xpc_connection_activate(connection)
}

func receive(message: xpc_object_t) {
    let type = xpc_get_type(message)
    switch type {
    case XPC_TYPE_ERROR:
        return
    case XPC_TYPE_CONNECTION:
        return
    case XPC_TYPE_DICTIONARY:
        guard let identifier = CXPCShared.Identifier(rawValue: xpc_dictionary_get_int64(message,
                                                                                        "identifier")) else {
            fatalError()
        }
        switch identifier {
        case .uppercase:
            guard let cString = xpc_dictionary_get_string(message,
                                                          "uppercase")  else {
                fatalError()
            }
            guard let string = String(cString: cString,
                                      encoding: .utf8) else {
                fatalError()
            }
            guard let reply = xpc_dictionary_create_reply(message) else {
                fatalError()
            }
            guard let connection = xpc_dictionary_get_remote_connection(message) else {
                fatalError()
            }
            let uppercase = string.uppercased()
            xpc_dictionary_set_string(reply,
                                      "uppercase",
                                      uppercase)
            xpc_connection_send_message(connection,
                                        reply)
        case .debugPrint:
            guard let cString = xpc_dictionary_get_string(message,
                                                          "value")  else {
                fatalError()
            }
            guard let string = String(cString: cString,
                                      encoding: .utf8) else {
                fatalError()
            }
            debugPrint("CXPCDebugPrint, \(string), ending up in \(getpid())")
        }
    default:
        fatalError()
    }
}

@main
struct CXPC {
    static func main() {
        xpc_main(receive(connection:))
    }
}
