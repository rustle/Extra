//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import XPC

private func receive(connection: xpc_connection_t) {
    let connection = Connection(connection: connection)
    connection.replyingInterfaces = ServiceListener.replyingInterfaces
    connection.onewayInterfaces = ServiceListener.onewayInterfaces
    ServiceListener.connection = connection
    connection.activate()
}

public struct ServiceListener {
    static var connection: Connection?
    @Atomic public static var replyingInterfaces = [InterfaceIdentifier:AnyReplyingInterface]()
    @Atomic public static var onewayInterfaces = [InterfaceIdentifier:AnyOnewayVoidInterface]()
    public static func main() -> Never {
        xpc_main(receive(connection:))
    }
}
