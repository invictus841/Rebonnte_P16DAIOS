import SwiftUI

struct MedicineDetailView: View {
    let medicineId: String  // Store ID instead of whole medicine object
    
    @State private var stockAdjustment = 1
    @State private var isAddMode = true
    @State private var editedName: String = ""
    @State private var editedAisleNumber: Int = 1
    @State private var showSuccessMessage = false
    @State private var showStockPicker = false
    @State private var hasLoadedHistory = false
    @State private var hasInitialized = false
    
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Always get fresh medicine data from viewModel
    private var currentMedicine: Medicine? {
        viewModel.medicine(withId: medicineId)
    }
    
    init(medicine: Medicine) {
        self.medicineId = medicine.id ?? ""
        self._editedName = State(initialValue: medicine.name)
        self._editedAisleNumber = State(initialValue: medicine.aisle)
    }
    
    var body: some View {
        Group {
            if let medicine = currentMedicine {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Medicine Info Card
                        medicineInfoCard
                        
                        // Stock Management Card
                        stockManagementCard(for: medicine)
                        
                        // History Card
                        historyCard
                    }
                    .padding()
                }
                .navigationTitle(medicine.name)
                .navigationBarTitleDisplayMode(.inline)
                .overlay(successOverlay)
                .task {
                    if !hasInitialized {
                        hasInitialized = true
                        // Update edited values if medicine data changed
                        editedName = medicine.name
                        editedAisleNumber = medicine.aisle
                        
                        // Load history
                        if !hasLoadedHistory {
                            viewModel.loadHistory(for: medicineId)
                            hasLoadedHistory = true
                        }
                    }
                }
                .onDisappear {
                    viewModel.currentHistory = []
                    viewModel.stopHistoryListener()
                    hasLoadedHistory = false
                    print("🧹 Detail view dismissed - cleaned history")
                }
            } else {
                // Medicine not found or deleted
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    Text("Medicine not found")
                        .font(.headline)
                    Text("This medicine may have been deleted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Medicine Info Card
    private var medicineInfoCard: some View {
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
            
            if hasChanges {
                PrimaryButton("Save Changes") {
                    saveChanges()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Stock Management Card
    private func stockManagementCard(for medicine: Medicine) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stock Management")
                    .font(.headline)
                
                Spacer()
                
                Text("Current: \(medicine.stock)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(stockColor(for: medicine.stock))
            }
            
            Picker("Mode", selection: $isAddMode) {
                Text("Add Stock").tag(true)
                Text("Remove Stock").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            
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
    }
    
    // MARK: - History Card
    private var historyCard: some View {
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
    
    // MARK: - Computed Properties
    private var hasChanges: Bool {
        guard let current = currentMedicine else { return false }
        return editedName != current.name ||
               editedAisleNumber != current.aisle
    }
    
    private func stockColor(for stock: Int) -> Color {
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
        let change = isAddMode ? stockAdjustment : -stockAdjustment
        
        Task {
            await viewModel.updateStock(
                medicineId: medicineId,
                change: change,
                user: authViewModel.userEmail
            )
            
            showSuccess()
            stockAdjustment = 1
            showStockPicker = false
        }
    }
    
    private func quickAdjust(_ amount: Int) {
        Task {
            await viewModel.updateStock(
                medicineId: medicineId,
                change: amount,
                user: authViewModel.userEmail
            )
            
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func saveChanges() {
        guard var updated = currentMedicine else { return }
        
        updated.name = editedName
        updated.aisle = editedAisleNumber
        
        Task {
            await viewModel.updateMedicine(updated, user: authViewModel.userEmail)
            showSuccess()
        }
    }
    
    private func showSuccess() {
        showSuccessMessage = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
    }
}

struct MedicineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MedicineDetailView(medicine: Medicine(id: "1", name: "Aspirin", stock: 25, aisle: 1))
                .environmentObject(AuthViewModel())
                .environmentObject(MedicineStockViewModel())
        }
    }
}
