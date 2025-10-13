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
                LoginView()
            } else {
                ZStack {
                    if showMainApp || isAppReady {
                        MainTabView()
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    if !isAppReady {
                        LaunchScreenView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: medicineViewModel.appState)
                .onChange(of: medicineViewModel.appState) { _, newState in
                    if newState == .ready {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showMainApp = true
                            }
                        }
                    }
                }
                .task {
                    if medicineViewModel.appState == .initializing {
                        await medicineViewModel.initializeApp()
                    }
                }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, isAuthenticated in
            if isAuthenticated && !oldValue {
                Task {
                    await medicineViewModel.initializeApp()
                }
            } else if !isAuthenticated && oldValue {
                medicineViewModel.stopMedicinesListener()
                medicineViewModel.stopHistoryListener()
                medicineViewModel.cleanup()
                showMainApp = false
            }
        }
    }
}
