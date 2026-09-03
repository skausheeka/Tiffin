import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var isSearchActive = false
    @FocusState private var isSearchFieldFocused: Bool
    @State private var isPresentingFilters = false
    @State private var recipeFilter = RecipeFilter()
    @State private var path = NavigationPath()
    @State private var recipePendingDelete: Recipe?
    @State private var recipePendingEdit: Recipe?

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var filteredRecipes: [Recipe] {
        recipes
            .filter { recipe in
                searchText.isEmpty
                    || recipe.title.localizedCaseInsensitiveContains(searchText)
                    || recipe.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
            .filter(recipeFilter.matches)
    }

    private var availableCuisines: [String] {
        Array(Set(recipes.compactMap(\.tags.first))).sorted()
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeCardView(
                                recipe: recipe,
                                onEdit: { recipePendingEdit = recipe },
                                onDelete: { recipePendingDelete = recipe }
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                recipePendingDelete = recipe
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(12)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(AppColor.background)
            .navigationTitle("Recipes")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .navigationDestination(for: TagFilter.self) { filter in
                TaggedRecipesView(tag: filter.tag)
            }
            .sheet(isPresented: $isPresentingFilters) {
                RecipeFilterView(filter: $recipeFilter, availableCuisines: availableCuisines)
            }
            .sheet(item: $recipePendingEdit) { recipe in
                AddRecipeView(existingRecipe: recipe)
            }
            .alert(
                "Delete Recipe?",
                isPresented: Binding(
                    get: { recipePendingDelete != nil },
                    set: { if !$0 { recipePendingDelete = nil } }
                )
            ) {
                Button("Delete", role: .destructive) {
                    if let recipe = recipePendingDelete { delete(recipe) }
                    recipePendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    recipePendingDelete = nil
                }
            } message: {
                Text("This can't be undone.")
            }
            .overlay {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "fork.knife",
                        description: Text("Tap + to add your first recipe.")
                    )
                } else if filteredRecipes.isEmpty {
                    ContentUnavailableView(
                        "No Matches",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Try adjusting or clearing your filters.")
                    )
                }
            }
            .overlay(alignment: .bottomTrailing) {
                searchOverlay
            }
        }
    }

    /// Wordmark + accent flourish on the left, filter/add grouped on the right. Search
    /// deliberately isn't here — it lives in `searchOverlay`, within thumb's reach instead.
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Tiffin")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(AppColor.ink)
                LinearGradient(
                    colors: [AppColor.tertiary, AppColor.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 26, height: 3)
                .clipShape(Capsule())
            }

            Spacer()

            HStack(spacing: 4) {
                Button {
                    isPresentingFilters = true
                } label: {
                    Image(systemName: recipeFilter.isActive
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.accent)
                        .frame(width: 34, height: 34)
                }
                GlobalAddMenu()
                    .labelStyle(.iconOnly)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
                    .frame(width: 34, height: 34)
            }
            .background(AppColor.surface, in: Capsule())
        }
    }

    /// Floating search button anchored bottom-trailing, within thumb's reach. Tapping it
    /// reveals a pill field in place rather than presenting a whole new screen.
    private var searchOverlay: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if isSearchActive {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColor.inkMuted)
                    TextField("Search by title or tag", text: $searchText)
                        .focused($isSearchFieldFocused)
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            isSearchActive = false
                        }
                        isSearchFieldFocused = false
                        searchText = ""
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(width: 270)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isSearchActive.toggle()
                }
                if isSearchActive {
                    isSearchFieldFocused = true
                } else {
                    searchText = ""
                }
            } label: {
                Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(AppColor.accent, in: Circle())
                    .shadow(color: AppColor.accent.opacity(0.35), radius: 14, y: 8)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private func delete(_ recipe: Recipe) {
        for filename in recipe.photoFilenames {
            PhotoStore.delete(filename)
        }
        modelContext.delete(recipe)
    }
}

#Preview {
    RecipeListView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
