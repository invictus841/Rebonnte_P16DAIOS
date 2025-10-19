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
    
    var sut: AuthViewModel!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        sut = AuthViewModel(authService: mockAuthService)
    }
    
    override func tearDown() {
        sut = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Sign In Tests
    
    func test_signIn_withValidCredentials_authenticatesUser() async {
        // Given
        mockAuthService.shouldSucceed = true
        let email = "test@test.com"
        let password = "password123"
        
        // When
        await sut.signIn(email: email, password: password)
        
        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.userEmail, email)
    }
    
    func test_signIn_withInvalidCredentials_showsError() async {
        // Given
        mockAuthService.shouldSucceed = false
        let email = "wrong@test.com"
        let password = "wrongpass"
        
        // When
        await sut.signIn(email: email, password: password)
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func test_signIn_setsLoadingState() async {
        // Given
        mockAuthService.shouldSucceed = true
        let email = "test@test.com"
        let password = "password"
        
        // When
        await sut.signIn(email: email, password: password)
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    // MARK: - Sign Up Tests
    
    func test_signUp_withNewUser_createsAccount() async {
        // Given
        mockAuthService.shouldSucceed = true
        let email = "new@test.com"
        let password = "password123"
        
        // When
        await sut.signUp(email: email, password: password)
        
        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.userEmail, email)
    }
    
    func test_signUp_withWeakPassword_showsError() async {
        // Given
        mockAuthService.shouldSucceed = false
        let email = "test@test.com"
        let password = "123"
        
        // When
        await sut.signUp(email: email, password: password)
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Sign Out Tests
    
    func test_signOut_clearsUserData() {
        // Given
        mockAuthService.mockUser = User(uid: "123", email: "test@test.com")
        mockAuthService.shouldSucceed = true
        sut.currentUser = mockAuthService.mockUser
        sut.isAuthenticated = true
        
        // When
        sut.signOut()
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }
    
    func test_signOut_withError_setsErrorMessage() {
        // Given
        mockAuthService.shouldSucceed = false
        mockAuthService.mockUser = User(uid: "123", email: "test@test.com")
        
        // When
        sut.signOut()
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Auth State Listener Tests
    
    func test_authStateListener_whenUserLogsIn_updatesState() async {
        // Given
        let user = User(uid: "123", email: "test@test.com")
        
        // When
        mockAuthService.simulateUserStateChange(user: user)
        
        // Then
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUser?.email, user.email)
    }
    
    // MARK: - Helper Methods Tests
    
    func test_clearError_removesErrorMessage() {
        // Given
        sut.errorMessage = "Some error message"
        
        // When
        sut.clearError()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    func test_userEmail_returnsCorrectEmail() {
        // Given
        sut.currentUser = User(uid: "123", email: "test@test.com")
        
        // When
        let email = sut.userEmail
        
        // Then
        XCTAssertEqual(email, "test@test.com")
    }
    
    func test_userEmail_withNoUser_returnsEmptyString() {
        // Given
        sut.currentUser = nil
        
        // When
        let email = sut.userEmail
        
        // Then
        XCTAssertEqual(email, "")
    }
    
    func test_userUID_returnsCorrectUID() {
        // Given
        sut.currentUser = User(uid: "unique-123", email: "test@test.com")
        
        // When
        let uid = sut.userUID
        
        // Then
        XCTAssertEqual(uid, "unique-123")
    }
    
    func test_displayName_returnsEmail() {
        // Given
        sut.currentUser = User(uid: "123", email: "test@test.com")
        
        // When
        let displayName = sut.displayName
        
        // Then
        XCTAssertEqual(displayName, "test@test.com")
    }
    
    func test_displayName_withNoUser_returnsUser() {
        // Given
        sut.currentUser = nil
        
        // When
        let displayName = sut.displayName
        
        // Then
        XCTAssertEqual(displayName, "User")
    }
}
