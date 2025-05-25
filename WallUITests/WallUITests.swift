//
//  WallUITests.swift
//  WallUITests
//
//  Created by Chintan Patel on 24/05/25.
//

import XCTest

final class WallUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        
        addUIInterruptionMonitor(withDescription: "Google Sign-In Permission Alert") { (alert) -> Bool in
            let continueButton = alert.buttons["Continue"]
            if continueButton.exists {
                continueButton.tap()
                return true
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    @MainActor
    func testCoreAppWorkflow() throws {
        app.launch()
        
        // --- Google Sign-In ---
        let signInWithGoogleButton = app.buttons["signInWithGoogleButton"]
        XCTAssertTrue(signInWithGoogleButton.waitForExistence(timeout: 10), "Sign in with Google button not found")
        signInWithGoogleButton.tap()
        
        sleep(2)
        
        var alertHandled = false
        let startTime = Date()
        
        while !alertHandled && Date().timeIntervalSince(startTime) < 15 {
            
            // Try using springboard (system level)
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            if springboard.alerts.firstMatch.buttons["Continue"].exists {
                springboard.alerts.firstMatch.buttons["Continue"].tap()
                alertHandled = true
                break
            }
            
            sleep(1)
        }

        // --- Wait for Navigation to Wall View ---
        let wallNavigationBar = app.navigationBars["Wall"]
        XCTAssertTrue(wallNavigationBar.waitForExistence(timeout: 25), "Wall view did not appear after Google Sign-In. Sign-In might have failed or taken too long.")

        // --- Create a New Post ---
        let postInputField = app.textFields["postInputTextField"]
        
        XCTAssertTrue(postInputField.waitForExistence(timeout: 15), "Post input field not found on WallView")
        postInputField.tap()
        
        sleep(2)
        
        let uniquePostText = "Yo! Look at me write myself! I am just a silly test message though. You'll see me get deleted real soon too. Automated test post at \(Date())"
        postInputField.typeText(uniquePostText)

        let postButton = app.buttons["postButton"]
        XCTAssertTrue(postButton.waitForExistence(timeout: 5), "Post button not found")
        postButton.tap()

        // Dismiss the keyboard
        if app.keyboards.firstMatch.exists {
            // Method 1: Tap the "Done" or "Return" button if it exists
            if app.keyboards.buttons["Done"].exists {
                app.keyboards.buttons["Done"].tap()
            } else if app.keyboards.buttons["Return"].exists {
                app.keyboards.buttons["Return"].tap()
            } else {
                // Method 2: Tap somewhere else on the screen to dismiss keyboard
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
            }
        }

        // --- Verify Post Appears ---
        let newPostCell = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", uniquePostText)).firstMatch
        XCTAssertTrue(newPostCell.waitForExistence(timeout: 5), "Newly created post did not appear in the list")

        // --- Test Filter Toggle: Show My Posts Only ---
        let filterButton = app.navigationBars["Wall"].buttons.element(boundBy: 1) // Second button in nav bar (first is Log Out)
        XCTAssertTrue(filterButton.waitForExistence(timeout: 2), "Filter button not found in navigation bar")
        
        // Tap to show only my posts
        filterButton.tap()
        
        sleep(2)
        
        // Verify the post is still visible (since it's our post)
        XCTAssertTrue(newPostCell.exists, "My post should still be visible when filtering to 'My Posts'")
        
        // --- Test Filter Toggle: Show All Posts ---
        filterButton.tap()
        
        sleep(2)
        
        // Verify the post is still visible (should show all posts now)
        XCTAssertTrue(newPostCell.exists, "Post should be visible when showing all posts")

        // --- Delete the Post ---
        newPostCell.swipeLeft()
        
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete button did not appear after swipe")
        deleteButton.tap()

        // Verify the post is deleted
        XCTAssertFalse(newPostCell.waitForExistence(timeout: 2), "Post was not deleted successfully")

        let logOutButton = app.navigationBars["Wall"].buttons["Log Out"]
        XCTAssertTrue(logOutButton.waitForExistence(timeout: 2), "Log Out button not found in navigation bar")
        logOutButton.tap()

        // Verify we're back to the login screen by checking for the sign in button
        let signInButtonAfterLogout = app.buttons["signInWithGoogleButton"]
        XCTAssertTrue(signInButtonAfterLogout.waitForExistence(timeout: 5), "Did not return to login screen after logout")
    }
}
