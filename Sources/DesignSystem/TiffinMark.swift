import SwiftUI

/// The stacked-tin-and-handle glyph used for the app icon, redrawn from
/// plain SwiftUI shapes so it scales cleanly at any size.
struct TiffinMark: View {
    let size: CGFloat

    private var tinHeight: CGFloat { size * 0.22 }
    private var spacing: CGFloat { size * 0.07 }
    private var lineWidth: CGFloat { max(1.5, size * 0.045) }

    var body: some View {
        VStack(spacing: spacing) {
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(180))
                .frame(width: size * 0.5, height: size * 0.5)
                .frame(height: size * 0.2, alignment: .top)
                .clipped()

            VStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: size * 0.12)
                        .stroke(lineWidth: lineWidth)
                        .frame(width: size, height: tinHeight)
                }
            }
        }
    }
}

#Preview {
    TiffinMark(size: 64)
        .padding()
}
