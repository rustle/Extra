//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import XPC

public struct Endpoint {
    let endpoint: xpc_endpoint_t
    init(endpoint: xpc_endpoint_t) {
        self.endpoint = endpoint
    }
    public init(connection: Connection) {
        precondition(connection.canCreateListenerEndpoints)
        endpoint = xpc_endpoint_create(connection.connection)
    }
}
