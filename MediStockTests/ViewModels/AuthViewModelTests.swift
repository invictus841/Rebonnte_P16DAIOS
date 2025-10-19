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
        mockAuthService.shouldSucceed = true
        let email = "test@test.com"
        let password = "password123"
        
        await sut.signIn(email: email, password: password)
        
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.userEmail, email)
    }
    
    func test_signIn_withInvalidCredentials_showsError() async {
        mockAuthService.shouldSucceed = false
        let email = "wrong@test.com"
        let password = "wrongpass"
        
        await sut.signIn(email: email, password: password)
        
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func test_signIn_setsLoadingState() async {
        mockAuthService.shouldSucceed = true
        let email = "test@test.com"
        let password = "password"
        
        await sut.signIn(email: email, password: password)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    // MARK: - Sign Up Tests
    
    func test_signUp_withNewUser_createsAccount() async {
        mockAuthService.shouldSucceed = true
        let email = "new@test.com"
        let password = "password123"
        
        await sut.signUp(email: email, password: password)
        
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.userEmail, email)
    }
    
    func test_signUp_withWeakPassword_showsError() async {
        mockAuthService.shouldSucceed = false
        let email = "test@test.com"
        let password = "123"
        
        await sut.signUp(email: email, password: password)
        
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Sign Out Tests
    
    func test_signOut_clearsUserData() {
        mockAuthService.mockUser = User(uid: "123", email: "test@test.com")
        mockAuthService.shouldSucceed = true
        sut.currentUser = mockAuthService.mockUser
        sut.isAuthenticated = true
        
        sut.signOut()
        
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }
    
    func test_signOut_withError_setsErrorMessage() {
        mockAuthService.shouldSucceed = false
        mockAuthService.mockUser = User(uid: "123", email: "test@test.com")
        
        sut.signOut()
        
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Auth State Listener Tests
    
    func test_authStateListener_whenUserLogsIn_updatesState() async {
        let user = User(uid: "123", email: "test@test.com")
        
        mockAuthService.simulateUserStateChange(user: user)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUser?.email, user.email)
    }
    
    // MARK: - Helper Methods Tests
    
    func test_clearError_removesErrorMessage() {
        sut.errorMessage = "Some error message"
        
        sut.clearError()
        
        XCTAssertNil(sut.errorMessage)
    }
    
    func test_userEmail_returnsCorrectEmail() {
        sut.currentUser = User(uid: "123", email: "test@test.com")
        
        let email = sut.userEmail
        
        XCTAssertEqual(email, "test@test.com")
    }
    
    func test_userEmail_withNoUser_returnsEmptyString() {
        sut.currentUser = nil
        
        let email = sut.userEmail
        
        XCTAssertEqual(email, "")
    }
    
    func test_userUID_returnsCorrectUID() {
        sut.currentUser = User(uid: "unique-123", email: "test@test.com")
        
        let uid = sut.userUID
        
        XCTAssertEqual(uid, "unique-123")
    }
    
    func test_displayName_returnsEmail() {
        sut.currentUser = User(uid: "123", email: "test@test.com")
        
        let displayName = sut.displayName
        
        XCTAssertEqual(displayName, "test@test.com")
    }
    
    func test_displayName_withNoUser_returnsUser() {
        sut.currentUser = nil
        
        let displayName = sut.displayName
        
        XCTAssertEqual(displayName, "User")
    }
}
