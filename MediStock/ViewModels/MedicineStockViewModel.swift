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
    
    @Published private var fullMedicinesList: [Medicine] = []
    
    @Published var searchQuery: String = ""
    @Published var displayLimit: Int = 5
    @Published var errorMessage: String?
    @Published var isLoadingMore = false
    @Published var currentSortField: MedicineSortField = .name
    @Published var currentSortOrder: MedicineSortOrder = .ascending
    
    private let medicineService: MedicineServiceProtocol
    private var hasInitialized = false
    
    var allMedicines: [Medicine] {
        let filtered: [Medicine]
        
        if searchQuery.isEmpty {
            filtered = fullMedicinesList
        } else {
            filtered = fullMedicinesList.filter {
                $0.name.lowercased().contains(searchQuery.lowercased())
            }
        }
        
        return Array(filtered.prefix(displayLimit))
    }
    
    var hasMoreMedicines: Bool {
        let filtered: [Medicine]
        
        if searchQuery.isEmpty {
            filtered = fullMedicinesList
        } else {
            filtered = fullMedicinesList.filter {
                $0.name.lowercased().contains(searchQuery.lowercased())
            }
        }
        
        return filtered.count > displayLimit
    }
    
    var aisles: [Int] {
        let uniqueAisles = Set(fullMedicinesList.map { $0.aisle })
        return Array(uniqueAisles).sorted()
    }
    
    func medicinesForAisle(_ aisle: Int) -> [Medicine] {
        fullMedicinesList.filter { $0.aisle == aisle }
    }
    
    func medicine(withId id: String) -> Medicine? {
        fullMedicinesList.first { $0.id == id }
    }
    
    init(medicineService: MedicineServiceProtocol = FirebaseMedicineService()) {
        self.medicineService = medicineService
    }
    
    func initializeApp() async {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        appState = .loading
        loadingProgress = 0.5
        
        startRealtimeListener()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        if appState == .loading {
            loadingProgress = 1.0
            appState = .ready
            print("✅ App initialized with real-time listener")
        }
    }

    private func startRealtimeListener() {
        medicineService.startMedicinesListener(
            onSuccess: { [weak self] medicines in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.fullMedicinesList = self.sortMedicines(medicines)
                    print("🔄 Real-time update: \(medicines.count) total medicines")
                }
            },
            onError: { [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.appState = .error(error.localizedDescription)
                    print("❌ Listener error: \(error.localizedDescription)")
                }
            }
        )
    }
    
    func loadMoreMedicines() async {
        guard !isLoadingMore else {
            print("⚠️ Already loading")
            return
        }
        
        guard hasMoreMedicines else {
            print("⚠️ No more medicines to show")
            return
        }
        
        isLoadingMore = true
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        displayLimit += 5
        
        isLoadingMore = false
        
        print("📄 Now showing \(allMedicines.count) medicines")
    }
    
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
    
    func changeSortOrder(to field: MedicineSortField, order: MedicineSortOrder = .ascending) async {
        currentSortField = field
        currentSortOrder = order
        
        fullMedicinesList = sortMedicines(fullMedicinesList)
        
        print("✅ Sorted by \(field.rawValue)")
    }
    
    // MARK: - Search
    
    func searchMedicines(query: String) async {
        searchQuery = query
        displayLimit = 5
        
        if query.isEmpty {
            medicineService.stopMedicinesListener()
            startRealtimeListener()
            print("🔍 Search cleared - reloading all")
        } else {
            do {
                let results = try await medicineService.searchMedicines(
                    query: query,
                    limit: 20,
                    sortBy: currentSortField
                )
                fullMedicinesList = results
                print("🔍 Found \(results.count) medicines via Firebase")
            } catch {
                print("❌ Search error: \(error)")
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    func addMedicine(name: String, stock: Int, aisle: Int, user: String) async {
        do {
            let medicine = Medicine(name: name, stock: stock, aisle: aisle)
            let savedMedicine = try await medicineService.addMedicine(medicine)
            
            let entry = HistoryEntry(
                medicineId: savedMedicine.id ?? "",
                user: user,
                action: "Added \(name)",
                details: "Initial stock: \(stock) in Aisle \(aisle)"
            )
            try await medicineService.addHistoryEntry(entry)
            
            fullMedicinesList.append(savedMedicine)
            fullMedicinesList = sortMedicines(fullMedicinesList)
            
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
            
            if let index = fullMedicinesList.firstIndex(where: { $0.id == medicineId }) {
                fullMedicinesList[index].stock = newStock
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
            
            if let index = fullMedicinesList.firstIndex(where: { $0.id == medicine.id }) {
                fullMedicinesList[index] = medicine
                fullMedicinesList = sortMedicines(fullMedicinesList)
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
            
            fullMedicinesList.removeAll { $0.id == id }
            
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
        medicineService.stopAllListeners()
        
        fullMedicinesList = []
        searchQuery = ""
        displayLimit = 5
        
        appState = .initializing
        hasInitialized = false
        errorMessage = nil
        
        print("🧹 Cleanup complete")
    }
    
    deinit {
        medicineService.stopAllListeners()
        print("🧹 ViewModel deinitialized")
    }
}
