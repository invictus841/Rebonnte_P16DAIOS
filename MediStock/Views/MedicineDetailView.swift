import SwiftUI

struct MedicineDetailView: View {
    let originalMedicine: Medicine
    @State private var editedMedicine: Medicine
    @State private var aisleNumber: Int
    @State private var showSuccessMessage = false
    
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    private var isDirty: Bool {
        editedMedicine.name != originalMedicine.name ||
        aisleNumber != (Int(originalMedicine.aisle.components(separatedBy: " ").last ?? "1") ?? 1)
    }
    
    init(medicine: Medicine) {
        self.originalMedicine = medicine
        self._editedMedicine = State(initialValue: medicine)
        
        // Extract number from "Aisle 5" -> 5
        let components = medicine.aisle.components(separatedBy: " ")
        let number = Int(components.last ?? "1") ?? 1
        self._aisleNumber = State(initialValue: number)
    }

    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text(originalMedicine.name)
                        .font(.largeTitle)
                        .padding(.top, 20)
                        .padding(.horizontal)

                    // Medicine Name
                    VStack(alignment: .leading, spacing: 16) {
                        CustomTextField(
                            "Medicine Name",
                            text: $editedMedicine.name
                        )
                        
                        HStack {
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
                        
                        // Show Save/Cancel buttons when fields are edited
                        if isDirty {
                            HStack(spacing: 12) {
                                PrimaryButton("Save Changes") {
                                    saveChanges()
                                }
                                
                                SecondaryButton("Cancel") {
                                    cancelChanges()
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.3), value: isDirty)

                    // Medicine Stock
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stock")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            IconButton(
                                systemName: "minus.circle.fill",
                                size: 44,
                                backgroundColor: .red.opacity(0.8),
                                foregroundColor: .white,
                                accessibilityLabel: "Decrease stock"
                            ) {
                                viewModel.decreaseStock(
                                    originalMedicine,
                                    user: authViewModel.userEmail
                                )
                            }
                            
                            Text("\(originalMedicine.stock)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .frame(minWidth: 80)
                                .multilineTextAlignment(.center)
                            
                            IconButton(
                                systemName: "plus.circle.fill",
                                size: 44,
                                backgroundColor: .green.opacity(0.8),
                                foregroundColor: .white,
                                accessibilityLabel: "Increase stock"
                            ) {
                                viewModel.increaseStock(
                                    originalMedicine,
                                    user: authViewModel.userEmail
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // History Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("History")
                            .font(.headline)
                            .padding(.top, 20)
                        
                        if viewModel.history.filter({ $0.medicineId == originalMedicine.id }).isEmpty {
                            EmptyStateView(
                                systemName: "clock",
                                title: "No History Yet",
                                message: "Changes to this medicine will appear here"
                            )
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            ForEach(viewModel.history.filter { $0.medicineId == originalMedicine.id }.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { entry in
                                VStack(alignment: .leading, spacing: 8) {
                                    // Action header
                                    HStack {
                                        Image(systemName: iconForAction(entry.action))
                                            .foregroundColor(colorForAction(entry.action))
                                            .font(.caption)
                                        
                                        Text(entry.action)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // User
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(entry.user)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Details
                                    if !entry.details.isEmpty {
                                        Text(entry.details)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .padding(.top, 4)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            
            // Success message overlay - last element in ZStack
            if showSuccessMessage {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        
                        Text("Changes saved successfully")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuccessMessage)
            }
        }
        .navigationBarTitle("Medicine Details", displayMode: .inline)
        .onAppear {
            viewModel.fetchHistory(for: originalMedicine)
        }
    }
    
    private func iconForAction(_ action: String) -> String {
        if action.contains("Increased") {
            return "arrow.up.circle.fill"
        } else if action.contains("Decreased") {
            return "arrow.down.circle.fill"
        } else if action.contains("Added") {
            return "plus.circle.fill"
        } else if action.contains("Deleted") {
            return "trash.circle.fill"
        } else if action.contains("Updated") {
            return "pencil.circle.fill"
        }
        return "info.circle.fill"
    }
    
    private func colorForAction(_ action: String) -> Color {
        if action.contains("Increased") {
            return .green
        } else if action.contains("Decreased") {
            return .red
        } else if action.contains("Added") {
            return .blue
        } else if action.contains("Deleted") {
            return .orange
        } else if action.contains("Updated") {
            return .purple
        }
        return .gray
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        var updatedMedicine = originalMedicine
        updatedMedicine.name = editedMedicine.name.trimmingCharacters(in: .whitespaces)
        updatedMedicine.aisle = "Aisle \(aisleNumber)"
        
        viewModel.updateMedicine(updatedMedicine, user: authViewModel.userEmail)
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Show success message
        showSuccessMessage = true
        
        // Hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
    }
    
    private func cancelChanges() {
        editedMedicine = originalMedicine
        
        // Reset aisle number too
        let components = originalMedicine.aisle.components(separatedBy: " ")
        aisleNumber = Int(components.last ?? "1") ?? 1
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct MedicineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMedicine = Medicine(name: "Aspirin", stock: 25, aisle: "Aisle 1")
        NavigationView {
            MedicineDetailView(medicine: sampleMedicine)
                .environmentObject(AuthViewModel())
                .environmentObject(MedicineStockViewModel())
        }
    }
}
