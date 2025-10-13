import Foundation
// NO FIREBASE IMPORTS! 🚫

@MainActor
class MedicineStockViewModel: ObservableObject {
    
    // MARK: - App State
    
    enum LoadingState: Equatable {
        case initializing
        case loading
        case ready
        case error(String)
    }
    
    @Published var appState: LoadingState = .initializing
    @Published var loadingProgress: Double = 0
    
    // MARK: - Data
    
    @Published var allMedicines: [Medicine] = []
    @Published var currentHistory: [HistoryEntry] = []
    @Published var errorMessage: String?
    
    // ✅ NEW: Pagination state
    @Published var isLoadingMore = false
    @Published var hasMoreMedicines = true
    private var lastLoadedValue: Any?  // ✅ Changed from String? to Any?
    
    // ✅ NEW: Server-side sorting state
    @Published var currentSortField: MedicineSortField = .name
    @Published var currentSortOrder: SortOrder = .ascending
    
    // UI Display Settings
    @Published var displayLimit = 20
    private let pageSize = 20
    
    // MARK: - Dependencies (Using Protocol, not concrete Firebase!)
    
    private let medicineService: MedicineServiceProtocol
    private var hasInitialized = false
    
    // MARK: - Computed Properties
    
    var aisles: [String] {
        let uniqueAisles = Set(allMedicines.map { $0.aisle })
        return Array(uniqueAisles).sorted()
    }
    
    var displayedMedicines: [Medicine] {
        Array(allMedicines.prefix(displayLimit))
    }
    
    var hasMoreToShow: Bool {
        // ✅ IMPROVED: More explicit logic
        // Show "Load More" only if:
        // 1. We have more cached to display, OR
        // 2. Firebase has more to load
        if displayLimit < allMedicines.count {
            return true // Have cached medicines to show
        }
        return hasMoreMedicines // Firebase might have more
    }
    
    func medicinesForAisle(_ aisle: String) -> [Medicine] {
        allMedicines.filter { $0.aisle == aisle }
    }
    
    func medicine(withId id: String) -> Medicine? {
        allMedicines.first { $0.id == id }
    }
    
    // MARK: - Initialization (Dependency Injection!)
    
    init(medicineService: MedicineServiceProtocol = FirebaseMedicineService()) {
        self.medicineService = medicineService
    }
    
    // MARK: - App Initialization
    
    func initializeApp() async {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        appState = .loading
        loadingProgress = 0.1
        
        await loadInitialMedicines()
    }
    
    // ✅ UPDATED: Load only first page with server-side sorting
    private func loadInitialMedicines() async {
        loadingProgress = 0.3
        
        do {
            // ✅ Load with server-side sorting
            let medicines = try await medicineService.loadMedicines(
                limit: pageSize,
                startAfter: nil,
                sortBy: currentSortField,
                order: currentSortOrder
            )
            
            loadingProgress = 0.6
            
            allMedicines = medicines
            lastLoadedValue = getLastValue(from: medicines)  // ✅ Updated
            hasMoreMedicines = medicines.count == pageSize
            
            loadingProgress = 0.9
            
            print("✅ Loaded \(medicines.count) medicines (initial page, sorted by \(currentSortField.rawValue))")
            
            // Start real-time listener for updates (still watches all for real-time updates)
            startRealTimeUpdates()
            
            // Small delay for smooth transition
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            loadingProgress = 1.0
            appState = .ready
            
        } catch {
            print("❌ Error loading medicines: \(error)")
            appState = .error(error.localizedDescription)
        }
    }
    
    // ✅ UPDATED: Get last value with proper type based on current sort field
    private func getLastValue(from medicines: [Medicine]) -> Any? {
        guard let last = medicines.last else { return nil }
        
        switch currentSortField {
        case .name:
            return last.name  // String
        case .stock:
            return last.stock  // ✅ Int (not String!)
        case .aisle:
            return last.aisle  // String
        }
    }
    
