
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var medicineViewModel: MedicineStockViewModel
    
    private var showMainApp: Bool {
        authViewModel.isAuthenticated && medicineViewModel.appState == .ready
    }

    var body: some View {
        Group {
            if !authViewModel.isAuthenticated {
                LoginView()
            } else if showMainApp {
                MainTabView()
            } else {
                // Loading state - show simple spinner while data loads
                LaunchScreenView()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, isAuthenticated in
            if isAuthenticated && !oldValue {
                // User just logged in - initialize app
                Task {
                    await medicineViewModel.initializeApp()
                }
            } else if !isAuthenticated && oldValue {
                // User logged out - cleanup
                medicineViewModel.stopMedicinesListener()
                medicineViewModel.stopHistoryListener()
                medicineViewModel.cleanup()
            }
        }
    }
}
