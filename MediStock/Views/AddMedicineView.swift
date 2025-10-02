//
//  AddMedicine.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 02/10/2025.
//

import SwiftUI

struct AddMedicineView: View {
    // Form fields
    @State private var name = ""
    @State private var stock = 0
    @State private var aisleNumber = 1
    
    // UI state
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    @State private var isSaving = false
    
    // Environment
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Focus management
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case name
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "pills.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primaryAccent)
                        
                        Text("Add New Medicine")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Fill in the details below")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        CustomTextField(
                            "Medicine Name",
                            text: $name,
                            placeholder: "e.g., Aspirin"
                        )
                        .focused($focusedField, equals: .name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        
                        NumberField(
                            "Initial Stock",
                            value: $stock,
                            in: 0...9999
                        )
                        .submitLabel(.next)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Aisle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Picker("Aisle", selection: $aisleNumber) {
                                ForEach(1..<100) { number in
                                    Text("Aisle \(number)").tag(number)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Validation Error
                    if showingValidationError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(validationMessage)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .padding(.horizontal)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        PrimaryButton("Save Medicine", isLoading: isSaving) {
                            saveMedicine()
                        }
                        .disabled(!isFormValid || isSaving)
                        
                        SecondaryButton("Cancel") {
                            dismiss()
                        }
                        .disabled(isSaving)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
        }
        .onSubmit {
            handleSubmit()
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        stock >= 0
    }
    
    private func validateForm() -> Bool {
        // Clear previous errors
        showingValidationError = false
        
        // Check name
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            validationMessage = "Please enter a medicine name"
            showingValidationError = true
            return false
        }
        
        if trimmedName.count < 2 {
            validationMessage = "Medicine name must be at least 2 characters"
            showingValidationError = true
            return false
        }
        
        // Check stock
        if stock < 0 {
            validationMessage = "Stock cannot be negative"
            showingValidationError = true
            return false
        }
        
        return true
    }
    
    // MARK: - Actions
    
    private func handleSubmit() {
        switch focusedField {
        case .name:
            if isFormValid {
                saveMedicine()
            }
        case .none:
            break
        }
    }
    
    private func saveMedicine() {
        // Validate
        guard validateForm() else { return }
        
        // Start saving
        isSaving = true
        
        // Trim values
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        // Create medicine object
        let newMedicine = Medicine(
            id: nil,
            name: trimmedName,
            stock: stock,
            aisle: "Aisle \(aisleNumber)"
        )
        
        // Save to Firebase
        Task {
            do {
                try await viewModel.addMedicine(
                    newMedicine,
                    user: authViewModel.userEmail
                )
                
                // Success - dismiss view
                await MainActor.run {
                    // Add haptic feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss()
                }
            } catch {
                // Error handling
                await MainActor.run {
                    isSaving = false
                    validationMessage = "Failed to save: \(error.localizedDescription)"
                    showingValidationError = true
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
        AddMedicineView()
            .environmentObject(AuthViewModel())
            .environmentObject(MedicineStockViewModel())
}
