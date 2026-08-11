# RecipeApp

A native iOS recipe app, built as a learning project (product dev, AI-assisted building, and SWE fundamentals). Swift + SwiftUI + SwiftData, edited in VS Code, built via Xcode's toolchain.

## Phases

1. **Store & browse recipes** — CRUD, search/tags *(current)*
2. **Meal planning** — plan meals across days/weeks, generate shopping lists
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
project.yml              XcodeGen project config
Sources/
  RecipeAppApp.swift      App entry point
  Models/
    Recipe.swift          SwiftData model
  Views/
    RecipeListView.swift   Browse/search recipes
    AddRecipeView.swift    Add a recipe
    RecipeDetailView.swift View a recipe
```
