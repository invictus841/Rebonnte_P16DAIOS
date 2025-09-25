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
            VStack(spacing: 24) {
                // User Info
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
                .padding()
                
                // User Details
                GroupBox("Account Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Email:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(authViewModel.userEmail)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("User ID:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(authViewModel.userUID.prefix(8) + "...")
                                .foregroundColor(.secondary)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Sign Out Button
                SecondaryButton("Sign Out") {
                    authViewModel.signOut()
                }
                .foregroundColor(.red)
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
