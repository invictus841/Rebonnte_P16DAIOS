//
//  MockAuthService.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 13/10/2025.
//

import Foundation
@testable import MediStock

class MockAuthService: AuthServiceProtocol {
    var shouldSucceed = true
    var mockUser: User?
    var signInCallCount = 0
    var signUpCallCount = 0
    var signOutCallCount = 0
    var authStateListener: ((User?) -> Void)?
    
    var currentUser: User? {
        return mockUser
    }
    
    func signIn(email: String, password: String) async -> AuthResult {
        signInCallCount += 1
        
        if shouldSucceed {
            let user = User(uid: "test-uid-123", email: email)
            mockUser = user
            return .success(user)
        } else {
            return .failure(.invalidCredentials)
        }
    }
    
    func signUp(email: String, password: String) async -> AuthResult {
        signUpCallCount += 1
        
        if shouldSucceed {
            let user = User(uid: "new-user-456", email: email)
            mockUser = user
            return .success(user)
        } else {
            if email.contains("existing") {
                return .failure(.emailAlreadyInUse)
            } else if password.count < 6 {
                return .failure(.weakPassword)
            }
            return .failure(.unknown("Test error"))
        }
    }
    
    func signOut() -> Result<Void, AuthError> {
        signOutCallCount += 1
        
        if shouldSucceed {
            mockUser = nil
            authStateListener?(nil)
            return .success(())
        } else {
            return .failure(.unknown("Sign out failed"))
        }
    }
    
    func startAuthListener(completion: @escaping (User?) -> Void) {
        authStateListener = completion
        completion(mockUser)
    }
    
    func stopAuthListener() {
        authStateListener = nil
    }
    
    func simulateUserStateChange(user: User?) {
        mockUser = user
        authStateListener?(user)
    }
}
