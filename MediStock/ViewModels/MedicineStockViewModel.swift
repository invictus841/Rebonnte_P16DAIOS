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
    
    // UI Display Settings
    @Published var displayLimit = 10
    
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
        displayLimit < allMedicines.count
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
        
        await loadAllMedicines()
    }
    
    private func loadAllMedicines() async {
        loadingProgress = 0.3
        
        do {
            // Load initial data
            let medicines = try await medicineService.loadAllMedicines()
            
            loadingProgress = 0.6
            
            allMedicines = medicines
            loadingProgress = 0.9
            
            print("✅ Loaded \(medicines.count) medicines")
            
            // Start real-time listener for updates
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
    
    private func startRealTimeUpdates() {
        medicineService.startMedicinesListener { [weak self] medicines in
            guard let self = self else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Only update if we're ready (not during initial load)
                guard case .ready = self.appState else { return }
                self.allMedicines = medicines
            }
        }
    }
    
    // MARK: - History Management
    
    func loadHistory(for medicineId: String) {
        medicineService.startHistoryListener(for: medicineId) { [weak self] entries in
            Task { @MainActor in
                self?.currentHistory = entries
            }
        }
    }
    
    func stopHistoryListener() {
        medicineService.stopHistoryListener()
        currentHistory = []
    }
    
    // MARK: - Display Controls
    
    func showMore() {
        displayLimit = min(displayLimit + 10, allMedicines.count)
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
        
        // Reset state
        appState = .initializing
        hasInitialized = false
        displayLimit = 10
        errorMessage = nil
        
        print("🧹 Cleanup complete")
    }
    
    deinit {
        // Clean up listeners without calling @MainActor methods
        medicineService.stopAllListeners()
    }
}
