//
//  AuthService.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 25/09/2025.
//

import Foundation
import FirebaseAuth

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "No user found with this email"
        case .emailAlreadyInUse:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password should be at least 6 characters"
        case .networkError:
            return "Network connection error. Please try again."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Auth Result

enum AuthResult {
    case success(User)
    case failure(AuthError)
}

// MARK: - Auth Service Protocol

protocol AuthServiceProtocol {
    var currentUser: User? { get }
    
    func signIn(email: String, password: String) async -> AuthResult
    
    func signUp(email: String, password: String) async -> AuthResult
    
    func signOut() -> Result<Void, AuthError>
    
    func startAuthListener(completion: @escaping (User?) -> Void)
    
    func stopAuthListener()
}

// MARK: - Firebase Auth Service Implementation

class FirebaseAuthService: AuthServiceProtocol {
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    var currentUser: User? {
        guard let firebaseUser = Auth.auth().currentUser else { return nil }
        return User(uid: firebaseUser.uid, email: firebaseUser.email)
    }
    
    func signIn(email: String, password: String) async -> AuthResult {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = User(uid: result.user.uid, email: result.user.email)
            return .success(user)
        } catch {
            return .failure(mapFirebaseError(error))
        }
    }
    
    func signUp(email: String, password: String) async -> AuthResult {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = User(uid: result.user.uid, email: result.user.email)
            return .success(user)
        } catch {
            return .failure(mapFirebaseError(error))
        }
    }
    
    func signOut() -> Result<Void, AuthError> {
        do {
            try Auth.auth().signOut()
            return .success(())
        } catch {
            return .failure(mapFirebaseError(error))
        }
    }
    
    func startAuthListener(completion: @escaping (User?) -> Void) {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard self != nil else { return }
            
            let user = firebaseUser.map { User(uid: $0.uid, email: $0.email) }
            completion(user)
        }
    }
    
    func stopAuthListener() {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authHandle = nil
        }
    }
    
    
    private func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.userNotFound.rawValue:
            return .userNotFound
        case AuthErrorCode.wrongPassword.rawValue, AuthErrorCode.invalidCredential.rawValue:
            return .invalidCredentials
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .emailAlreadyInUse
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.networkError.rawValue:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
    deinit {
        stopAuthListener()
        print("✅ FirebaseAuthService deallocated - No memory leak!")
    }
}
