import SwiftUI
import SwiftData

@main
struct CaminoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            Journey.self,
            ProtocolVersion.self,
            DoseSlot.self,
            ScheduledEvent.self,
            RescueDose.self
        ])
    }
}
