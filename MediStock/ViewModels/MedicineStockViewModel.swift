import Foundation

@MainActor
class MedicineStockViewModel: ObservableObject {
    
    enum LoadingState: Equatable {
        case initializing
        case loading
        case ready
        case error(String)
    }
    
    @Published var appState: LoadingState = .initializing
    @Published var loadingProgress: Double = 0
    
    @Published var allMedicines: [Medicine] = []
    @Published var currentHistory: [HistoryEntry] = []
    @Published var errorMessage: String?
    
    @Published var isLoadingMore = false
    @Published var hasMoreMedicines = true
    private var lastLoadedValue: Any?
    
    @Published var currentSortField: MedicineSortField = .name
    @Published var currentSortOrder: MedicineSortOrder = .ascending
    
    private let pageSize = 2
    
    private let medicineService: MedicineServiceProtocol
    private var hasInitialized = false
    
    var aisles: [Int] {
        let uniqueAisles = Set(allMedicines.map { $0.aisle })
        return Array(uniqueAisles).sorted()
    }
    
    func medicinesForAisle(_ aisle: Int) -> [Medicine] {
        allMedicines.filter { $0.aisle == aisle }
    }
    
    func medicine(withId id: String) -> Medicine? {
        allMedicines.first { $0.id == id }
    }
    
    init(medicineService: MedicineServiceProtocol = FirebaseMedicineService()) {
        self.medicineService = medicineService
    }
    
    // Simple initialization without launch screen
    func initializeApp() async {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        appState = .loading
        
        // Load initial batch of medicines
        await loadInitialMedicines()
        
        appState = .ready
    }
    
