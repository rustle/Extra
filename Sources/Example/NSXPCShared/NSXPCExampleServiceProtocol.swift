//
//  NSXPCExampleServiceProtocol.swift
//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation

@objc
public protocol NSXPCExampleServiceProtocol {
    func upperCase(_ string: String,
                   with reply: @escaping ((String) -> Void))
    func debugPrint(_ string: String)
}
