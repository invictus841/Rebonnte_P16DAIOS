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
                LaunchScreenView()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, isAuthenticated in
            if isAuthenticated && !oldValue {
                Task {
                    await medicineViewModel.initializeApp()
                }
            } else if !isAuthenticated && oldValue {
                medicineViewModel.stopMedicinesListener()
                medicineViewModel.cleanup()
            }
        }
    }
}
