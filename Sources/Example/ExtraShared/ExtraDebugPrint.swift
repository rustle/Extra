//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import Extra

public struct ExtraDebugPrint: OnewayVoidInterface {
    public typealias Input = String
    public func receive(input: String) {
        debugPrint("ExtraDebugPrint, \(input), ending up in \(getpid())")
    }
    public init() {}
}
