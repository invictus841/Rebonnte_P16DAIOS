//
//  ProfileView.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 25/09/2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
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
                                    .accessibilityLabel("Logged in as \(authViewModel.userEmail)")
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
                    
                    VStack(spacing: 16) {
                        SecondaryButton("Sign Out") {
                            authViewModel.signOut()
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .accessibilityLabel("Sign out button")
                        .accessibilityHint("Double tap to sign out of your account")
                        
                        Text("MediStock v1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("App version 1.0.0")
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
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
