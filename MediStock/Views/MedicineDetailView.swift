import SwiftUI

struct MedicineDetailView: View {
    let medicine: Medicine
    
    @State private var stockAdjustment = 1
    @State private var isAddMode = true
    @State private var editedName: String
    @State private var editedAisleNumber: Int
    @State private var showSuccessMessage = false
    @State private var showStockPicker = false
    
    @State private var hasLoadedHistory = false
    
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Get the current version of this medicine from the ViewModel
    private var currentMedicine: Medicine? {
        viewModel.medicine(withId: medicine.id ?? "")
    }
    
    init(medicine: Medicine) {
        self.medicine = medicine
        self._editedName = State(initialValue: medicine.name)
        
        let aisleNum = Int(medicine.aisle.replacingOccurrences(of: "Aisle ", with: "")) ?? 1
        self._editedAisleNumber = State(initialValue: aisleNum)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Medicine Info Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Medicine Information")
                        .font(.headline)
                    
                    CustomTextField("Name", text: $editedName)
                    
                    HStack {
                        Text("Aisle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Aisle", selection: $editedAisleNumber) {
                            ForEach(1..<100) { num in
                                Text("Aisle \(num)").tag(num)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Save Changes Button (if edited)
                    if hasChanges {
                        PrimaryButton("Save Changes") {
                            saveChanges()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Stock Management Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Stock Management")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("Current: \(currentMedicine?.stock ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(stockColor)
                    }
                    
                    // Add/Remove Toggle
                    Picker("Mode", selection: $isAddMode) {
                        Text("Add Stock").tag(true)
                        Text("Remove Stock").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Quantity Selection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Quantity:")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    showStockPicker.toggle()
                                }
                            }) {
                                HStack {
                                    Text("\(stockAdjustment)")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    Image(systemName: showStockPicker ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if showStockPicker {
                            Picker("Quantity", selection: $stockAdjustment) {
                                ForEach(1..<100) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 120)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    // Apply Button
                    Button(action: applyStockChange) {
                        HStack {
                            Image(systemName: isAddMode ? "plus.circle" : "minus.circle")
                            Text("\(isAddMode ? "Add" : "Remove") \(stockAdjustment)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isAddMode ? Color.green : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Quick Actions
                    Text("Quick Actions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach([1, 5, 10], id: \.self) { amount in
                            HStack(spacing: 4) {
                                Button(action: { quickAdjust(-amount) }) {
                                    Image(systemName: "minus")
                                        .frame(width: 30, height: 30)
                                        .background(Color.red.opacity(0.8))
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                
                                Text("\(amount)")
                                    .font(.caption)
                                    .frame(minWidth: 20)
                                
                                Button(action: { quickAdjust(amount) }) {
                                    Image(systemName: "plus")
                                        .frame(width: 30, height: 30)
                                        .background(Color.green.opacity(0.8))
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // History Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent History")
                        .font(.headline)
                    
                    if viewModel.currentHistory.isEmpty {
                        Text("No history yet")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    } else {
                        ForEach(viewModel.currentHistory.prefix(10), id: \.id) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.action)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text(entry.timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(entry.user)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if !entry.details.isEmpty {
                                    Text(entry.details)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle(currentMedicine?.name ?? "Medicine")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(successOverlay)
        .onAppear {
            // Only load history once
            if !hasLoadedHistory, let id = medicine.id {
                viewModel.loadHistory(for: id)
                hasLoadedHistory = true
            }
        }
        .onDisappear {
            // Always stop the listener
            viewModel.stopHistoryListener()
            hasLoadedHistory = false
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasChanges: Bool {
        guard let current = currentMedicine else { return false }
        return editedName != current.name ||
               "Aisle \(editedAisleNumber)" != current.aisle
    }
    
    private var stockColor: Color {
        let stock = currentMedicine?.stock ?? 0
        if stock == 0 { return .red }
        if stock < 10 { return .orange }
        return .green
    }
    
    @ViewBuilder
    private var successOverlay: some View {
        if showSuccessMessage {
            VStack {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text("Success!")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color.green)
                .cornerRadius(12)
                .padding(.top, 50)
                
                Spacer()
            }
            .transition(.move(edge: .top))
            .animation(.spring(), value: showSuccessMessage)
        }
    }
    
    // MARK: - Actions
    
    private func applyStockChange() {
        guard let id = medicine.id else { return }
        
        let change = isAddMode ? stockAdjustment : -stockAdjustment
        
        Task {
            await viewModel.updateStock(
                medicineId: id,
                change: change,
                user: authViewModel.userEmail
            )
            
            showSuccess()
            stockAdjustment = 1
            showStockPicker = false
        }
    }
    
    private func quickAdjust(_ amount: Int) {
        guard let id = medicine.id else { return }
        
        Task {
            await viewModel.updateStock(
                medicineId: id,
                change: amount,
                user: authViewModel.userEmail
            )
            
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func saveChanges() {
        guard var updated = currentMedicine else { return }
        
        updated.name = editedName
        updated.aisle = "Aisle \(editedAisleNumber)"
        
        Task {
            await viewModel.updateMedicine(updated, user: authViewModel.userEmail)
            showSuccess()
        }
    }
    
    private func showSuccess() {
        showSuccessMessage = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Use a timer instead of Task.sleep - it's simpler and doesn't leak
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
    }
}

struct MedicineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MedicineDetailView(medicine: Medicine(id: "1", name: "Aspirin", stock: 25, aisle: "Aisle 1"))
                .environmentObject(AuthViewModel())
                .environmentObject(MedicineStockViewModel())
        }
    }
}
