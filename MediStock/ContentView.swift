import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var medicineViewModel: MedicineStockViewModel
    
    @State private var showMainApp = false
    
    private var isAppReady: Bool {
        medicineViewModel.appState == .ready
    }

    var body: some View {
        Group {
            if !authViewModel.isAuthenticated {
                // Not logged in - show login
                LoginView()
            } else {
                // Logged in - check app state
                ZStack {
                    // Main app (hidden during loading)
                    if showMainApp || isAppReady {  // Show if ready OR showMainApp is true
                        MainTabView()
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // Launch screen overlay
                    if !isAppReady {
                        LaunchScreenView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: medicineViewModel.appState)
                .onChange(of: medicineViewModel.appState) { _, newState in
                    if newState == .ready {
                        // Delay to show 100% progress before transitioning
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showMainApp = true
                            }
                        }
                    }
                }
                .task {
                    // Initialize app when authenticated
                    if medicineViewModel.appState == .initializing {
                        await medicineViewModel.initializeApp()
                    }
                }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, isAuthenticated in
            if isAuthenticated && !oldValue {
                // User just logged in - initialize app
                Task {
                    await medicineViewModel.initializeApp()
                }
            } else if !isAuthenticated && oldValue {
                // User logged out - AGGRESSIVE CLEANUP
                medicineViewModel.stopMedicinesListener()
                medicineViewModel.stopHistoryListener()
                medicineViewModel.cleanup()
                showMainApp = false
            }
        }
    }
}
