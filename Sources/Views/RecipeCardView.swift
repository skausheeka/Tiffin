import SwiftUI
import UIKit

/// A torn-flag ribbon, used to call out dessert recipes specifically.
private struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let notch = rect.width * 0.18
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// "Full-Bleed" recipe card — photo fills the card, title/meta sit on a bottom scrim.
struct RecipeCardView: View {
    let recipe: Recipe
    var onTapTag: (String) -> Void

    private var coverImage: UIImage? {
        guard let filename = recipe.coverPhotoFilename else { return nil }
        return UIImage(contentsOfFile: PhotoStore.url(for: filename).path)
    }

    private var timeText: String? {
        let total = (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)
        return total > 0 ? "\(total) min" : nil
    }

    private var primaryTag: String? { recipe.tags.first }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { proxy in
                Group {
                    if let coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [AppColor.accentSoft, AppColor.tertiarySoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }

            LinearGradient(
                colors: [AppColor.ink.opacity(0), AppColor.ink.opacity(0), AppColor.ink.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )

            if recipe.courseValue == .dessert {
                Text("Dessert")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RibbonShape().fill(AppColor.tertiary))
                    .padding(.top, 12)
                    .offset(x: -6)
            }

            if let average = recipe.averageRating {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                    Text(String(format: "%.1f", average))
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(AppColor.ink.opacity(0.5), in: Capsule())
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: 3) {
                Spacer()
                Text(recipe.title)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    if let timeText {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(timeText)
                        if primaryTag != nil { Text("·") }
                    }
                    if let primaryTag {
                        Button {
                            onTapTag(primaryTag)
                        } label: {
                            Text(primaryTag)
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
