//
//  ProfileView.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 25/09/2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var medicineViewModel: MedicineStockViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // User Info Section
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.primaryAccent)
                        
                        VStack(spacing: 4) {
                            Text("Welcome")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(authViewModel.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Account Information Card
                    GroupBox("Account Information") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Email:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(authViewModel.userEmail)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("User ID:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(String(authViewModel.userUID.prefix(8)) + "...")
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    
                    // Inventory Statistics Card
                    GroupBox("Inventory Statistics") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Total Medicines", systemImage: "pills")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(medicineViewModel.allMedicines.count)")
                                    .font(.headline)
                                    .foregroundColor(.primaryAccent)
                            }
                            
                            Divider()
                            
                            HStack {
                                Label("Total Aisles", systemImage: "rectangle.stack")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(medicineViewModel.aisles.count)")
                                    .font(.headline)
                                    .foregroundColor(.primaryAccent)
                            }
                            
                            // Low stock alert
                            let lowStockCount = medicineViewModel.allMedicines.filter { $0.stock > 0 && $0.stock < 10 }.count
                            if lowStockCount > 0 {
                                Divider()
                                
                                HStack {
                                    Label("Low Stock Alert", systemImage: "exclamationmark.triangle.fill")
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                    Spacer()
                                    Text("\(lowStockCount)")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            // Out of stock alert
                            let outOfStockCount = medicineViewModel.allMedicines.filter { $0.stock == 0 }.count
                            if outOfStockCount > 0 {
                                Divider()
                                
                                HStack {
                                    Label("Out of Stock", systemImage: "exclamationmark.circle.fill")
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                    Spacer()
                                    Text("\(outOfStockCount)")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    
                    // Sign Out Section
                    VStack(spacing: 16) {
                        SecondaryButton("Sign Out") {
                            authViewModel.signOut()
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        
                        // App Version
                        Text("MediStock v1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40) // Extra padding for tab bar
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
            .environmentObject(MedicineStockViewModel())
    }
}
