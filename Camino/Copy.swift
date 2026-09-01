import Foundation

enum Copy {
    static let appName = "Camino"

    static let disclaimerBody =
        "This is a personal ledger for your clonazepam, not medical advice. Withdrawal can be dangerous. You own your protocol. A clinician owns the medicine."
    static let `continue` = "Continue"

    static let firstPromiseTitle = "Your first promise"
    static let firstPromiseLead = "Which pieces, which nights, which time. You can cut this whenever you can hold less."
    static let begin = "Begin"
    static let addATime = "Add a time"

    static let rescue = "Rescue"
    static let promise = "Promise"
    static let lookBack = "Look back"
    static let unresolvedOne = "One night still open"
    static func unresolvedMany(_ n: Int) -> String { "\(n) nights still open" }

    static let taken = "Taken"
    static let skip = "Skip"
    static let differentAmount = "Different amount"
    static let time = "Time"
    static let save = "Save"
    static let cancel = "Cancel"
    static func overflow(_ extra: String) -> String {
        "\(extra) above the promise is logged as rescue."
    }

    static let fromSlotPrefix = "From"

    static let thisWeekPlanned: (String) -> String = { "This week \($0) mg planned" }
    static let amount = "Amount"
    static let note = "Note"
    static let noteHint = "optional"
    static let days = "Days"
    static let rhythm = "Rhythm"
    static let weekdays = "Weekdays"
    static let everyFewNights = "Every few nights"
    static func everyNNights(_ n: Int) -> String { "Every \(n) nights" }
    static func nightsOffAfterTake(_ off: Int) -> String {
        let span: String
        switch off {
        case 1: span = "one night"
        case 2: span = "two nights"
        case 3: span = "three nights"
        default: span = "\(off) nights"
        }
        return "Take, then \(span) off."
    }
    static let firstNight = "First night"
    static let tonight = "Tonight"
    static let tomorrow = "Tomorrow"
    static func aboutWeekPlanned(_ amount: String) -> String { "About \(amount) mg a week" }
    static let deleteThisTime = "Delete this time"
    static let custom = "Custom"
    static let pieceQuarter = "¼"
    static let pieceHalf = "½"
    static let pieceThreeQuarter = "¾"
    static let pieceOne = "1"
    static let pieceUnit = "of 0.25 mg"

    static let layDownTitle = "Lay this promise down?"
    static let layDownBody = "No scheduled doses. Rescue will still be possible until you are home."
    static let layDownConfirm = "Lay it down"
    static let discardTitle = "Discard changes?"
    static let discard = "Discard"
    static let keepEditing = "Keep editing"
    static let notificationsOff = "Reminders are off."
    static let openSettings = "Open Settings"

    static let thisWeek = "This week"
    static let weeks = "Weeks"
    static let actual = "Taken"
    static let planned = "Promised"
    static let promises = "Promises"
    static let nights = "Nights"
    static let skipped = "Skipped"
    static let lessThanPromised = "Less than promised"
    static let exportJourney = "Export journey"
    static let emptyWeek = "Just this week so far."
    static let now = "now"

    static let arriveLead = "No promise. Nothing taken today."
    static let imHome = "I’m home"
    static let notYet = "Not yet"
    static let arrivedVO = "Home. The road has ended."

    static let beginAgain = "Begin again"
    static let beginAgainTitle = "Start a new road?"
    static let beginAgainBody = "The one you finished stays here to look back on."

    static let ok = "OK"
    static let done = "Done"

    static func voScene(house: String, sky: String, weather: String) -> String {
        "Road toward home. House \(house). Sky \(sky). Weather \(weather)."
    }

    static func voStepOpen(time: String, amount: String) -> String {
        "\(time), \(amount) milligrams, not confirmed"
    }

    static func voStepTaken(time: String, amount: String) -> String {
        "\(time), took \(amount) milligrams"
    }

    static func voStepLess(time: String, planned: String, actual: String) -> String {
        "\(time), promised \(planned), took \(actual)"
    }

    static func voStepSkipped(time: String) -> String {
        "\(time), skipped"
    }

    static let voOff = "No dose on the path tonight"

    static func houseWord(_ distance: Double) -> String {
        distance < 0.45 ? "far" : "nearer"
    }

    static func skyWord(_ brightness: Double) -> String {
        if brightness < 0.25 { return "dark" }
        if brightness < 0.7 { return "thinning" }
        return "morning"
    }

    static func weatherWord(_ weather: Double) -> String {
        if weather < 0.2 { return "clear" }
        if weather < 0.55 { return "cloud" }
        return "rain"
    }
}
