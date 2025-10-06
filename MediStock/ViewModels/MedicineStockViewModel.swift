import Foundation

class MedicineStockViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var medicines: [Medicine] = []
    @Published var aisles: [String] = []
    @Published var aisleMedicines: [Medicine] = []  // Medicines for a specific aisle
    @Published var history: [HistoryEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var historyLimit = 5   // Default: 5 history entries
    @Published var medicinesLimit = 10  // Default: 10 medicines
    @Published var historyPageSize = 5  // User can change this (5/10/20)
    @Published var medicinesPageSize = 10  // User can change this (5/10/20)
    
    // MARK: - Private Properties
    
    private let medicineService: MedicineServiceProtocol
    
    // Track which medicine's history is currently being observed
    private var currentHistoryMedicineId: String?
    
    // MARK: - Initialization
    
    init(medicineService: MedicineServiceProtocol = FirebaseMedicineService()) {
        self.medicineService = medicineService
    }
    
    // MARK: - Fetch Methods
    
    func fetchMedicines() {
        medicineService.startMedicinesListener(limit: medicinesLimit) { [weak self] medicines in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.medicines = medicines
                print("✅ Medicines loaded: \(medicines.count) (limit: \(self?.medicinesLimit ?? 10))")
            }
        }
    }
    
    func loadMoreMedicines() {
        // Increase limit by page size
        medicinesLimit += medicinesPageSize
        
        // Restart listener with new limit
        medicineService.startMedicinesListener(limit: medicinesLimit) { [weak self] medicines in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.medicines = medicines
                print("✅ Loaded more medicines: \(medicines.count) entries")
            }
        }
    }
    
    func fetchAisles() {
        // Load ALL medicines (no limit) to get complete aisles list
        medicineService.startAllMedicinesListener { [weak self] medicines in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.medicines = medicines
                self?.aisles = Array(Set(medicines.map { $0.aisle })).sorted()
                print("✅ Aisles extracted from \(medicines.count) medicines: \(self?.aisles.count ?? 0) aisles found")
            }
        }
    }
    
    // NEW: Fetch medicines for a specific aisle (Firebase-side filtering)
    func fetchMedicinesForAisle(_ aisle: String) {
        medicineService.startAisleMedicinesListener(aisle: aisle) { [weak self] medicines in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.aisleMedicines = medicines
                print("✅ Aisle medicines loaded: \(medicines.count) for '\(aisle)'")
            }
        }
    }
    
    func fetchHistory(for medicine: Medicine) {
        guard let medicineId = medicine.id else { return }
        
        // Don't create a new listener if we're already listening to this medicine
        if currentHistoryMedicineId == medicineId {
            return
        }
        
        // Reset limit to initial page size when viewing new medicine
        historyLimit = historyPageSize
        
        // Clear old history before fetching new one
        Task { @MainActor in
            self.history = []
        }
        
        currentHistoryMedicineId = medicineId
        
        medicineService.startHistoryListener(for: medicineId, limit: historyLimit) { [weak self] history in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                // Only update if we're still interested in this medicine
                guard self?.currentHistoryMedicineId == medicineId else { return }
                
                // History is already sorted by Firebase query (newest first)
                self?.history = history
                
                print("✅ History loaded: \(history.count) entries (limit: \(self?.historyLimit ?? 5))")
            }
        }
    }
    
    // Load more history entries
    func loadMoreHistory(for medicine: Medicine) {
        guard let medicineId = medicine.id,
              medicineId == currentHistoryMedicineId else { return }
        
        // Increase limit by page size
        historyLimit += historyPageSize
        
        // Restart listener with new limit
        medicineService.startHistoryListener(for: medicineId, limit: historyLimit) { [weak self] history in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard self?.currentHistoryMedicineId == medicineId else { return }
                self?.history = history
                print("✅ Loaded more history: \(history.count) entries")
            }
        }
    }
    
    // Clear history when leaving detail view
    func clearHistory() {
        Task { @MainActor in
            self.history = []
            self.historyLimit = historyPageSize  // Reset to page size
        }
        currentHistoryMedicineId = nil
        medicineService.stopHistoryListener()
    }
    
    // MARK: - CRUD Operations
    
    func addMedicine(_ medicine: Medicine, user: String) async throws {
        await MainActor.run { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        do {
            let medicineId = try await medicineService.addMedicine(medicine)
            
            let entry = HistoryEntry(
                medicineId: medicineId,
                user: user,
                action: "Added \(medicine.name)",
                details: "Added new medicine with initial stock of \(medicine.stock) in \(medicine.aisle)"
            )
            
            try await medicineService.addHistoryEntry(entry)
            
            await MainActor.run { [weak self] in
                self?.isLoading = false
            }
        } catch {
            await MainActor.run { [weak self] in
                self?.isLoading = false
                self?.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func deleteMedicine(id: String, medicineName: String, user: String) {
        Task { @MainActor [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
            
            do {
                try await self?.medicineService.deleteMedicine(id: id)
                
                let entry = HistoryEntry(
                    medicineId: id,
                    user: user,
                    action: "Deleted \(medicineName)",
                    details: "Medicine removed from inventory"
                )
                
                try await self?.medicineService.addHistoryEntry(entry)
                
                if let index = self?.medicines.firstIndex(where: { $0.id == id }) {
                    self?.medicines.remove(at: index)
                }
                self?.isLoading = false
            } catch {
                self?.isLoading = false
                self?.errorMessage = error.localizedDescription
                print("Error deleting medicine: \(error)")
            }
        }
    }
    
    func updateMedicine(_ medicine: Medicine, user: String) {
        guard let id = medicine.id else { return }
        guard let originalMedicine = medicines.first(where: { $0.id == id }) else {
            Task {
                try? await medicineService.updateMedicine(medicine)
            }
            return
        }
        
        var changes: [String] = []
        
        if originalMedicine.name != medicine.name {
            changes.append("Name: '\(originalMedicine.name)' → '\(medicine.name)'")
        }
        
        if originalMedicine.aisle != medicine.aisle {
            changes.append("Aisle: '\(originalMedicine.aisle)' → '\(medicine.aisle)'")
        }
        
        guard !changes.isEmpty else { return }
        
        Task { @MainActor [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
            
            do {
                try await self?.medicineService.updateMedicine(medicine)
                
                let action = changes.count == 1 ? "Updated \(medicine.name)" : "Updated \(medicine.name) (multiple fields)"
                let details = changes.joined(separator: "\n")
                
                let entry = HistoryEntry(
                    medicineId: id,
                    user: user,
                    action: action,
                    details: details
                )
                
                try await self?.medicineService.addHistoryEntry(entry)
                
                self?.isLoading = false
            } catch {
                self?.isLoading = false
                self?.errorMessage = error.localizedDescription
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
        
        Task { @MainActor [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
            
            do {
                try await self?.medicineService.updateStock(medicineId: id, newStock: newStock)
                
                if let index = self?.medicines.firstIndex(where: { $0.id == id }) {
                    self?.medicines[index].stock = newStock
                }
                
                let entry = HistoryEntry(
                    medicineId: id,
                    user: user,
                    action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(abs(amount))",
                    details: "Stock changed from \(oldStock) to \(newStock)"
                )
                
                try await self?.medicineService.addHistoryEntry(entry)
                
                self?.isLoading = false
            } catch {
                self?.isLoading = false
                self?.errorMessage = error.localizedDescription
                print("Error updating stock: \(error)")
            }
        }
    }
    
    // MARK: - Cleanup
    
    func stopListening() {
        medicineService.stopAllListeners()
        Task { @MainActor in
            self.medicines = []
            self.aisles = []
            self.history = []
            self.medicinesLimit = medicinesPageSize  // Reset to page size
            self.historyLimit = historyPageSize      // Reset to page size
        }
        currentHistoryMedicineId = nil
    }
    
    deinit {
        print("MedicineStockViewModel deinitialized")
        medicineService.stopAllListeners()
    }
}
