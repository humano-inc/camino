import SwiftUI
import SwiftData
import Charts

struct LookBackView: View {
    var journey: Journey
    var calendar: Calendar

    @Query(sort: \Journey.startedAt) private var journeys: [Journey]
    @State private var exportURL: URL?
    @State private var confirmAgain = false
    @State private var noteTarget: RescueNoteTarget?

    private var week: WeekLoad { Ledger.thisWeek(on: journey, now: .now, calendar: calendar) }
    private var weeks: [WeekLoad] { Ledger.weekLoads(on: journey, now: .now, calendar: calendar) }
    private var timeline: [Ledger.NightRow] { Ledger.timeline(on: journey, calendar: calendar) }

    var body: some View {
        List {
            thisWeekSection
            if weeks.count > 1 {
                weeksSection
            } else {
                Section {
                    Text(Copy.emptyWeek)
                        .foregroundStyle(.secondary)
                }
            }
            promisesSection
            nightsSection
            exportSection
            if journey.isArrived {
                beginAgainSection
            }
        }
        .navigationTitle(Copy.lookBack)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $noteTarget) { target in
            if let rescue = journey.rescues.first(where: { $0.id == target.id }) {
                RescueNoteEditor(rescue: rescue, calendar: calendar)
            }
        }
        .confirmationDialog(Copy.beginAgainTitle, isPresented: $confirmAgain, titleVisibility: .visible) {
            Button(Copy.beginAgain) {
                NotificationCenter.default.post(name: .caminoBeginAgain, object: nil)
            }
            Button(Copy.cancel, role: .cancel) {}
        } message: {
            Text(Copy.beginAgainBody)
        }
    }

    private var thisWeekSection: some View {
        Section(Copy.thisWeek) {
            HStack(spacing: 8) {
                metric(formatMg(week.actualMg), Copy.actual + " mg")
                metric(formatMg(week.plannedMg), Copy.planned + " mg")
                metric(formatMg(week.rescueMg), "\(Copy.rescue) · \(week.rescueCount)")
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var weeksSection: some View {
        Section(Copy.weeks) {
            Chart(weeks, id: \.weekStart) { load in
                BarMark(
                    x: .value("Week", load.weekStart, unit: .weekOfYear),
                    y: .value(Copy.planned, load.plannedMg)
                )
                .foregroundStyle(Color.secondary.opacity(0.35))
                BarMark(
                    x: .value("Week", load.weekStart, unit: .weekOfYear),
                    y: .value(Copy.actual, load.actualMg)
                )
                .foregroundStyle(Color.primary)
            }
            .frame(height: 160)
            .accessibilityLabel("Weekly promised and taken")
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.day().month(.abbreviated))
                        }
                    }
                }
            }
        }
    }

    private var promisesSection: some View {
        Section(Copy.promises) {
            ForEach(journey.protocolVersions.sorted { $0.startedAt > $1.startedAt }, id: \.id) { version in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(formatMg(version.weeklyPlannedMg)) mg / week")
                    Text(CaminoFormat.range(started: version.startedAt, ended: version.endedAt, calendar: calendar))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var nightsSection: some View {
        Section(Copy.nights) {
            let rows = timeline
            if rows.isEmpty {
                Text("—")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rows) { row in
                    switch row {
                    case .night(let event):
                        nightRow(event)
                    case .rescue(let rescue):
                        rescueRow(rescue)
                    }
                }
            }
        }
    }

    private func nightRow(_ event: ScheduledEvent) -> some View {
        HStack(spacing: 8) {
            statusMark(event.status)
                .frame(width: 20, alignment: .leading)
            Text(nightWord(event.status))
                .foregroundStyle(event.status == .skipped ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
            Spacer()
            Text(nightDetail(event))
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }

    private func rescueRow(_ rescue: RescueDose) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                RainStrokes()
                    .stroke(CaminoTheme.rain, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                    .frame(width: 14, height: 14)
                    .frame(width: 20, alignment: .leading)
                Text(Copy.rescue)
                    .foregroundStyle(CaminoTheme.rain)
                Spacer()
                Text(rescueDetail(rescue))
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                if !journey.isArrived {
                    Button {
                        noteTarget = RescueNoteTarget(id: rescue.id)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Copy.note)
                }
            }
            if let note = rescue.note {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(.leading, 28)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rescueAccessibility(rescue))
    }

    @ViewBuilder
    private func statusMark(_ status: EventStatus) -> some View {
        let size: CGFloat = 13
        switch status {
        case .taken, .open:
            Circle()
                .fill(CaminoTheme.amber)
                .frame(width: size, height: size)
        case .less:
            ZStack {
                Circle()
                    .stroke(CaminoTheme.amber, lineWidth: 1.5)
                Circle()
                    .fill(CaminoTheme.amber)
                    .frame(width: size / 2, height: size)
                    .offset(x: -size / 4)
                    .clipShape(Circle())
            }
            .frame(width: size, height: size)
        case .skipped:
            Capsule()
                .fill(Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.35))
                .frame(width: size, height: 3)
        }
    }

    private func nightWord(_ status: EventStatus) -> String {
        switch status {
        case .skipped: return Copy.skipped
        case .less: return Copy.lessThanPromised
        case .taken, .open: return Copy.taken
        }
    }

    private var exportSection: some View {
        Section {
            ShareLink(item: exportFile()) {
                Text(Copy.exportJourney)
            }
        }
    }

    private var beginAgainSection: some View {
        Section {
            Button(Copy.beginAgain) { confirmAgain = true }
                .foregroundStyle(.secondary)
        }
    }

    private func rescueDetail(_ rescue: RescueDose) -> String {
        let day = CaminoFormat.weekdayDate(rescue.takenAt, calendar: calendar)
        if rescue.isOverflow, let event = linkedEvent(rescue) {
            let slot = CaminoFormat.time(hour: event.hour, minute: event.minute, calendar: calendar)
            return "\(formatMg(rescue.amountMg)) · \(Copy.fromSlotPrefix) \(slot) · \(day)"
        }
        let time = rescue.takenAt.formatted(date: .omitted, time: .shortened)
        return "\(formatMg(rescue.amountMg)) · \(time) · \(day)"
    }

    private func rescueAccessibility(_ rescue: RescueDose) -> String {
        var parts = [Copy.rescue, "\(formatMg(rescue.amountMg)) milligrams", rescue.takenAt.formatted()]
        if let note = rescue.note { parts.append(note) }
        return parts.joined(separator: ", ")
    }

    private func nightDetail(_ event: ScheduledEvent) -> String {
        let day = CaminoFormat.weekdayDate(event.dayStart, calendar: calendar)
        switch event.status {
        case .less:
            return "\(formatMg(event.plannedAmountMg)) → \(formatMg(event.actualAmountMg ?? 0)) · \(day)"
        case .taken, .open:
            return "\(formatMg(event.actualAmountMg ?? event.plannedAmountMg)) · \(day)"
        case .skipped:
            return "\(formatMg(event.plannedAmountMg)) · \(day)"
        }
    }

    private func linkedEvent(_ rescue: RescueDose) -> ScheduledEvent? {
        guard let id = rescue.linkedScheduledId else { return nil }
        return journey.events.first { $0.id == id }
    }

    private func exportFile() -> URL {
        if let exportURL { return exportURL }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("camino-journey.json")
        if let data = try? JourneyExport.jsonData(journeys: Array(journeys)) {
            try? data.write(to: url, options: .atomic)
        }
        return url
    }
}

private struct RescueNoteTarget: Identifiable {
    var id: UUID
}

/// Three slanted strokes, the scene's rain at ledger scale.
private struct RainStrokes: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width / 14
        let h = rect.height / 14
        var path = Path()
        path.move(to: CGPoint(x: 5.2 * w, y: 1.5 * h))
        path.addLine(to: CGPoint(x: 3.2 * w, y: 8 * h))
        path.move(to: CGPoint(x: 10.6 * w, y: 3.5 * h))
        path.addLine(to: CGPoint(x: 8.6 * w, y: 10 * h))
        path.move(to: CGPoint(x: 7.4 * w, y: 8.5 * h))
        path.addLine(to: CGPoint(x: 5.9 * w, y: 13 * h))
        return path
    }
}

extension Notification.Name {
    static let caminoBeginAgain = Notification.Name("camino.beginAgain")
}
