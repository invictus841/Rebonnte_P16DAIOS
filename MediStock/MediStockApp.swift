//
//  MediStockApp.swift
//  MediStock
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import SwiftUI

@main
struct MediStockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var medicineViewModel = MedicineStockViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(medicineViewModel)
                .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                    if !isAuthenticated {
                        medicineViewModel.stopListening()
                    }
                }
        }
    }
}
