//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import SwiftUI
import Example
import Extra
import ExtraShared

@main
final class ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            Group {
                Text("Hello")
                    .padding()
            }
        }
    }
    let configs: [XPCConfig]
    init() {
        configs = [
            NSXPCConfig(),
            CXPCConfig(),
            ExtraConfig(),
        ]
        configs.forEach { $0.activate() }
        configs.forEach { $0.doSomething() }
    }
}
