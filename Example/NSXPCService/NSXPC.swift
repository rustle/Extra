//
//  NSXPC.swift
//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation

@main
struct NSXPC {
    static func main() {
        let delegate = NSXPCServiceDelegate()
        let listener = NSXPCListener.service()
        listener.delegate = delegate
        listener.resume()
    }
}
