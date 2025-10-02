import SwiftUI

struct MedicineDetailView: View {
    let originalMedicine: Medicine
    @State private var editedMedicine: Medicine
    
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    // Track if fields have changed
    private var isDirty: Bool {
        editedMedicine.name != originalMedicine.name ||
        editedMedicine.aisle != originalMedicine.aisle
    }
    
    init(medicine: Medicine) {
        self.originalMedicine = medicine
        self._editedMedicine = State(initialValue: medicine)
    }

    var body: some View {
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
                    
                    CustomTextField(
                        "Aisle Location",
                        text: $editedMedicine.aisle
                    )
                    
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
                                user: authViewModel.userUID
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
                                user: authViewModel.userUID
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
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(entry.action)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("User: \(entry.user)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if !entry.details.isEmpty {
                                    Text(entry.details)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
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
        .navigationBarTitle("Medicine Details", displayMode: .inline)
        .onAppear {
            viewModel.fetchHistory(for: originalMedicine)
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        var updatedMedicine = originalMedicine
        updatedMedicine.name = editedMedicine.name.trimmingCharacters(in: .whitespaces)
        updatedMedicine.aisle = editedMedicine.aisle.trimmingCharacters(in: .whitespaces)
        
        viewModel.updateMedicine(updatedMedicine, user: authViewModel.userUID)
        
        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Go back after saving
        dismiss()
    }
    
    private func cancelChanges() {
        // Reset to original values
        editedMedicine = originalMedicine
        
        // Haptic feedback
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
