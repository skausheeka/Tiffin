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
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    private var coverImage: UIImage? {
        guard let filename = recipe.coverPhotoFilename else { return nil }
        return UIImage(contentsOfFile: PhotoStore.url(for: filename).path)
    }

    private var timeText: String? {
        let total = (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)
        return total > 0 ? "\(total) min" : nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { proxy in
                Group {
                    if let coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        RecipePlaceholderView()
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

            if onEdit != nil || onDelete != nil {
                Menu {
                    if let onEdit {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    if let onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(7)
                        .background(AppColor.ink.opacity(0.4), in: Circle())
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if let average = recipe.averageRating {
                Text(String(format: "%.1f", average))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppColor.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColor.gold, in: Capsule())
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }

            VStack(alignment: .leading, spacing: 3) {
                Spacer()
                Text(recipe.title)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let timeText {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(timeText)
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
                }

                if recipe.servings != nil || recipe.timesCooked > 0 {
                    HStack(spacing: 4) {
                        if let servings = recipe.servings {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 8))
                            Text("Serves \(servings)")
                            if recipe.timesCooked > 0 { Text("·") }
                        }
                        if recipe.timesCooked > 0 {
                            Image(systemName: "repeat")
                                .font(.system(size: 8))
                            Text("Cooked ×\(recipe.timesCooked)")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
