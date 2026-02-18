import SwiftUI

@main
struct DenApp: App {
    @State private var syncEngine = SyncEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncEngine)
                .task {
                    await syncEngine.start()
                }
        }
    }
}
