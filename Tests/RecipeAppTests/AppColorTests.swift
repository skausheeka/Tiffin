import SwiftUI
import UIKit
import XCTest
@testable import RecipeApp

final class AppColorTests: XCTestCase {
    private struct RGB: Equatable {
        let r: Double
        let g: Double
        let b: Double

        init(_ color: Color) {
            let uiColor = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            self.r = Double(r)
            self.g = Double(g)
            self.b = Double(b)
        }

        func isClose(to other: RGB, accuracy: Double = 0.01) -> Bool {
            abs(r - other.r) < accuracy && abs(g - other.g) < accuracy && abs(b - other.b) < accuracy
        }
    }

    func test_forRating_isDeterministic() {
        XCTAssertTrue(RGB(AppColor.forRating(6.4)).isClose(to: RGB(AppColor.forRating(6.4))))
    }

    func test_forRating_lowAndHighEndpointsDiffer() {
        XCTAssertFalse(RGB(AppColor.forRating(1)).isClose(to: RGB(AppColor.forRating(10))))
    }

    func test_forRating_midpointMatchesGold() {
        // 5.5 is the exact midpoint of the 1...10 scale, which is defined to be gold.
        XCTAssertTrue(RGB(AppColor.forRating(5.5)).isClose(to: RGB(AppColor.gold)))
    }

    func test_forRating_clampsBelowMinimumToMinimum() {
        XCTAssertTrue(RGB(AppColor.forRating(-5)).isClose(to: RGB(AppColor.forRating(1))))
    }

    func test_forRating_clampsAboveMaximumToMaximum() {
        XCTAssertTrue(RGB(AppColor.forRating(50)).isClose(to: RGB(AppColor.forRating(10))))
    }

    func test_forRating_atMinimumMatchesLowEndpointExactly() {
        // t = 0 in the interpolation, so this should be the raw low-end color, not a
        // blend — same reasoning as the maximum/gold cases below.
        let expected = RGB(Color(red: Double(0xD9) / 255, green: Double(0x69) / 255, blue: Double(0x5D) / 255))
        XCTAssertTrue(RGB(AppColor.forRating(1)).isClose(to: expected))
    }

    func test_forRating_atMaximumMatchesHighEndpointExactly() {
        let expected = RGB(Color(red: Double(0x6F) / 255, green: Double(0xA3) / 255, blue: Double(0x6B) / 255))
        XCTAssertTrue(RGB(AppColor.forRating(10)).isClose(to: expected))
    }

    func test_forRating_quarterPointIsHalfwayBetweenLowAndGold() {
        // Rating 3.25 sits exactly halfway through the low→mid half of the scale.
        let low = RGB(AppColor.forRating(1))
        let gold = RGB(AppColor.gold)
        let quarter = RGB(AppColor.forRating(3.25))

        XCTAssertEqual(quarter.r, (low.r + gold.r) / 2, accuracy: 0.01)
        XCTAssertEqual(quarter.g, (low.g + gold.g) / 2, accuracy: 0.01)
        XCTAssertEqual(quarter.b, (low.b + gold.b) / 2, accuracy: 0.01)
    }
}
