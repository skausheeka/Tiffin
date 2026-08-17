import SwiftUI

struct RecipeFilterView: View {
    @Binding var filter: RecipeFilter
    let availableCuisines: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Cuisine") {
                    Picker("Cuisine", selection: $filter.cuisine) {
                        Text("Any").tag(String?.none)
                        ForEach(availableCuisines, id: \.self) { cuisine in
                            Text(cuisine).tag(String?.some(cuisine))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Course") {
                    Picker("Course", selection: $filter.course) {
                        Text("Any").tag(RecipeCourse?.none)
                        ForEach(RecipeCourse.allCases) { course in
                            Text(course.rawValue).tag(RecipeCourse?.some(course))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Time to cook") {
                    Picker("Time to cook", selection: $filter.timeBucket) {
                        Text("Any").tag(TimeBucket?.none)
                        ForEach(TimeBucket.allCases) { bucket in
                            Text(bucket.rawValue).tag(TimeBucket?.some(bucket))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Times cooked") {
                    Picker("Times cooked", selection: $filter.cookedBucket) {
                        Text("Any").tag(CookedBucket?.none)
                        ForEach(CookedBucket.allCases) { bucket in
                            Text(bucket.rawValue).tag(CookedBucket?.some(bucket))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if filter.isActive {
                    Section {
                        Button("Clear Filters", role: .destructive) {
                            filter = RecipeFilter()
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
        }
    }
}
