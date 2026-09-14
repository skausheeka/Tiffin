import SwiftUI

/// The "no photo yet" fallback — a warmer multi-stop gradient with the same
/// stacked-tiffin mark from the app icon watermarked on top, instead of a
/// flat two-color gradient with nothing else going on.
struct RecipePlaceholderView: View {
    var glyphSize: CGFloat = 56

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColor.accentSoft, AppColor.secondarySoft, AppColor.tertiarySoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            TiffinMark(size: glyphSize)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

#Preview {
    RecipePlaceholderView()
        .frame(width: 160, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 18))
}