    // Load first page of medicines
    private func loadInitialMedicines() async {
        do {
            let medicines = try await medicineService.loadMedicines(
                limit: pageSize,
                startAfter: nil,
                sortBy: currentSortField,
                order: currentSortOrder
            )
            
            allMedicines = medicines
            lastLoadedValue = getLastValue(from: medicines)
            hasMoreMedicines = medicines.count == pageSize
            
            print("✅ Loaded \(medicines.count) medicines (initial page)")
            
        } catch {
            print("❌ Error loading medicines: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    // Helper to sort medicines
    private func sortMedicines(_ medicines: [Medicine]) -> [Medicine] {
        medicines.sorted { med1, med2 in
            switch currentSortField {
            case .name:
                return currentSortOrder == .ascending ? med1.name < med2.name : med1.name > med2.name
            case .stock:
                return currentSortOrder == .ascending ? med1.stock < med2.stock : med1.stock > med2.stock
            case .aisle:
                return currentSortOrder == .ascending ? med1.aisle < med2.aisle : med1.aisle > med2.aisle
            }
        }
    }
    
    func loadMoreMedicines() async {
        guard !isLoadingMore else {
            print("⚠️ Already loading, skipping")
            return
        }
        
        guard hasMoreMedicines else {
            print("⚠️ No more medicines to load")
            return
        }
        
        isLoadingMore = true
        
        do {
            let newMedicines = try await medicineService.loadMedicines(
                limit: pageSize,
                startAfter: lastLoadedValue,
                sortBy: currentSortField,
                order: currentSortOrder
            )
            
            if newMedicines.isEmpty {
                hasMoreMedicines = false
                print("✅ Loaded 0 medicines - all loaded! (total: \(allMedicines.count))")
            } else {
                allMedicines.append(contentsOf: newMedicines)
                lastLoadedValue = getLastValue(from: newMedicines)

                if newMedicines.count < pageSize {
                    hasMoreMedicines = false
                    print("✅ Loaded \(newMedicines.count) medicines (final page, total: \(allMedicines.count))")
                } else {
                    hasMoreMedicines = true
                    print("✅ Loaded \(newMedicines.count) medicines (total: \(allMedicines.count), more available)")
                }
            }
            
        } catch {
            print("❌ Error loading more medicines: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoadingMore = false
    }
    
    private func getLastValue(from medicines: [Medicine]) -> Any? {
        guard let last = medicines.last else { return nil }
        
        switch currentSortField {
        case .name:
            return last.name
        case .stock:
            return last.stock
        case .aisle:
            return last.aisle
        }
    }
    
    func changeSortOrder(to field: MedicineSortField, order: MedicineSortOrder = .ascending) async {
        currentSortField = field
        currentSortOrder = order
        
        // Reload with new sort order
        lastLoadedValue = nil
        hasMoreMedicines = true
        
        await loadInitialMedicines()
        
        print("✅ Sorted by \(field.rawValue)")
    }
    
    func searchMedicines(query: String) async {
        guard !query.isEmpty else {
            // Return to normal view - reload initial medicines
            lastLoadedValue = nil
            hasMoreMedicines = true
            await loadInitialMedicines()
            return
        }
        
        do {
            let medicines = try await medicineService.searchMedicines(
                query: query,
                limit: 50, // More results for search
                sortBy: currentSortField
            )
            
            allMedicines = medicines
            hasMoreMedicines = false
            
            print("🔍 Found \(medicines.count) medicines matching '\(query)'")
            
        } catch {
            print("❌ Search error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func loadHistory(for medicineId: String) {
        medicineService.startHistoryListener(for: medicineId) { [weak self] entries in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let newEntries = Array(entries.prefix(20))
                if newEntries.count != self.currentHistory.count {
                    self.currentHistory = newEntries
                    print("📜 History updated: \(newEntries.count) entries")
                }
            }
        }
    }
    
    func stopHistoryListener() {
        let count = currentHistory.count
        medicineService.stopHistoryListener()
        currentHistory.removeAll()
        print("🛑 History listener stopped - cleared \(count) entries")
    }
    
    func addMedicine(name: String, stock: Int, aisle: Int, user: String) async {
        do {
            let medicine = Medicine(name: name, stock: stock, aisle: aisle)
            try await medicineService.addMedicine(medicine)
            
            let entry = HistoryEntry(
                medicineId: medicine.id ?? "",
                user: user,
                action: "Added \(name)",
                details: "Initial stock: \(stock) in Aisle \(aisle)"
            )
            try await medicineService.addHistoryEntry(entry)
            
            print("✅ Medicine added successfully")
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateStock(medicineId: String, change: Int, user: String) async {
        guard let medicine = medicine(withId: medicineId) else { return }
        
        let newStock = max(0, medicine.stock + change)
        
        do {
            try await medicineService.updateStock(
                medicineId: medicineId,
                newStock: newStock
            )
            
            // Update local array immediately
            if let index = allMedicines.firstIndex(where: { $0.id == medicineId }) {
                allMedicines[index].stock = newStock
            }
            
            let action = change > 0 ?
                "Added \(change) to \(medicine.name)" :
                "Removed \(abs(change)) from \(medicine.name)"
            
            let entry = HistoryEntry(
                medicineId: medicineId,
                user: user,
                action: action,
                details: "Stock: \(medicine.stock) → \(newStock)"
            )
            try await medicineService.addHistoryEntry(entry)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateMedicine(_ medicine: Medicine, user: String) async {
        guard medicine.id != nil else { return }
        
        do {
            try await medicineService.updateMedicine(medicine)
            
            // Update local array immediately
            if let index = allMedicines.firstIndex(where: { $0.id == medicine.id }) {
                allMedicines[index] = medicine
            }
            
            let entry = HistoryEntry(
                medicineId: medicine.id!,
                user: user,
                action: "Updated \(medicine.name)",
                details: "Modified medicine details"
            )
            try await medicineService.addHistoryEntry(entry)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteMedicine(id: String, name: String, user: String) async {
        do {
            try await medicineService.deleteMedicine(id: id)
            
            // Remove from local array immediately
            allMedicines.removeAll { $0.id == id }
            
            let entry = HistoryEntry(
                medicineId: id,
                user: user,
                action: "Deleted \(name)",
                details: "Removed from inventory"
            )
            try await medicineService.addHistoryEntry(entry)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopMedicinesListener() {
        medicineService.stopMedicinesListener()
    }
    
    func cleanup() {
        print("🧹 Starting cleanup")
        
        medicineService.stopMedicinesListener()
        medicineService.stopHistoryListener()
        medicineService.stopAllListeners()
        
        allMedicines = []
        currentHistory = []
        
        lastLoadedValue = nil
        hasMoreMedicines = true
        isLoadingMore = false
        
        appState = .initializing
        hasInitialized = false
        errorMessage = nil
        
        print("🧹 Cleanup complete")
    }
    
    deinit {
        medicineService.stopAllListeners()
        print("🧹 deinit")
    }
}
