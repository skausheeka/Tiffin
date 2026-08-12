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

/// Cardamom & Rose — the app's committed pastel palette, light/dark paired.
enum AppColor {
    static let background = Color(light: Color(hex: 0xF8F3F6), dark: Color(hex: 0x201A1E))
    static let surface = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x2B232A))
    static let surfaceAlt = Color(light: Color(hex: 0xEFE2EA), dark: Color(hex: 0x362C34))

    static let ink = Color(light: Color(hex: 0x3E2E3A), dark: Color(hex: 0xF1E6EE))
    static let inkMuted = Color(light: Color(hex: 0x8A7686), dark: Color(hex: 0xC2AEC0))

    static let accent = Color(light: Color(hex: 0xA5789B), dark: Color(hex: 0xC79BC0))
    static let accentSoft = Color(light: Color(hex: 0xE3D2E0), dark: Color(hex: 0x4A3A48))

    static let secondary = Color(light: Color(hex: 0x8FAE93), dark: Color(hex: 0xA9C9AE))
    static let secondarySoft = Color(light: Color(hex: 0xD7E6D9), dark: Color(hex: 0x3A4A3E))

    static let tertiary = Color(light: Color(hex: 0xD89A93), dark: Color(hex: 0xE0ACA6))
    static let tertiarySoft = Color(light: Color(hex: 0xF1D9D5), dark: Color(hex: 0x4A3230))

    static let gold = Color(light: Color(hex: 0xC9A15A), dark: Color(hex: 0xE0BD7C))
    static let goldSoft = Color(light: Color(hex: 0xECDCB8), dark: Color(hex: 0x4A3F28))
}
