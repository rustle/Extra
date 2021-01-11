//
//  NSXPCServiceDelegate.swift
//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import NSXPCShared

@objcMembers
public class NSXPCServiceDelegate: NSObject, NSXPCListenerDelegate {
    public func listener(_ listener: NSXPCListener,
                         shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: NSXPCExampleServiceProtocol.self)
        newConnection.exportedObject = NSXPCExampleService()
        newConnection.resume()
        return true
    }
}
