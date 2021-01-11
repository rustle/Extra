//
//  ExampleService.swift
//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import NSXPCShared

class NSXPCExampleService: NSObject, NSXPCExampleServiceProtocol {
    func upperCase(_ string: String,
                   with reply: ((String) -> Void)) {
        reply(string.uppercased())
    }
    func debugPrint(_ string: String) {
        Swift.debugPrint("NSXPCDebugPrint, \(string), ending up in \(getpid())")
    }
}
