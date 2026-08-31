import XCTest
@testable import RecipeApp

final class RecipeJSONLDParserTests: XCTestCase {

    // MARK: - parseJSONLD

    func test_parseJSONLD_minimalValidRecipe() throws {
        let json = """
        {
            "@context": "https://schema.org",
            "@type": "Recipe",
            "name": "Simple Dal",
            "recipeIngredient": ["2 cups red lentils", "1 tsp turmeric"],
            "recipeInstructions": "Rinse the lentils.\\nSimmer until soft."
        }
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.title, "Simple Dal")
        XCTAssertEqual(draft.ingredients.count, 2)
        XCTAssertEqual(draft.ingredients.first?.name, "red lentils")
        XCTAssertEqual(draft.steps, ["Rinse the lentils.", "Simmer until soft."])
    }

    func test_parseJSONLD_instructionsAsHowToStepArray() throws {
        let json = """
        {
            "@type": "Recipe",
            "name": "Tomato Soup",
            "recipeIngredient": ["4 tomatoes"],
            "recipeInstructions": [
                {"@type": "HowToStep", "text": "Chop the tomatoes."},
                {"@type": "HowToStep", "text": "Simmer for 20 minutes."}
            ]
        }
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.steps, ["Chop the tomatoes.", "Simmer for 20 minutes."])
    }

    func test_parseJSONLD_instructionsAsNestedHowToSections() throws {
        let json = """
        {
            "@type": "Recipe",
            "name": "Layered Dish",
            "recipeIngredient": ["1 cup rice"],
            "recipeInstructions": [
                {
                    "@type": "HowToSection",
                    "name": "For the rice",
                    "itemListElement": [
                        {"@type": "HowToStep", "text": "Cook the rice."}
                    ]
                },
                {
                    "@type": "HowToSection",
                    "name": "Assembly",
                    "itemListElement": [
                        {"@type": "HowToStep", "text": "Layer everything together."}
                    ]
                }
            ]
        }
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.steps, ["Cook the rice.", "Layer everything together."])
        XCTAssertEqual(draft.prepSteps, [], "Section names with no \"prep\" mention shouldn't be guessed as prep")
    }

    func test_parseJSONLD_prepNamedHowToSection_routesToPrepSteps() throws {
        let json = """
        {
            "@type": "Recipe",
            "name": "Weeknight Curry",
            "recipeIngredient": ["1 onion"],
            "recipeInstructions": [
                {
                    "@type": "HowToSection",
                    "name": "Prep",
                    "itemListElement": [
                        {"@type": "HowToStep", "text": "Dice the onion."},
                        {"@type": "HowToStep", "text": "Mince the garlic."}
                    ]
                },
                {
                    "@type": "HowToSection",
                    "name": "Cook",
                    "itemListElement": [
                        {"@type": "HowToStep", "text": "Saute the onion."}
                    ]
                }
            ]
        }
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.prepSteps, ["Dice the onion.", "Mince the garlic."])
        XCTAssertEqual(draft.steps, ["Saute the onion."])
    }

    func test_parseJSONLD_graphWrappedRecipe_wordPressStyle() throws {
        let json = """
        {
            "@context": "https://schema.org",
            "@graph": [
                {"@type": "WebPage", "name": "Some Blog Post"},
                {
                    "@type": "Recipe",
                    "name": "Graph Recipe",
                    "recipeIngredient": ["1 onion"],
                    "recipeInstructions": ["Dice the onion."]
                }
            ]
        }
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.title, "Graph Recipe")
    }

    func test_parseJSONLD_topLevelArrayOfObjects() throws {
        let json = """
        [
            {"@type": "BreadcrumbList"},
            {
                "@type": "Recipe",
                "name": "Array Recipe",
                "recipeIngredient": ["1 carrot"],
                "recipeInstructions": ["Peel the carrot."]
            }
        ]
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.title, "Array Recipe")
    }

    func test_parseJSONLD_typeAsArray_matchesRecipe() throws {
        let json = """
        {
            "@type": ["Thing", "Recipe"],
            "name": "Multi-Type Recipe",
            "recipeIngredient": ["1 potato"],
            "recipeInstructions": ["Boil the potato."]
        }
        """

        XCTAssertNotNil(RecipeJSONLDParser.parseJSONLD(json))
    }

    func test_parseJSONLD_noRecipeType_returnsNil() {
        let json = """
        {"@type": "WebPage", "name": "Not a recipe"}
        """

        XCTAssertNil(RecipeJSONLDParser.parseJSONLD(json))
    }

    func test_parseJSONLD_invalidJSON_returnsNil() {
        XCTAssertNil(RecipeJSONLDParser.parseJSONLD("{not valid json"))
    }

    func test_parseJSONLD_missingIngredients_returnsNil() {
        let json = """
        {"@type": "Recipe", "name": "No Ingredients", "recipeInstructions": ["Do something."]}
        """

        XCTAssertNil(RecipeJSONLDParser.parseJSONLD(json))
    }

    func test_parseJSONLD_cuisineAndKeywords_becomeTagsWithCuisineFirst() throws {
        let json = """
        {
            "@type": "Recipe",
            "name": "Curry",
            "recipeIngredient": ["1 cup coconut milk"],
            "recipeInstructions": ["Simmer everything."],
            "recipeCuisine": "Thai",
            "keywords": "spicy, quick, weeknight"
        }
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.tags.first, "Thai")
        XCTAssertTrue(draft.tags.contains("spicy"))
    }

    func test_parseJSONLD_recipeYieldAsBareNumber() throws {
        let json = """
        {"@type": "Recipe", "name": "Yield Test", "recipeIngredient": ["1 egg"], "recipeInstructions": ["Cook it."], "recipeYield": 4}
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.servings, 4)
    }

    func test_parseJSONLD_recipeYieldAsString() throws {
        let json = """
        {"@type": "Recipe", "name": "Yield Test", "recipeIngredient": ["1 egg"], "recipeInstructions": ["Cook it."], "recipeYield": "6 servings"}
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.servings, 6)
    }

    func test_parseJSONLD_recipeYieldAsQuantitativeValue() throws {
        let json = """
        {"@type": "Recipe", "name": "Yield Test", "recipeIngredient": ["1 egg"], "recipeInstructions": ["Cook it."], "recipeYield": {"@type": "QuantitativeValue", "value": 8}}
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.servings, 8)
    }

    func test_parseJSONLD_durationParsing_hoursAndMinutes() throws {
        let json = """
        {"@type": "Recipe", "name": "Timing", "recipeIngredient": ["1 egg"], "recipeInstructions": ["Cook it."], "prepTime": "PT15M", "cookTime": "PT1H30M"}
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.prepTimeMinutes, 15)
        XCTAssertEqual(draft.cookTimeMinutes, 90)
    }

    func test_parseJSONLD_malformedDuration_returnsNil() throws {
        let json = """
        {"@type": "Recipe", "name": "Timing", "recipeIngredient": ["1 egg"], "recipeInstructions": ["Cook it."], "prepTime": "not-a-duration"}
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertNil(draft.prepTimeMinutes)
    }

    func test_parseJSONLD_categoryGuessesDessertCourse() throws {
        let json = """
        {"@type": "Recipe", "name": "Cake", "recipeIngredient": ["1 cup sugar"], "recipeInstructions": ["Bake it."], "recipeCategory": "Dessert"}
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.parseJSONLD(json))

        XCTAssertEqual(draft.course, .dessert)
    }

    // MARK: - extractRecipeDraft(fromHTML:)

    func test_extractRecipeDraft_findsScriptBlockInHTML() throws {
        let html = """
        <html><head>
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "From HTML", "recipeIngredient": ["1 egg"], "recipeInstructions": ["Cook it."]}
        </script>
        </head><body></body></html>
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.extractRecipeDraft(fromHTML: html))

        XCTAssertEqual(draft.title, "From HTML")
    }

    func test_extractRecipeDraft_skipsNonRecipeBlock_findsSecondBlock() throws {
        let html = """
        <script type="application/ld+json">{"@type": "WebPage"}</script>
        <script type="application/ld+json">{"@type": "Recipe", "name": "Second Block", "recipeIngredient": ["1 egg"], "recipeInstructions": ["Cook it."]}</script>
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.extractRecipeDraft(fromHTML: html))

        XCTAssertEqual(draft.title, "Second Block")
    }

    func test_extractRecipeDraft_noScriptBlocks_returnsNil() {
        let html = "<html><body><p>No structured data here.</p></body></html>"

        XCTAssertNil(RecipeJSONLDParser.extractRecipeDraft(fromHTML: html))
    }

    func test_extractRecipeDraft_htmlEntitiesInJSON_decodedBeforeParsing() throws {
        let html = """
        <script type="application/ld+json">
        {"@type": "Recipe", "name": "Mac &amp; Cheese", "recipeIngredient": ["1 cup pasta"], "recipeInstructions": ["Boil it."]}
        </script>
        """

        let draft = try XCTUnwrap(RecipeJSONLDParser.extractRecipeDraft(fromHTML: html))

        XCTAssertEqual(draft.title, "Mac & Cheese")
    }
}
