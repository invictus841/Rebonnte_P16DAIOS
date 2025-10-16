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
    
//    @Published var displayLimit = 20
    private let pageSize = 20
    
    private let medicineService: MedicineServiceProtocol
    private var hasInitialized = false
    
    var aisles: [String] {
        let uniqueAisles = Set(allMedicines.map { $0.aisle })
        return Array(uniqueAisles).sorted()
    }
    
//    var displayedMedicines: [Medicine] {
//        Array(allMedicines.prefix(displayLimit))
//    }
    
//    var hasMoreToShow: Bool {
//        if displayLimit < allMedicines.count {
//            return true
//        }
//        return hasMoreMedicines
//    }
    
    func medicinesForAisle(_ aisle: String) -> [Medicine] {
        allMedicines.filter { $0.aisle == aisle }
    }
    
    func medicine(withId id: String) -> Medicine? {
        allMedicines.first { $0.id == id }
    }
    
    init(medicineService: MedicineServiceProtocol = FirebaseMedicineService()) {
        self.medicineService = medicineService
    }
    
    func initializeApp() async {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        appState = .loading
        loadingProgress = 0.1
        
        await loadInitialMedicines()
    }
    
    private func loadInitialMedicines() async {
        loadingProgress = 0.3
        
        do {
            let medicines = try await medicineService.loadMedicines(
                limit: pageSize,
                startAfter: nil,
                sortBy: currentSortField,
                order: currentSortOrder
            )
            
            loadingProgress = 0.6
            
            allMedicines = medicines
            lastLoadedValue = getLastValue(from: medicines)
            hasMoreMedicines = medicines.count == pageSize
            
            loadingProgress = 0.9
            
            print("✅ Loaded \(medicines.count) medicines (initial page, sorted by \(currentSortField.rawValue))")
            
//            startRealTimeUpdates()
            
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            loadingProgress = 1.0
            appState = .ready
            
        } catch {
            print("❌ Error loading medicines: \(error)")
            appState = .error(error.localizedDescription)
        }
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
    
    func changeSortOrder(to field: MedicineSortField, order: MedicineSortOrder = .ascending) async {
        currentSortField = field
        currentSortOrder = order
        
        medicineService.stopMedicinesListener()
        
        do {
            let medicines = try await medicineService.loadMedicines(
                limit: pageSize,
                startAfter: nil,
                sortBy: field,
                order: order
            )
            
            // If sorting by aisle, sort numerically instead of alphabetically
            if field == .aisle {
                let sorted = medicines.sorted { med1, med2 in
                    let num1 = Int(med1.aisle.replacingOccurrences(of: "Aisle ", with: "")) ?? 0
                    let num2 = Int(med2.aisle.replacingOccurrences(of: "Aisle ", with: "")) ?? 0
                    return order == .ascending ? num1 < num2 : num1 > num2
                }
                allMedicines = sorted
            } else {
                allMedicines = medicines
            }
            
            lastLoadedValue = getLastValue(from: medicines)
            hasMoreMedicines = medicines.count == pageSize
            
            print("✅ Sorted by \(field.rawValue): loaded \(medicines.count) medicines")
            
        } catch {
            print("❌ Error sorting: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func searchMedicines(query: String) async {
        guard !query.isEmpty else {
            // Return to normal paginated view
            await changeSortOrder(to: currentSortField, order: currentSortOrder)
            return
        }
        
        medicineService.stopMedicinesListener()
        
        do {
            let medicines = try await medicineService.searchMedicines(
                query: query,
                limit: pageSize,
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
    
//    func showMore() {
//        if displayLimit < allMedicines.count {
//            displayLimit = min(displayLimit + 20, allMedicines.count)
//        } else {
//            Task {
//                await loadMoreMedicines()
//            }
//        }
//    }
    
//    func setDisplayLimit(_ limit: Int) {
//        displayLimit = limit
//    }
    
    func addMedicine(name: String, stock: Int, aisle: String, user: String) async {
        let medicine = Medicine(name: name, stock: stock, aisle: aisle)
        
        do {
            try await medicineService.addMedicine(medicine)
            
            let entry = HistoryEntry(
                medicineId: medicine.id ?? "",
                user: user,
                action: "Added \(name)",
                details: "Initial stock: \(stock) in \(aisle)"
            )
            try await medicineService.addHistoryEntry(entry)
            
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
//        displayLimit = 20
        errorMessage = nil
        
        print("🧹 Cleanup complete")
    }
    
    deinit {
        medicineService.stopAllListeners()
        print("🧹 deiniit")
    }
}
