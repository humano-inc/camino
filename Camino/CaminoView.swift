import SwiftUI
import SwiftData

struct CaminoView: View {
    var journey: Journey
    var calendar: Calendar

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var confirmEvent: ScheduledEvent?
    @State private var showRescue = false
    @State private var showPromise = false
    @State private var showLookBack = false
    @State private var showOpenNights = false

    private var signals: SceneSignals {
        Ledger.signals(on: journey, now: .now, calendar: calendar)
    }

    private var today: [ScheduledEvent] {
        Ledger.todayEvents(on: journey, now: .now, calendar: calendar)
    }

    private var unresolved: [ScheduledEvent] {
        Ledger.unresolvedEvents(on: journey, now: .now, calendar: calendar)
    }

    private var offerArrival: Bool {
        Ledger.arrivalIsOfferable(on: journey, now: .now, calendar: calendar)
    }

    private var arrived: Bool { journey.isArrived }
    private var lightChrome: Bool { CaminoTheme.chromeOnLight(brightness: signals.brightness, arrived: arrived) }

    var body: some View {
        ZStack {
            HearthScene(
                brightness: signals.brightness,
                distance: signals.distance,
                weather: signals.weather,
                arrived: arrived,
                reduceMotion: reduceMotion
            )
            .ignoresSafeArea()
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.8), value: signals)

            VStack(spacing: 0) {
                header
                Spacer()
                if offerArrival {
                    arrivalOffer
                } else if !arrived {
                    pathContent
                }
                chrome
            }
        }
        .preferredColorScheme(lightChrome ? .light : .dark)
        .navigationTitle(Copy.appName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .sheet(item: $confirmEvent) { event in
            ConfirmSheet(event: event, calendar: calendar) { refreshReminders() }
        }
        .sheet(isPresented: $showRescue) {
            RescueSheet(journey: journey, calendar: calendar) { }
        }
        .sheet(isPresented: $showPromise) {
            ProtocolEditorView(journey: journey, isFirst: false, calendar: calendar, onFinished: {
                refreshReminders()
            })
        }
        .navigationDestination(isPresented: $showLookBack) {
            LookBackView(journey: journey, calendar: calendar)
        }
        .sheet(isPresented: $showOpenNights) {
            unresolvedSheet
        }
        .onAppear {
            Ledger.materializeEvents(on: journey, now: .now, calendar: calendar, in: context)
            try? context.save()
            refreshReminders()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Ledger.materializeEvents(on: journey, now: .now, calendar: calendar, in: context)
                try? context.save()
            }
        }
    }

    private var header: some View {
        HStack {
            Text(CaminoFormat.caminoDate(.now, calendar: calendar))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(lightChrome ? CaminoTheme.dateDay : CaminoTheme.dateNight)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .accessibilityHidden(true)
        .overlay(alignment: .leading) {
            Text(Copy.voScene(
                house: Copy.houseWord(signals.distance),
                sky: Copy.skyWord(signals.brightness),
                weather: Copy.weatherWord(signals.weather)
            ))
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .accessibilityLabel(Copy.voScene(
                house: Copy.houseWord(signals.distance),
                sky: Copy.skyWord(signals.brightness),
                weather: Copy.weatherWord(signals.weather)
            ))
            .accessibilityAddTraits(.isImage)
        }
    }

    private var pathContent: some View {
        VStack(spacing: 18) {
            if !unresolved.isEmpty {
                Button {
                    if unresolved.count == 1, let only = unresolved.first {
                        confirmEvent = only
                    } else {
                        showOpenNights = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .stroke(Color.white.opacity(0.45), lineWidth: 1.5)
                            .frame(width: 11, height: 11)
                        Text(unresolved.count == 1 ? Copy.unresolvedOne : Copy.unresolvedMany(unresolved.count))
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white.opacity(0.68))
                    }
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }

            if today.isEmpty {
                Color.clear
                    .frame(height: 1)
                    .accessibilityLabel(Copy.voOff)
            } else {
                VStack(spacing: 18) {
                    ForEach(Array(today.enumerated()), id: \.element.id) { index, event in
                        let last = index == today.count - 1
                        StepStone(event: event, calendar: calendar, prominent: last || today.count == 1) {
                            confirmEvent = event
                        }
                    }
                }
            }
        }
        .padding(.bottom, 12)
    }

    private var arrivalOffer: some View {
        VStack(spacing: 8) {
            Text(Copy.arriveLead)
                .font(.system(size: 19))
                .foregroundStyle(Color(red: 0.165, green: 0.137, blue: 0.094))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button {
                try? Ledger.acceptHome(journey: journey, in: context)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                ReminderScheduler.cancelAll()
            } label: {
                Text(Copy.imHome)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(CaminoTheme.cream)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color(red: 0.165, green: 0.137, blue: 0.094), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)

            Button {
                try? Ledger.declineHome(journey: journey, calendar: calendar, in: context)
            } label: {
                Text(Copy.notYet)
                    .font(.system(size: 17))
                    .foregroundStyle(Color(red: 0.165, green: 0.137, blue: 0.094).opacity(0.65))
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 20)
    }

    private var chrome: some View {
        HStack {
            if arrived || offerArrival {
                Spacer()
                chromeButton(Copy.lookBack) { showLookBack = true }
                Spacer()
            } else {
                chromeButton(Copy.promise) { showPromise = true }
                    .frame(minWidth: 88, alignment: .leading)
                Spacer()
                chromeButton(Copy.rescue) { showRescue = true }
                Spacer()
                chromeButton(Copy.lookBack) { showLookBack = true }
                    .frame(minWidth: 88, alignment: .trailing)
            }
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 8)
        .frame(minHeight: 44)
    }

    private func chromeButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(lightChrome ? CaminoTheme.chromeDay : CaminoTheme.chromeNight)
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    private var unresolvedSheet: some View {
        NavigationStack {
            List(unresolved, id: \.id) { event in
                Button {
                    showOpenNights = false
                    confirmEvent = event
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(CaminoFormat.pathAmount(hour: event.hour, minute: event.minute, amount: event.plannedAmountMg, calendar: calendar))
                        Text(CaminoFormat.weekdayDate(event.dayStart, calendar: calendar))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(unresolved.count == 1 ? Copy.unresolvedOne : Copy.unresolvedMany(unresolved.count))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Copy.cancel) { showOpenNights = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func refreshReminders() {
        Task { await ReminderScheduler.reschedule(journey: journey, calendar: calendar) }
    }
}

extension ScheduledEvent: Identifiable {}
