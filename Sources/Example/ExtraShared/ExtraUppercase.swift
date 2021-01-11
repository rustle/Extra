//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import Extra

public struct ExtraUppercase: ReplyingInterface {
    public typealias Input = String
    public typealias Output = String
    public func receive(input: String,
                        outputHandler: @escaping (Result<String, Error>) -> Void) {
        outputHandler(.success(input.uppercased()))
    }
    public init() {}
}
