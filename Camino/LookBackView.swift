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
    private var nightFacts: [ScheduledEvent] { Ledger.nights(on: journey) }
    private var recentRescues: [RescueDose] {
        journey.rescues.sorted { $0.takenAt > $1.takenAt }
    }

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
            rescuesSection
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
            if let rescue = recentRescues.first(where: { $0.id == target.id }) {
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

    private var rescuesSection: some View {
        Section(Copy.rescues) {
            let items = recentRescues
            if items.isEmpty {
                Text(Copy.noRescues)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.id) { rescue in
                    HStack(alignment: .top, spacing: 8) {
                        rescueFacts(rescue)
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
            if nightFacts.isEmpty {
                Text("—")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(nightFacts, id: \.id) { event in
                    HStack {
                        Text(event.status == .skipped ? Copy.skipped : Copy.lessThanPromised)
                        Spacer()
                        Text(nightDetail(event))
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
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

    private func rescueFacts(_ rescue: RescueDose) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(formatMg(rescue.amountMg)) · \(rescue.takenAt.formatted(date: .omitted, time: .shortened))")
                Spacer()
                HStack(spacing: 6) {
                    if rescue.isOverflow, let event = linkedEvent(rescue) {
                        Text("\(Copy.fromSlotPrefix) \(CaminoFormat.time(hour: event.hour, minute: event.minute, calendar: calendar))")
                            .foregroundStyle(.secondary)
                    }
                    Text(CaminoFormat.weekdayDate(rescue.takenAt, calendar: calendar))
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
            if let note = rescue.note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rescueAccessibility(rescue))
    }

    private func rescueAccessibility(_ rescue: RescueDose) -> String {
        var parts = ["\(formatMg(rescue.amountMg)) milligrams", rescue.takenAt.formatted()]
        if let note = rescue.note { parts.append(note) }
        return parts.joined(separator: ", ")
    }

    private func nightDetail(_ event: ScheduledEvent) -> String {
        let day = CaminoFormat.weekdayDate(event.dayStart, calendar: calendar)
        if event.status == .less {
            return "\(formatMg(event.plannedAmountMg)) → \(formatMg(event.actualAmountMg ?? 0)) · \(day)"
        }
        return "\(formatMg(event.plannedAmountMg)) · \(day)"
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

extension Notification.Name {
    static let caminoBeginAgain = Notification.Name("camino.beginAgain")
}
