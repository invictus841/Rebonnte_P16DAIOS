//
//  AuthViewModelTests.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 13/10/2025.
//

import XCTest
@testable import MediStock

@MainActor
class AuthViewModelTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Sign In Tests
    
    func testSignInSuccess() async {
        // Given
        mockAuthService.shouldSucceed = true
        let email = "test@example.com"
        let password = "password123"
        
        // When
        await viewModel.signIn(email: email, password: password)
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated, "User should be authenticated")
        XCTAssertEqual(viewModel.userEmail, email, "Email should match")
        XCTAssertNil(viewModel.errorMessage, "No error should be present")
        XCTAssertEqual(mockAuthService.signInCallCount, 1, "Sign in should be called once")
    }
    
    func testSignInFailure() async {
        // Given
        mockAuthService.shouldSucceed = false
        let email = "wrong@example.com"
        let password = "wrongpass"
        
        // When
        await viewModel.signIn(email: email, password: password)
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated, "User should not be authenticated")
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be present")
        XCTAssertEqual(mockAuthService.signInCallCount, 1, "Sign in should be called once")
    }
    
    // In AuthViewModelTests.swift
    func testSignInLoadingState() async {
        // Given
        mockAuthService.shouldSucceed = true
        
        // Simply test that loading gets set during the operation
        // We can't reliably catch the exact moment it's true
        
        // When
        await viewModel.signIn(email: "test@example.com", password: "password")
        
        // Then - After completion
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after sign in completes")
        XCTAssertTrue(viewModel.isAuthenticated, "Should be authenticated")
        
        // Alternative: Test that isLoading is set to false after operation
        // This is what we can reliably test
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpSuccess() async {
        // Given
        mockAuthService.shouldSucceed = true
        let email = "newuser@example.com"
        let password = "newpassword123"
        
        // When
        await viewModel.signUp(email: email, password: password)
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated, "User should be authenticated")
        XCTAssertEqual(viewModel.userEmail, email, "Email should match")
        XCTAssertNil(viewModel.errorMessage, "No error should be present")
        XCTAssertEqual(mockAuthService.signUpCallCount, 1, "Sign up should be called once")
    }
    
    func testSignUpWithWeakPassword() async {
        // Given
        mockAuthService.shouldSucceed = false
        let email = "newuser@example.com"
        let password = "123" // Too short
        
        // When
        await viewModel.signUp(email: email, password: password)
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated, "User should not be authenticated")
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be present")
        XCTAssertEqual(mockAuthService.signUpCallCount, 1, "Sign up should be called once")
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOutSuccess() {
        // Given
        mockAuthService.shouldSucceed = true
        mockAuthService.mockUser = User(uid: "123", email: "test@example.com")
        
        // When
        viewModel.signOut()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated, "User should not be authenticated")
        XCTAssertNil(viewModel.currentUser, "Current user should be nil")
        XCTAssertEqual(mockAuthService.signOutCallCount, 1, "Sign out should be called once")
    }
    
    func testSignOutFailure() {
        // Given
        mockAuthService.shouldSucceed = false
        mockAuthService.mockUser = User(uid: "123", email: "test@example.com")
        
        // When
        viewModel.signOut()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be present")
        XCTAssertEqual(mockAuthService.signOutCallCount, 1, "Sign out should be called once")
    }
    
    // MARK: - Auth State Listener Tests
    
    func testAuthStateListenerUserLogin() {
        // Given
        let user = User(uid: "123", email: "test@example.com")
        
        // When
        mockAuthService.simulateUserStateChange(user: user)
        
        // Allow time for state update
        let expectation = expectation(description: "Auth state update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated, "User should be authenticated")
        XCTAssertEqual(viewModel.currentUser?.email, user.email, "User email should match")
    }
    
    func testAuthStateListenerUserLogout() {
        // Given
        viewModel.currentUser = User(uid: "123", email: "test@example.com")
        viewModel.isAuthenticated = true
        
        // When
        mockAuthService.simulateUserStateChange(user: nil)
        
        // Allow time for state update
        let expectation = expectation(description: "Auth state update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated, "User should not be authenticated")
        XCTAssertNil(viewModel.currentUser, "Current user should be nil")
    }
    
    // MARK: - Helper Methods Tests
    
    func testClearError() {
        // Given
        viewModel.errorMessage = "Some error message"
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage, "Error message should be cleared")
    }
    
    func testUserEmailProperty() {
        // Given
        viewModel.currentUser = User(uid: "123", email: "test@example.com")
        
        // Then
        XCTAssertEqual(viewModel.userEmail, "test@example.com", "User email should match")
        
        // When user is nil
        viewModel.currentUser = nil
        
        // Then
        XCTAssertEqual(viewModel.userEmail, "", "User email should be empty string")
    }
    
    func testUserUIDProperty() {
        // Given
        viewModel.currentUser = User(uid: "unique-id-123", email: "test@example.com")
        
        // Then
        XCTAssertEqual(viewModel.userUID, "unique-id-123", "User UID should match")
        
        // When user is nil
        viewModel.currentUser = nil
        
        // Then
        XCTAssertEqual(viewModel.userUID, "", "User UID should be empty string")
    }
    
    func testDisplayNameProperty() {
        // Given
        viewModel.currentUser = User(uid: "123", email: "test@example.com")
        
        // Then
        XCTAssertEqual(viewModel.displayName, "test@example.com", "Display name should be email")
        
        // When user is nil
        viewModel.currentUser = nil
        
        // Then
        XCTAssertEqual(viewModel.displayName, "User", "Display name should be 'User'")
    }
}
