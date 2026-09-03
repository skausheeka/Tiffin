import SwiftUI
import UIKit

struct MealPlanRow: View {
    let entry: MealPlanEntry

    private var coverImage: UIImage? {
        guard let filename = entry.recipe?.coverPhotoFilename else { return nil }
        return PhotoStore.image(for: filename)
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(AppColor.forCourse(entry.recipe?.courseValue))
                .frame(width: 4)

            Group {
                if let coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RecipePlaceholderView(glyphSize: 22)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.recipe?.title ?? "Recipe")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                HStack(spacing: 6) {
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                    if let servings = entry.servings {
                        Text("· \(servings) servings")
                    }
                    if entry.expectsLeftovers {
                        Image(systemName: "takeoutbag.and.cup.and.straw")
                    }
                }
                .font(.caption)
                .foregroundStyle(AppColor.inkMuted)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
