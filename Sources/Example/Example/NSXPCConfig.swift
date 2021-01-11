//
//  NSXPCConfig.swift
//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import NSXPCShared

public struct NSXPCConfig: XPCConfig {
    let connection: NSXPCConnection
    public init() {
        connection = NSXPCConnection(serviceName: "com.rustle.NSXPCService")
        connection.remoteObjectInterface = NSXPCInterface(with: NSXPCExampleServiceProtocol.self)
        connection.invalidationHandler = {
            debugPrint("invalidate")
        }
    }
    public func activate() {
        connection.resume()
    }
    public func doSomething() {
        guard let proxy = connection.remoteObjectProxy as? NSXPCExampleServiceProtocol else {
            return
        }
        proxy
            .upperCase("nsxpc") { value in
                debugPrint("Uppercase: \(value)")
            }
        proxy
            .debugPrint("starting in \(getpid())")
    }
}
