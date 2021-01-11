//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import CodableXPC

extension Encodable {
    func toXPC() throws -> xpc_object_t {
        try XPCEncoder
            .encode(self)
    }
}
