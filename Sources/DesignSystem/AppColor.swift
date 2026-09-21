import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

/// Tiffin — dusty indigo/teal/rose palette, light/dark paired. Deliberately muted rather
/// than fully saturated.
enum AppColor {
    static let background = Color(light: Color(hex: 0xF5F6FC), dark: Color(hex: 0x100F1E))
    static let surface = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1B1A2E))
    static let surfaceAlt = Color(light: Color(hex: 0xEDEFFB), dark: Color(hex: 0x262540))

    static let ink = Color(light: Color(hex: 0x16162A), dark: Color(hex: 0xF1F1FF))
    static let inkMuted = Color(light: Color(hex: 0x6B6B85), dark: Color(hex: 0xA8A6C8))

    static let accent = Color(light: Color(hex: 0x5B6EAE), dark: Color(hex: 0x93A1D6))
    static let accentSoft = Color(light: Color(hex: 0xDDE1FF), dark: Color(hex: 0x33355E))

    static let secondary = Color(light: Color(hex: 0x4F9A8C), dark: Color(hex: 0x7FC2B6))
    static let secondarySoft = Color(light: Color(hex: 0xC9F5EF), dark: Color(hex: 0x1D4A44))

    static let tertiary = Color(light: Color(hex: 0xC97690), dark: Color(hex: 0xE0A0B4))
    static let tertiarySoft = Color(light: Color(hex: 0xFFDCE6), dark: Color(hex: 0x5C2438))

    static let gold = Color(light: Color(hex: 0xF5B400), dark: Color(hex: 0xFFD873))
    static let goldSoft = Color(light: Color(hex: 0xFFEEC2), dark: Color(hex: 0x4A3A12))

    // Podium colors for #2 and #3 on the leaderboard — #1 reuses gold above.
    static let silver = Color(light: Color(hex: 0x8E93A8), dark: Color(hex: 0xB7BBCC))
    static let bronze = Color(light: Color(hex: 0xA66B42), dark: Color(hex: 0xC99568))

    // Endpoints for `forRating` below — gold (defined above) is reused as the midpoint,
    // so a perfectly middling rating looks exactly like the rating badges always have.
    private static let ratingLow: UInt32 = 0xD9695D
    private static let ratingLowDark: UInt32 = 0xE89488
    private static let ratingMid: UInt32 = 0xF5B400
    private static let ratingMidDark: UInt32 = 0xFFD873
    private static let ratingHigh: UInt32 = 0x6FA36B
    private static let ratingHighDark: UInt32 = 0x94C48F

    // Same muted treatment as the trio above, for the newer course buckets — a 6-color
    // course palette shouldn't have three quiet tones and three loud ones.
    static let breakfast = Color(light: Color(hex: 0xC99A3B), dark: Color(hex: 0xE0BB6F))
    static let side = Color(light: Color(hex: 0x6E9B72), dark: Color(hex: 0x8FC494))
    static let snack = Color(light: Color(hex: 0x9585B8), dark: Color(hex: 0xB6A8D6))

    // A soft wash blending the three signature hues — for header/hero bands that want
    // atmosphere without competing with photo-forward card content sitting below them.
    static let auroraIndigo = Color(light: Color(hex: 0xEEF0FB), dark: Color(hex: 0x22213A))
    static let auroraRose = Color(light: Color(hex: 0xF7ECF1), dark: Color(hex: 0x2E2230))
    static let auroraGold = Color(light: Color(hex: 0xFDF3DD), dark: Color(hex: 0x2E2716))

    static func forCourse(_ course: RecipeCourse?) -> Color {
        switch course {
        case .breakfast: breakfast
        case .appetizer: secondary
        case .entree: accent
        case .side: side
        case .snack: snack
        case .dessert: tertiary
        case nil: inkMuted
        }
    }

    /// Red at 1, gold at the midpoint, green at 10 — a traffic-light read on a rating
    /// badge at a glance, without needing to actually read the number.
    static func forRating(_ rating: Double) -> Color {
        let t = min(max((rating - 1) / 9, 0), 1)
        if t < 0.5 {
            let segment = t / 0.5
            return Color(
                light: interpolate(ratingLow, ratingMid, segment),
                dark: interpolate(ratingLowDark, ratingMidDark, segment)
            )
        } else {
            let segment = (t - 0.5) / 0.5
            return Color(
                light: interpolate(ratingMid, ratingHigh, segment),
                dark: interpolate(ratingMidDark, ratingHighDark, segment)
            )
        }
    }

    private static func interpolate(_ from: UInt32, _ to: UInt32, _ t: Double) -> Color {
        func component(_ hex: UInt32, _ shift: UInt32) -> Double {
            Double((hex >> shift) & 0xFF)
        }
        let r = component(from, 16) + (component(to, 16) - component(from, 16)) * t
        let g = component(from, 8) + (component(to, 8) - component(from, 8)) * t
        let b = component(from, 0) + (component(to, 0) - component(from, 0)) * t
        return Color(red: r / 255, green: g / 255, blue: b / 255)
    }
}
