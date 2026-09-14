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
    @State private var isInteractingWithRail = false
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

    /// No active search or filter — nothing specific in mind, just scrolling for
    /// inspiration. That's when the course-mixed order kicks in; otherwise show the
    /// flat, filtered grid so a focused lookup isn't reshuffled underneath it.
    private var isBrowsing: Bool {
        searchText.isEmpty && !recipeFilter.isActive
    }

    /// One continuous grid, same as any other browsing feed — but the order takes one
    /// recipe from each course in turn (round-robin) instead of strict recency, so
    /// scrolling naturally samples variety instead of running through one course at a
    /// time. Course still reads at a glance from each card's own ribbon color.
    private var browsableRecipes: [Recipe] {
        var byCourse = RecipeCourse.allCases.map { course in
            recipes.filter { $0.courseValue == course }
        }
        var mixed: [Recipe] = []
        while !byCourse.isEmpty {
            for index in byCourse.indices where !byCourse[index].isEmpty {
                mixed.append(byCourse[index].removeFirst())
            }
            byCourse.removeAll(where: \.isEmpty)
        }
        return mixed
    }

    private var displayedRecipes: [Recipe] {
        isBrowsing ? browsableRecipes : filteredRecipes
    }

    private var coursesWithRecipes: [RecipeCourse] {
        RecipeCourse.allCases.filter { course in recipes.contains { $0.courseValue == course } }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                header

                activeFilterChips

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(displayedRecipes) { recipe in
                        recipeCard(recipe)
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, coursesWithRecipes.count > 1 ? 30 : 12)
                .padding(.vertical, 12)
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
            .overlay(alignment: .trailing) {
                if coursesWithRecipes.count > 1 {
                    courseRail
                        .padding(.trailing, 6)
                }
            }
        }
    }

    private var headerGradient: LinearGradient {
        LinearGradient(
            colors: [AppColor.auroraIndigo, AppColor.auroraRose, AppColor.auroraGold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Tiffin mark + wordmark on the left, filter/add on the right, sitting on a soft
    /// gradient wash blending the app's three signature hues. Search deliberately isn't
    /// here — it lives in `searchOverlay`, within thumb's reach instead.
    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 9) {
                TiffinMark(size: 28)
                    .foregroundStyle(AppColor.ink)
                Text("Tiffin")
                    .font(.system(size: 25, weight: .bold, design: .serif))
                    .foregroundStyle(AppColor.ink)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    isPresentingFilters = true
                } label: {
                    Image(systemName: recipeFilter.isActive
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.accent)
                        .frame(width: 34, height: 34)
                        .background(AppColor.surface.opacity(0.85), in: Circle())
                }
                GlobalAddMenu()
                    .labelStyle(.iconOnly)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
                    .frame(width: 34, height: 34)
                    .background(AppColor.surface.opacity(0.85), in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(headerGradient)
    }

    /// Removable pills for whatever's active in `recipeFilter` — course, cuisine, time,
    /// times-cooked — so it's never ambiguous whether you're browsing or looking at a
    /// narrowed slice, and clearing one is always a single tap.
    @ViewBuilder
    private var activeFilterChips: some View {
        if recipeFilter.isActive {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let course = recipeFilter.course {
                        filterChip(course.rawValue, tint: AppColor.forCourse(course)) {
                            recipeFilter.course = nil
                        }
                    }
                    if let cuisine = recipeFilter.cuisine {
                        filterChip(cuisine, tint: AppColor.accent) {
                            recipeFilter.cuisine = nil
                        }
                    }
                    if let maxCookTimeMinutes = recipeFilter.maxCookTimeMinutes {
                        filterChip("Under \(maxCookTimeMinutes) min", tint: AppColor.accent) {
                            recipeFilter.maxCookTimeMinutes = nil
                        }
                    }
                    if let cookedBucket = recipeFilter.cookedBucket {
                        filterChip(cookedBucket.rawValue, tint: AppColor.accent) {
                            recipeFilter.cookedBucket = nil
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 6)
        }
    }

    private func filterChip(_ label: String, tint: Color, onClear: @escaping () -> Void) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.caption.weight(.semibold))
            Button(action: onClear) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint, in: Capsule())
    }

    private let railItemHeight: CGFloat = 26

    /// A quiet index along the trailing edge, styled like a native scroll indicator —
    /// small neutral dots at rest (the active course shown as a colored dot even then),
    /// expanding into the actual course labels the moment you touch down, and scrubbing
    /// live as you drag. Fades back to dots on release. Six courses at most, so a single
    /// press-and-drag over the whole rail covers both a quick tap and a scrub.
    private var courseRail: some View {
        VStack(spacing: 0) {
            ForEach(coursesWithRecipes) { course in
                railItem(for: course)
                    .frame(height: railItemHeight)
            }
        }
        .frame(width: 30)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isInteractingWithRail {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            isInteractingWithRail = true
                        }
                    }
                    let index = min(
                        max(Int(value.location.y / railItemHeight), 0),
                        coursesWithRecipes.count - 1
                    )
                    recipeFilter.course = coursesWithRecipes[index]
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        isInteractingWithRail = false
                    }
                }
        )
        .sensoryFeedback(.selection, trigger: recipeFilter.course)
    }

    @ViewBuilder
    private func railItem(for course: RecipeCourse) -> some View {
        if isInteractingWithRail {
            Text(String(course.rawValue.prefix(2)).uppercased())
                .font(.system(size: 11, weight: recipeFilter.course == course ? .heavy : .bold))
                .foregroundStyle(AppColor.forCourse(course))
                .opacity(recipeFilter.course == nil || recipeFilter.course == course ? 1 : 0.4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Circle()
                .fill(recipeFilter.course == course ? AppColor.forCourse(course) : AppColor.inkMuted.opacity(0.3))
                .frame(width: recipeFilter.course == course ? 6 : 4, height: recipeFilter.course == course ? 6 : 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func recipeCard(_ recipe: Recipe) -> some View {
        NavigationLink(value: recipe) {
            RecipeCardView(
                recipe: recipe,
                onEdit: { recipePendingEdit = recipe },
                onDelete: { recipePendingDelete = recipe },
                onTapCourse: { course in recipeFilter.course = course }
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
