# Tiffin

A native iOS recipe app, built as a learning project (product dev, AI-assisted building, and SWE fundamentals). Swift + SwiftUI + SwiftData, edited in VS Code, built via Xcode's toolchain.

## Phases

1. **Store & browse recipes** — CRUD, search/tags, course + rating/notes, leaderboard *(mostly done)*
2. **Meal planning** — day view with add/edit/delete is live; onboarding + notifications, week/month views next *(in progress)*
3. **Import/scale recipes** — pull from URLs, scale servings, convert units
4. *(stretch)* Recreate favorite dishes from favorite restaurants

## Setup

Requires:
- Xcode (full app, not just Command Line Tools) — for the iOS SDK, simulator, and build toolchain
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

```sh
xcodegen generate          # generates RecipeApp.xcodeproj from project.yml — do this after cloning or editing project.yml
open -a Simulator
xcodebuild -project RecipeApp.xcodeproj -scheme RecipeApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Or in VS Code: Cmd+Shift+B runs the default build task (see `.vscode/tasks.json`).

The `.xcodeproj` is generated, not committed — `project.yml` is the source of truth for project configuration.

## Structure

```
project.yml                  XcodeGen project config — source of truth, not the .xcodeproj
Sources/
  RecipeAppApp.swift          App entry point
  DesignSystem/
    AppColor.swift             Cardamom & Rose palette (light/dark) + course→color mapping
  Models/
    Recipe.swift                SwiftData model
    RecipeCourse.swift          Appetizer / Entree / Dessert
    IngredientEntry.swift       One ingredient row (amount, unit, name)
    IngredientUnitSuggestions.swift  ~350-entry unit lookup, Indian-forward
    MealPlanEntry.swift         SwiftData model, relates to Recipe (cascade delete)
    PhotoStore.swift            Saves/loads recipe photos on disk
  Views/
    RootTabView.swift           Tab bar: Recipes / Meal Plan / Leaderboard / Discover / Profile
    RecipeListView.swift        Browse/search recipes (photo grid)
    RecipeCardView.swift        Full-bleed recipe grid card
    RecipeDetailView.swift      View, rate, and edit a recipe
    AddRecipeView.swift         Add or edit a recipe (shared form)
    StarRatingView.swift        Reusable star rating control
    LeaderboardView.swift       Recipes ranked by rating, tiebroken by times cooked
    TaggedRecipesView.swift     Recipes filtered by a tapped tag/cuisine
    MealPlanView.swift          Meal Plan tab container (date nav)
    DayPlanView.swift           Agenda list of planned meals for a day
    MealPlanEntryFormView.swift Add or edit a planned meal
```
