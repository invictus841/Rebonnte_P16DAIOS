import Foundation

class MedicineStockViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var medicines: [Medicine] = []
    @Published var aisles: [String] = []
    @Published var history: [HistoryEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let medicineService: MedicineServiceProtocol
    
    // MARK: - Initialization
    
    init(medicineService: MedicineServiceProtocol = FirebaseMedicineService()) {
        self.medicineService = medicineService
    }
    
    // MARK: - Fetch Methods
    
    func fetchMedicines() {
        medicineService.startMedicinesListener { [weak self] medicines in
            Task { @MainActor in
                self?.medicines = medicines
            }
        }
    }
    
    func fetchAisles() {
        medicineService.startMedicinesListener { [weak self] medicines in
            Task { @MainActor in
                self?.medicines = medicines
                self?.aisles = Array(Set(medicines.map { $0.aisle })).sorted()
            }
        }
    }
    
    func fetchHistory(for medicine: Medicine) {
        guard let medicineId = medicine.id else { return }
        
        medicineService.startHistoryListener(for: medicineId) { [weak self] history in
            Task { @MainActor in
                self?.history = history
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    func addMedicine(_ medicine: Medicine, user: String) async throws {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let medicineId = try await medicineService.addMedicine(medicine)
            
            // Add history entry
            let entry = HistoryEntry(
                medicineId: medicineId,
                user: user,
                action: "Added \(medicine.name)",
                details: "Added new medicine with initial stock of \(medicine.stock) in \(medicine.aisle)"
            )
            
            try await medicineService.addHistoryEntry(entry)
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func deleteMedicine(id: String, medicineName: String, user: String) {
        Task { @MainActor in
            self.isLoading = true
            self.errorMessage = nil
            
            do {
                try await medicineService.deleteMedicine(id: id)
                
                // Add history entry
                let entry = HistoryEntry(
                    medicineId: id,
                    user: user,
                    action: "Deleted \(medicineName)",
                    details: "Medicine removed from inventory"
                )
                
                try await medicineService.addHistoryEntry(entry)
                
                // Remove from local array
                if let index = self.medicines.firstIndex(where: { $0.id == id }) {
                    self.medicines.remove(at: index)
                }
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                print("Error deleting medicine: \(error)")
            }
        }
    }
    
    func updateMedicine(_ medicine: Medicine, user: String) {
        guard let id = medicine.id else { return }
        
        // Find the original medicine
        guard let originalMedicine = medicines.first(where: { $0.id == id }) else {
            Task {
                try? await medicineService.updateMedicine(medicine)
            }
            return
        }
        
        // Track changes
        var changes: [String] = []
        
        if originalMedicine.name != medicine.name {
            changes.append("Name: '\(originalMedicine.name)' → '\(medicine.name)'")
        }
        
        if originalMedicine.aisle != medicine.aisle {
            changes.append("Aisle: '\(originalMedicine.aisle)' → '\(medicine.aisle)'")
        }
        
        guard !changes.isEmpty else { return }
        
        Task { @MainActor in
            self.isLoading = true
            self.errorMessage = nil
            
            do {
                try await medicineService.updateMedicine(medicine)
                
                let action = changes.count == 1 ? "Updated \(medicine.name)" : "Updated \(medicine.name) (multiple fields)"
                let details = changes.joined(separator: "\n")
                
                let entry = HistoryEntry(
                    medicineId: id,
                    user: user,
                    action: action,
                    details: details
                )
                
                try await medicineService.addHistoryEntry(entry)
                
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                print("Error updating medicine: \(error)")
            }
        }
    }
    
    // MARK: - Stock Management
    
    func increaseStock(_ medicine: Medicine, user: String) {
        updateStock(medicine, by: 1, user: user)
    }
    
    func decreaseStock(_ medicine: Medicine, user: String) {
        updateStock(medicine, by: -1, user: user)
    }
    
    private func updateStock(_ medicine: Medicine, by amount: Int, user: String) {
        guard let id = medicine.id else { return }
        
        let oldStock = medicine.stock
        let newStock = oldStock + amount
        
        Task { @MainActor in
            self.isLoading = true
            self.errorMessage = nil
            
            do {
                try await medicineService.updateStock(medicineId: id, newStock: newStock)
                
                // Update local array
                if let index = self.medicines.firstIndex(where: { $0.id == id }) {
                    self.medicines[index].stock = newStock
                }
                
                let entry = HistoryEntry(
                    medicineId: id,
                    user: user,
                    action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(abs(amount))",
                    details: "Stock changed from \(oldStock) to \(newStock)"
                )
                
                try await medicineService.addHistoryEntry(entry)
                
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                print("Error updating stock: \(error)")
            }
        }
    }
    
    // MARK: - Cleanup
    
    func stopListening() {
        medicineService.stopAllListeners()
        medicines = []
        aisles = []
        history = []
    }
    
    deinit {
        medicineService.stopAllListeners()
    }
}
