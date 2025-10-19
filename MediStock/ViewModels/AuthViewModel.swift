//
//  AuthViewModel.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 25/09/2025.
//

import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.authService = authService
        startListening()
    }
    
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
    
    private func startListening() {
        authService.startAuthListener { [weak self] user in

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.currentUser = user
                self.isAuthenticated = user != nil
            }
        }
    }
    
    var userEmail: String {
        currentUser?.email ?? ""
    }
    
    var userUID: String {
        currentUser?.uid ?? ""
    }
    
    var displayName: String {
        currentUser?.email ?? "User"
    }
    
    deinit {
        authService.stopAuthListener()
        print("✅ AuthViewModel deallocated - No memory leak!")
    }
}
