import SwiftUI

/// The persistent "+" menu — present in the toolbar on every tab, offering every
/// content-creation action in one place: a new recipe, a cooking log entry, an AI
/// import, or scheduling an existing recipe onto the meal plan.
struct GlobalAddMenu: View {
    @State private var isPresentingAddRecipe = false
    @State private var isPresentingLogCook = false
    @State private var isPresentingImport = false
    @State private var isPresentingScheduleMeal = false

    var body: some View {
        Menu {
            Button {
                isPresentingAddRecipe = true
            } label: {
                Label("New Recipe", systemImage: "fork.knife")
            }
            Button {
                isPresentingLogCook = true
            } label: {
                Label("Log a Cook", systemImage: "star")
            }
            Button {
                isPresentingImport = true
            } label: {
                Label("Import Recipe", systemImage: "sparkles")
            }
            Button {
                isPresentingScheduleMeal = true
            } label: {
                Label("Schedule a Meal", systemImage: "calendar.badge.plus")
            }
        } label: {
            Label("Add", systemImage: "plus")
        }
        .sheet(isPresented: $isPresentingAddRecipe) {
            AddRecipeView()
        }
        .sheet(isPresented: $isPresentingLogCook) {
            CookingLogEntryFormView()
        }
        .sheet(isPresented: $isPresentingImport) {
            ImportRecipeView()
        }
        .sheet(isPresented: $isPresentingScheduleMeal) {
            MealPlanEntryFormView()
        }
    }
}
