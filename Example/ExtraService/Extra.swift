//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import Extra
import ExtraShared

@main
struct Extra {
    static func main() {
        let uppercase = ExtraUppercase()
        ServiceListener.replyingInterfaces = [
            ExtraUppercase.identifier: AnyReplyingInterface(interface: uppercase)
        ]
        let debugPrint = ExtraDebugPrint()
        ServiceListener.onewayInterfaces = [
            ExtraDebugPrint.identifier: AnyOnewayVoidInterface(interface: debugPrint),
        ]
        ServiceListener.main()
    }
}
