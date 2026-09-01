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

    // Same muted treatment as the trio above, for the newer course buckets — a 6-color
    // course palette shouldn't have three quiet tones and three loud ones.
    static let breakfast = Color(light: Color(hex: 0xC99A3B), dark: Color(hex: 0xE0BB6F))
    static let side = Color(light: Color(hex: 0x6E9B72), dark: Color(hex: 0x8FC494))
    static let snack = Color(light: Color(hex: 0x9585B8), dark: Color(hex: 0xB6A8D6))

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
}
