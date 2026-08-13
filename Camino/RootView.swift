import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Journey.startedAt) private var journeys: [Journey]
    @AppStorage("camino.disclaimer.accepted") private var disclaimerAccepted = false
    @State private var startingAgain = false

    private var calendar: Calendar { .current }
    private var walking: Journey? { journeys.first { $0.arrivedAt == nil } }
    private var latest: Journey? { journeys.max(by: { $0.startedAt < $1.startedAt }) }

    var body: some View {
        Group {
            if let walking {
                NavigationStack {
                    CaminoView(journey: walking, calendar: calendar)
                }
            } else if let arrived = latest, arrived.arrivedAt != nil, !startingAgain {
                NavigationStack {
                    CaminoView(journey: arrived, calendar: calendar)
                }
            } else if disclaimerAccepted || latest != nil {
                firstPromise
            } else {
                DisclaimerView {
                    disclaimerAccepted = true
                }
            }
        }
        .tint(CaminoTheme.amber)
        .onReceive(NotificationCenter.default.publisher(for: .caminoBeginAgain)) { _ in
            startingAgain = true
        }
        .onChange(of: walking?.id) { _, new in
            if new != nil {
                startingAgain = false
            }
        }
    }

    private var firstPromise: some View {
        ProtocolEditorView(
            journey: nil,
            isFirst: true,
            calendar: calendar,
            onFinished: {
                startingAgain = false
            }
        )
        .preferredColorScheme(.dark)
    }
}
