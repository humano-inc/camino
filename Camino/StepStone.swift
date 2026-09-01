import SwiftUI

struct StepStone: View {
    var event: ScheduledEvent
    var calendar: Calendar
    var prominent: Bool
    var action: () -> Void

    @ScaledMetric(relativeTo: .title2) private var openSize: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var settledSize: CGFloat = 17

    var body: some View {
        Button(action: action) {
            HStack(spacing: prominent ? 11 : 10) {
                mark
                label
                Spacer(minLength: 0)
            }
            .padding(.horizontal, prominent ? 20 : 17)
            .padding(.vertical, prominent ? 17 : 13)
            .frame(width: prominent ? 238 : 190, alignment: .leading)
            .frame(minHeight: 44)
            .background(stoneFill, in: UnevenRoundedRectangle(topLeadingRadius: prominent ? 5 : 4, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: prominent ? 5 : 4))
            .overlay(alignment: .top) {
                if event.isOpen {
                    Rectangle()
                        .fill(CaminoTheme.stoneEdge.opacity(0.75))
                        .frame(height: 1.5)
                }
            }
            .shadow(color: .black.opacity(prominent ? 0.5 : 0.4), radius: prominent ? 14 : 8, y: prominent ? 10 : 6)
        }
        .buttonStyle(.plain)
        .rotation3DEffect(.degrees(15), axis: (x: 1, y: 0, z: 0), perspective: 0.45)
        .accessibilityLabel(voiceOver)
        .accessibilityHint("Opens confirm")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var mark: some View {
        let size: CGFloat = prominent ? 13 : 12
        switch event.status {
        case .open:
            Circle()
                .stroke(CaminoTheme.stoneEdge.opacity(0.9), lineWidth: 2)
                .frame(width: size, height: size)
        case .taken:
            Circle()
                .fill(Color(red: 0.94, green: 0.90, blue: 0.82).opacity(0.85))
                .frame(width: size, height: size)
        case .less:
            ZStack {
                Circle()
                    .stroke(Color(red: 0.94, green: 0.90, blue: 0.82).opacity(0.6), lineWidth: 1.5)
                Circle()
                    .fill(Color(red: 0.94, green: 0.90, blue: 0.82).opacity(0.85))
                    .frame(width: size / 2, height: size)
                    .offset(x: -size / 4)
                    .clipShape(Circle())
            }
            .frame(width: size, height: size)
        case .skipped:
            Capsule()
                .fill(Color(red: 0.94, green: 0.90, blue: 0.82).opacity(0.7))
                .frame(width: size, height: 3)
        case .delayed:
            Image(systemName: "arrow.right")
                .font(.system(size: size - 2, weight: .semibold))
                .foregroundStyle(Color(red: 0.94, green: 0.90, blue: 0.82).opacity(0.7))
                .frame(width: size, height: size)
        }
    }

    @ViewBuilder
    private var label: some View {
        let time = CaminoFormat.time(hour: event.hour, minute: event.minute, calendar: calendar)
        switch event.status {
        case .open:
            Text("\(time) · \(formatMg(event.plannedAmountMg))")
                .font(.system(size: openSize, weight: .semibold))
                .foregroundStyle(CaminoTheme.cream)
        case .taken:
            Text("\(time) · \(formatMg(event.actualAmountMg ?? event.plannedAmountMg))")
                .font(.system(size: settledSize, weight: .regular))
                .foregroundStyle(CaminoTheme.cream.opacity(0.75))
        case .less:
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("\(time) · \(formatMg(event.actualAmountMg ?? 0))")
                    .font(.system(size: settledSize, weight: .regular))
                    .foregroundStyle(CaminoTheme.cream.opacity(0.75))
                Text("of \(formatMg(event.plannedAmountMg))")
                    .font(.system(size: 12))
                    .foregroundStyle(CaminoTheme.cream.opacity(0.45))
            }
        case .skipped:
            Text("\(time) · skipped")
                .font(.system(size: settledSize, weight: .regular))
                .foregroundStyle(CaminoTheme.cream.opacity(0.62))
        case .delayed:
            Text("\(time) · \(Copy.delayedStone)")
                .font(.system(size: settledSize, weight: .regular))
                .foregroundStyle(CaminoTheme.cream.opacity(0.62))
        }
    }

    private var stoneFill: LinearGradient {
        if event.isOpen {
            return LinearGradient(
                colors: [CaminoTheme.stoneTop, CaminoTheme.stoneMid, CaminoTheme.stoneBot],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [
                Color(red: 0.224, green: 0.255, blue: 0.318).opacity(0.44),
                Color(red: 0.165, green: 0.188, blue: 0.243),
                Color(red: 0.137, green: 0.161, blue: 0.212)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var voiceOver: String {
        let time = CaminoFormat.time(hour: event.hour, minute: event.minute, calendar: calendar)
        switch event.status {
        case .open:
            return Copy.voStepOpen(time: time, amount: formatMg(event.plannedAmountMg))
        case .taken:
            return Copy.voStepTaken(time: time, amount: formatMg(event.actualAmountMg ?? event.plannedAmountMg))
        case .less:
            return Copy.voStepLess(
                time: time,
                planned: formatMg(event.plannedAmountMg),
                actual: formatMg(event.actualAmountMg ?? 0)
            )
        case .skipped:
            return Copy.voStepSkipped(time: time)
        case .delayed:
            return Copy.voStepDelayed(time: time)
        }
    }
}
