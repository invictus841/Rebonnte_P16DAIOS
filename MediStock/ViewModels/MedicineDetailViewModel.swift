//
//  MedicineDetailViewModel.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 17/10/2025.
//

import Foundation

@MainActor
class MedicineDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var history: [HistoryEntry] = []
    @Published var isLoading = false
    
    // MARK: - Private Properties
    
    private let medicineService: MedicineServiceProtocol
    private var medicineId: String = ""
    
    // MARK: - Initialization
    
    init(medicineService: MedicineServiceProtocol = FirebaseMedicineService()) {
        self.medicineService = medicineService
        print("✅ MedicineDetailViewModel initialized")
    }
    
    // MARK: - Public Methods
    
    func loadHistory(for medicineId: String) {
        self.medicineId = medicineId
        isLoading = true
        
        medicineService.startHistoryListener(for: medicineId) { [weak self] entries in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let limitedEntries = Array(entries.prefix(20))
                self.history = limitedEntries
                self.isLoading = false
                
                print("📜 History loaded: \(limitedEntries.count) entries for medicine \(medicineId)")
            }
        }
    }
    
    func cleanup() {
        print("🧹 Starting detail ViewModel cleanup")
        
        medicineService.stopHistoryListener()
        history.removeAll()
        isLoading = false
        
        print("🧹 Detail ViewModel cleanup complete")
    }
    
    // MARK: - Deinitialization
    
    deinit {
        medicineService.stopHistoryListener()
        print("🧹 MedicineDetailViewModel deinitialized - memory freed!")
    }
}