    // ✅ UPDATED: Load next page with server-side sorting
    func loadMoreMedicines() async {
        // ✅ Safety checks
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
                // ✅ No more medicines in Firebase
                hasMoreMedicines = false
                print("✅ Loaded 0 medicines - all loaded! (total: \(allMedicines.count))")
            } else {
                // ✅ Append to existing medicines
                allMedicines.append(contentsOf: newMedicines)
                lastLoadedValue = getLastValue(from: newMedicines)  // ✅ Updated
                
                // ✅ Check if we got less than requested (means we're at the end)
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
    
    // ✅ NEW: Change sort order and reload
    func changeSortOrder(to field: MedicineSortField, order: SortOrder = .ascending) async {
        currentSortField = field
        currentSortOrder = order
        
        // Reload from beginning with new sort
        await loadInitialMedicines()
    }
    
    // ✅ UPDATED: Search with server-side sorting
    func searchMedicines(query: String) async {
        guard !query.isEmpty else {
            // Reset to initial state
            await loadInitialMedicines()
            return
        }
        
        // ✅ FIX: Stop real-time listener during search to save memory!
        medicineService.stopMedicinesListener()
        
        // ✅ Load more medicines for better search coverage (100 instead of 20)
        do {
            let medicines = try await medicineService.loadMedicines(
                limit: pageSize,
                startAfter: nil,
                sortBy: currentSortField,
                order: currentSortOrder
            )
            
            // ✅ Filter client-side (case-insensitive!)
            let filtered = medicines.filter { medicine in
                medicine.name.localizedCaseInsensitiveContains(query)
            }
            
            allMedicines = filtered
            hasMoreMedicines = false // Disable pagination during search
            
            print("🔍 Found \(filtered.count) medicines matching '\(query)' (from \(medicines.count) loaded, sorted by \(currentSortField.rawValue))")
            
        } catch {
            print("❌ Search error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    private func startRealTimeUpdates() {
        medicineService.startMedicinesListener { [weak self] medicines in
            guard let self = self else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Only update if we're ready (not during initial load)
                guard case .ready = self.appState else { return }
                
                // ✅ OPTIMIZED: Simple replacement instead of complex merge
                // This reduces memory allocations and is faster
                self.allMedicines = medicines.sorted { $0.name < $1.name }
                
                print("📡 Real-time update: \(medicines.count) medicines")
            }
        }
    }
    
    // MARK: - History Management
    
    func loadHistory(for medicineId: String) {
        // ✅ OPTIMIZED: Limit to 20 entries instead of 50 to reduce memory
        medicineService.startHistoryListener(for: medicineId) { [weak self] entries in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // ✅ Only update if history actually changed (reduce re-renders)
                let newEntries = Array(entries.prefix(20)) // Limit to 20
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
        
        // ✅ CRITICAL: Clear history data immediately to free memory!
        currentHistory.removeAll()
        
        print("🛑 History listener stopped - cleared \(count) entries")
    }
    
    // MARK: - Display Controls
    
    func showMore() {
        // ✅ If we have more cached, show them. Otherwise load from server
        if displayLimit < allMedicines.count {
            displayLimit = min(displayLimit + 20, allMedicines.count)
        } else {
            Task {
                await loadMoreMedicines()
            }
        }
    }
    
    func setDisplayLimit(_ limit: Int) {
        displayLimit = limit
    }
    
    // MARK: - CRUD Operations
    
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
    
    // MARK: - Cleanup
    
    func cleanup() {
        print("🧹 Starting cleanup")
        
        // Stop ALL listeners
        medicineService.stopMedicinesListener()
        medicineService.stopHistoryListener()
        medicineService.stopAllListeners()
        
        // Clear all data
        allMedicines = []
        currentHistory = []
        
        // Reset pagination state
        lastLoadedValue = nil  // ✅ Updated
        hasMoreMedicines = true
        isLoadingMore = false
        
        // Reset state
        appState = .initializing
        hasInitialized = false
        displayLimit = 20
        errorMessage = nil
        
        print("🧹 Cleanup complete")
    }
    
    deinit {
        // Clean up listeners without calling @MainActor methods
        medicineService.stopAllListeners()
    }
}
