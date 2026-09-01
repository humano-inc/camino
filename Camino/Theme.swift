import SwiftUI
import UIKit

enum CaminoTheme {
    static let amber = Color(red: 0.922, green: 0.718, blue: 0.443)
    static let cream = Color(red: 0.965, green: 0.945, blue: 0.906)
    static let ink = Color(red: 0.102, green: 0.078, blue: 0.031)
    static let dateNight = Color.white.opacity(0.42)
    static let dateDay = Color(red: 0.118, green: 0.098, blue: 0.059).opacity(0.5)
    static let chromeNight = Color.white.opacity(0.62)
    static let chromeDay = Color(red: 0.965, green: 0.945, blue: 0.906).opacity(0.78)
    static let stoneTop = Color(red: 0.290, green: 0.329, blue: 0.408)
    static let stoneMid = Color(red: 0.200, green: 0.231, blue: 0.298)
    static let stoneBot = Color(red: 0.153, green: 0.180, blue: 0.239)
    static let stoneEdge = Color(red: 1.0, green: 0.835, blue: 0.588)
    /// The scene's rain, made dynamic: day rain on light backgrounds, night rain on dark.
    static let rain = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.808, green: 0.847, blue: 0.922, alpha: 1)
            : UIColor(red: 0.235, green: 0.275, blue: 0.353, alpha: 1)
    })

    static func chromeOnLight(brightness: Double, arrived: Bool) -> Bool {
        arrived || brightness > 0.65
    }
}
