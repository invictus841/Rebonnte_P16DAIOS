//
//  LaunchScreenView.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 06/10/2025.
//


import SwiftUI

struct LaunchScreenView: View {
    @EnvironmentObject var medicineViewModel: MedicineStockViewModel
    @State private var isRotating = false
    
    private var isError: Bool {
        if case .error = medicineViewModel.appState {
            return true
        }
        return false
    }
    
    private var message: String {
        if isError {
            if case .error(let errorMessage) = medicineViewModel.appState {
                return errorMessage
            }
        }
        return "Loading..."
    }
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: isError ? "exclamationmark.triangle.fill" : "pills.fill")
                        .font(.system(size: 60))
                        .foregroundColor(isError ? .red : .blue)
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .animation(
                            isError ? .none : .linear(duration: 2).repeatForever(autoreverses: false),
                            value: isRotating
                        )
                }
                
                Text("MediStock")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !isError {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                
                if isError {
                    Button("Retry") {
                        Task {
                            await medicineViewModel.initializeApp()
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(25)
                    .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .onAppear {
            isRotating = true
        }
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
            .environmentObject(MedicineStockViewModel())
    }
}
