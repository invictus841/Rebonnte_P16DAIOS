//
//  LaunchScreenView.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 06/10/2025.
//


import SwiftUI

struct LaunchScreenView: View {
    @EnvironmentObject var medicineViewModel: MedicineStockViewModel
    @State private var isAnimating = false
    @State private var logoScale: CGFloat = 0.8
    
    private var isErrorState: Bool {
        if case .error = medicineViewModel.appState {
            return true
        }
        return false
    }
    
    private var loadingMessage: String {
        switch medicineViewModel.appState {
        case .initializing:
            return "Initializing..."
        case .loading:
            if medicineViewModel.loadingProgress < 0.3 {
                return "Connecting to database..."
            } else if medicineViewModel.loadingProgress < 0.6 {
                return "Loading medicines..."
            } else if medicineViewModel.loadingProgress < 0.9 {
                return "Processing inventory..."
            } else {
                return "Almost ready..."
            }
        case .ready:
            return "Welcome to MediStock!"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var statusIcon: String {
        switch medicineViewModel.appState {
        case .error:
            return "exclamationmark.triangle.fill"
        default:
            return "pills.fill"
        }
    }
    
    private var statusColor: Color {
        switch medicineViewModel.appState {
        case .error:
            return .red
        default:
            return .blue
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [statusColor.opacity(0.8), statusColor.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: statusColor)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and App Name
                VStack(spacing: 20) {
                    ZStack {
                        // Background circle with pulse animation
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .scaleEffect(logoScale)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: logoScale
                            )
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 60))
                            .foregroundColor(statusColor)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                isErrorState ? .none :
                                Animation.linear(duration: 2)
                                    .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                    .onAppear {
                        logoScale = 1.1
                    }
                    
                    Text("MediStock")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Pharmacy Inventory Management")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Loading Section
                VStack(spacing: 20) {
                    // Progress Bar
                    if !isErrorState {
                        ZStack(alignment: .leading) {
                            // Background
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 250, height: 8)
                            
                            // Progress
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 250 * medicineViewModel.loadingProgress, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: medicineViewModel.loadingProgress)
                        }
                        
                        // Progress percentage
                        Text("\(Int(medicineViewModel.loadingProgress * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Loading Text with Icon
                    HStack(spacing: 10) {
                        switch medicineViewModel.appState {
                        case .loading:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        case .error:
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.white)
                        case .ready:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        default:
                            EmptyView()
                        }
                        
                        Text(loadingMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .animation(.none, value: loadingMessage)
                    }
                    .frame(height: 30)
                    
                    // Medicine count (if loaded)
                    if !medicineViewModel.allMedicines.isEmpty {
                        Text("\(medicineViewModel.allMedicines.count) medicines loaded")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    // Retry button for errors
                    if isErrorState {
                        Button(action: retryLoading) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .foregroundColor(statusColor)
                            .cornerRadius(20)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .frame(minHeight: 100)
                
                Spacer()
                
                // Version info
                VStack(spacing: 4) {
                    Text("MediStock v1.0.0")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("© 2025 Your Pharmacy")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func retryLoading() {
        Task {
            await medicineViewModel.initializeApp()
        }
    }
}

// Preview
struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
            .environmentObject(MedicineStockViewModel())
    }
}
