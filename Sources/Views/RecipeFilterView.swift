import SwiftUI

struct RecipeFilterView: View {
    @Binding var filter: RecipeFilter
    let availableCuisines: [String]
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCuisineFieldFocused: Bool
    @State private var cuisineQuery = ""

    /// Cuisines are free-text tags, so the list can grow arbitrarily — an autofill
    /// search reads better than scrolling a long picker. Course/time/cooked are small
    /// fixed sets, so a menu-style dropdown fits those better. Tapping into the field
    /// with nothing typed shows every cuisine already used across saved recipes, like a
    /// dropdown; typing narrows that list down, like autofill.
    private var cuisineSuggestions: [String] {
        guard isCuisineFieldFocused else { return [] }
        guard !cuisineQuery.isEmpty else { return availableCuisines }
        return availableCuisines.filter { $0.localizedCaseInsensitiveContains(cuisineQuery) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cuisine") {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColor.inkMuted)
                        TextField("Search cuisines...", text: $cuisineQuery)
                            .focused($isCuisineFieldFocused)
                            .onChange(of: cuisineQuery) {
                                if cuisineQuery.isEmpty { filter.cuisine = nil }
                            }
                            .onSubmit(commitCuisineQuery)
                        if !cuisineQuery.isEmpty {
                            Button {
                                cuisineQuery = ""
                                filter.cuisine = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColor.inkMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ForEach(cuisineSuggestions, id: \.self) { cuisine in
                        Button {
                            filter.cuisine = cuisine
                            cuisineQuery = cuisine
                            isCuisineFieldFocused = false
                        } label: {
                            Text(cuisine)
                                .foregroundStyle(AppColor.ink)
                        }
                    }
                }

                Section("Filters") {
                    Picker("Course", selection: $filter.course) {
                        Text("Any").tag(RecipeCourse?.none)
                        ForEach(RecipeCourse.allCases) { course in
                            Text(course.rawValue).tag(RecipeCourse?.some(course))
                        }
                    }
                    .pickerStyle(.menu)

                    // The dropdown only ever offers "Any" or "Custom Limit" — never a
                    // specific number — so it doesn't read as if a fixed default (like
                    // "Under 30 min") were the only alternative to no constraint. The
                    // actual minute value lives entirely in the wheel below.
                    Picker(
                        "Time to Cook",
                        selection: Binding(
                            get: { filter.maxCookTimeMinutes != nil },
                            set: { isOn in filter.maxCookTimeMinutes = isOn ? (filter.maxCookTimeMinutes ?? 30) : nil }
                        )
                    ) {
                        Text("Any").tag(false)
                        Text("Custom Limit").tag(true)
                    }
                    .pickerStyle(.menu)

                    if let maxTime = filter.maxCookTimeMinutes {
                        HStack {
                            Text("Under \(maxTime) min")
                                .foregroundStyle(AppColor.inkMuted)
                            Spacer()
                        }
                        .font(.caption)

                        Picker(
                            "Under",
                            selection: Binding(
                                get: { maxTime },
                                set: { filter.maxCookTimeMinutes = $0 }
                            )
                        ) {
                            ForEach(Array(stride(from: 5, through: 180, by: 5)), id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .labelsHidden()
                    }

                    Picker("Times Cooked", selection: $filter.cookedBucket) {
                        Text("Any").tag(CookedBucket?.none)
                        ForEach(CookedBucket.allCases) { bucket in
                            Text(bucket.rawValue).tag(CookedBucket?.some(bucket))
                        }
                    }
                    .pickerStyle(.menu)
                }

                if filter.isActive {
                    Section {
                        Button("Clear Filters", role: .destructive) {
                            filter = RecipeFilter()
                            cuisineQuery = ""
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle("Filter Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                cuisineQuery = filter.cuisine ?? ""
            }
        }
    }

    private func commitCuisineQuery() {
        guard let match = availableCuisines.first(where: { $0.caseInsensitiveCompare(cuisineQuery) == .orderedSame }) else { return }
        filter.cuisine = match
        cuisineQuery = match
        isCuisineFieldFocused = false
    }
}
