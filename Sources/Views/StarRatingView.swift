import SwiftUI

/// A row of star icons. Read-only for display (leaderboard, cards) or
/// interactive — tap a star to set the rating (recipe detail).
struct StarRatingView: View {
    let rating: Int?
    var maxRating: Int = 5
    var size: CGFloat = 18
    var interactive: Bool = true
    var onRate: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= (rating ?? 0) ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(AppColor.gold)
                    .onTapGesture {
                        guard interactive else { return }
                        onRate?(star)
                    }
            }
        }
    }
}
