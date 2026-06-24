import SwiftData
import SwiftUI

@main
struct FinTrackApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(FinTrackModelContainer.shared)
    }
}
