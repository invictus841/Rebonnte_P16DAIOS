//
//  AuthViewModel.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 25/09/2025.
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    // MARK: - Private Properties
    
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    
    init(authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.authService = authService
        startListening()
    }
    
    // MARK: - Public Methods
    
    func signIn(email: String, password: String) async {
        await performAuthAction {
            await authService.signIn(email: email, password: password)
        }
    }
    
    func signUp(email: String, password: String) async {
        await performAuthAction {
            await authService.signUp(email: email, password: password)
        }
    }
    
    func signOut() {
        clearError()
        
        let result = authService.signOut()
        switch result {
        case .success:
            break
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func startListening() {
        authService.startAuthListener { [weak self] user in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    private func performAuthAction(_ action: () async -> AuthResult) async {
        isLoading = true
        errorMessage = nil
        
        let result = await action()
        
        switch result {
        case .success(let user):
            currentUser = user
            isAuthenticated = true
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Validation Helpers
    
    func validateEmail(_ email: String) -> String? {
        if email.isEmpty {
            return "Email is required"
        }
        
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            return "Please enter a valid email address"
        }
        
        return nil
    }
    
    func validatePassword(_ password: String) -> String? {
        if password.isEmpty {
            return "Password is required"
        }
        
        if password.count < 6 {
            return "Password must be at least 6 characters"
        }
        
        return nil
    }
    
    func validateSignInForm(email: String, password: String) -> String? {
        if let emailError = validateEmail(email) {
            return emailError
        }
        
        if let passwordError = validatePassword(password) {
            return passwordError
        }
        
        return nil
    }
    
    // MARK: - Convenience Properties
    
    var userEmail: String {
        return currentUser?.email ?? ""
    }
    
    var userUID: String {
        return currentUser?.uid ?? ""
    }
    
    var displayName: String {
        return currentUser?.email ?? "User"
    }
    
    // MARK: - Cleanup
    
    deinit {
        print("AuthViewModel deinitialized")
        authService.stopAuthListener()
    }
}
