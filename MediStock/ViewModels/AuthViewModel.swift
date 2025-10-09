//
//  AuthViewModel.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 25/09/2025.
//

import Foundation
// NO FIREBASE IMPORTS! 🚫

@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    // MARK: - Dependencies (Using Protocol!)
    
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization with Dependency Injection
    
    init(authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.authService = authService
        startListening()
    }
    
    // MARK: - Public Methods
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        let result = await authService.signIn(email: email, password: password)
        
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
    
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        let result = await authService.signUp(email: email, password: password)
        
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
    
    func signOut() {
        clearError()
        
        let result = authService.signOut()
        switch result {
        case .success:
            currentUser = nil
            isAuthenticated = false
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
            Task { @MainActor [weak self] in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Convenience Properties
    
    var userEmail: String {
        currentUser?.email ?? ""
    }
    
    var userUID: String {
        currentUser?.uid ?? ""
    }
    
    var displayName: String {
        currentUser?.email ?? "User"
    }
    
    // MARK: - Cleanup
    
    deinit {
        authService.stopAuthListener()
    }
}
