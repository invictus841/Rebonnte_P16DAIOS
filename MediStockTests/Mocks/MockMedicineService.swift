//
//  MockMedicineService.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 13/10/2025.
//

import Foundation
@testable import MediStock

class MockMedicineService: MedicineServiceProtocol {
    // Test data
    var medicines: [Medicine] = []
    var historyEntries: [HistoryEntry] = []
    
    // Control test behavior
    var shouldThrowError = false
    var loadDelay: UInt64 = 0
    
    // Track method calls
    var loadMedicinesCallCount = 0
    var addMedicineCallCount = 0
    var updateMedicineCallCount = 0
    var deleteMedicineCallCount = 0
    var updateStockCallCount = 0
    var addHistoryCallCount = 0
    
    // Listeners
    var medicinesListener: (([Medicine]) -> Void)?
    var historyListener: (([HistoryEntry]) -> Void)?
    
    // Initialize with test data
    init() {
        setupTestData()
    }
    
    private func setupTestData() {
        medicines = [
            Medicine(id: "1", name: "Aspirin", stock: 25, aisle: 1),
            Medicine(id: "2", name: "Paracetamol", stock: 10, aisle: 1),
            Medicine(id: "3", name: "Ibuprofen", stock: 0, aisle: 2),
            Medicine(id: "4", name: "Amoxicillin", stock: 5, aisle: 2),
            Medicine(id: "5", name: "Vitamin C", stock: 100, aisle: 3)
        ]
    }
    
    // MARK: - Load Methods (kept for compatibility but less used now)
    
    func loadMedicines(limit: Int, startAfter: Any?, sortBy: MedicineSortField, order: MedicineSortOrder) async throws -> [Medicine] {
        loadMedicinesCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.notAuthenticated
        }
        
        // Simple pagination simulation
        let sorted = medicines.sorted { med1, med2 in
            switch sortBy {
            case .name:
                return order == .ascending ? med1.name < med2.name : med1.name > med2.name
            case .stock:
                return order == .ascending ? med1.stock < med2.stock : med1.stock > med2.stock
            case .aisle:
                return order == .ascending ? med1.aisle < med2.aisle : med1.aisle > med2.aisle
            }
        }
        
        let startIndex = startAfter != nil ? min(limit, sorted.count) : 0
        let endIndex = min(startIndex + limit, sorted.count)
        
        return Array(sorted[startIndex..<endIndex])
    }
    
    func loadMedicines(forAisle aisle: String, limit: Int, sortBy: MedicineSortField) async throws -> [Medicine] {
        if shouldThrowError {
            throw MedicineServiceError.notAuthenticated
        }
        
        let aisleNumber = Int(aisle.replacingOccurrences(of: "Aisle ", with: "")) ?? 0
        return medicines.filter { $0.aisle == aisleNumber }.prefix(limit).map { $0 }
    }
    
    func searchMedicines(query: String, limit: Int, sortBy: MedicineSortField) async throws -> [Medicine] {
        if shouldThrowError {
            throw MedicineServiceError.notAuthenticated
        }
        
        let filtered = medicines.filter {
            $0.name.lowercased().contains(query.lowercased())
        }
        
        let sorted = filtered.sorted { med1, med2 in
            switch sortBy {
            case .name:
                return med1.name < med2.name
            case .stock:
                return med1.stock < med2.stock
            case .aisle:
                return med1.aisle < med2.aisle
            }
        }
        
        return Array(sorted.prefix(limit))
    }
    
    // MARK: - Real-time Listeners (PRIMARY for new approach)
    
    func startMedicinesListener(completion: @escaping ([Medicine]) -> Void) {
        medicinesListener = completion
        // Immediately send current medicines
        completion(medicines)
        print("🧪 Mock listener started with \(medicines.count) medicines")
    }
    
    func stopMedicinesListener() {
        medicinesListener = nil
        print("🧪 Mock listener stopped")
    }
    
    func startHistoryListener(for medicineId: String, completion: @escaping ([HistoryEntry]) -> Void) {
        historyListener = completion
        let filtered = historyEntries.filter { $0.medicineId == medicineId }
        completion(filtered)
    }
    
    func stopHistoryListener() {
        historyListener = nil
    }
    
    // MARK: - CRUD Operations
    
    func addMedicine(_ medicine: Medicine) async throws -> Medicine {  // 🆕 Returns Medicine
        addMedicineCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.invalidData
        }
        
        var newMedicine = medicine
        newMedicine.id = UUID().uuidString
        medicines.append(newMedicine)
        
        // Notify listener if active
        medicinesListener?(medicines)
        
        print("🧪 Mock: Added medicine - total now: \(medicines.count)")
        
        return newMedicine  // 🆕 Return the created medicine
    }
    
    func updateMedicine(_ medicine: Medicine) async throws {
        updateMedicineCallCount += 1
        
        guard let id = medicine.id else {
            throw MedicineServiceError.invalidData
        }
        
        if shouldThrowError {
            throw MedicineServiceError.unknown("Update failed")
        }
        
        if let index = medicines.firstIndex(where: { $0.id == id }) {
            medicines[index] = medicine
            medicinesListener?(medicines)
            print("🧪 Mock: Updated medicine")
        }
    }
    
    func deleteMedicine(id: String) async throws {
        deleteMedicineCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.unknown("Delete failed")
        }
        
        medicines.removeAll { $0.id == id }
        medicinesListener?(medicines)
        print("🧪 Mock: Deleted medicine - total now: \(medicines.count)")
    }
    
    func updateStock(medicineId: String, newStock: Int) async throws {
        updateStockCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.unknown("Stock update failed")
        }
        
        if let index = medicines.firstIndex(where: { $0.id == medicineId }) {
            medicines[index].stock = newStock
            medicinesListener?(medicines)
            print("🧪 Mock: Updated stock to \(newStock)")
        }
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        addHistoryCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.unknown("History add failed")
        }
        
        var newEntry = entry
        newEntry.id = UUID().uuidString
        historyEntries.append(newEntry)
        
        // Notify history listener if watching this medicine
        let filtered = historyEntries.filter { $0.medicineId == entry.medicineId }
        historyListener?(filtered)
    }
    
    // MARK: - Cleanup
    
    func stopAllListeners() {
        medicinesListener = nil
        historyListener = nil
        print("🧪 Mock: All listeners stopped")
    }
    
    // MARK: - Test Helper Methods
    
    func reset() {
        setupTestData()
        historyEntries = []
        shouldThrowError = false
        loadDelay = 0
        loadMedicinesCallCount = 0
        addMedicineCallCount = 0
        updateMedicineCallCount = 0
        deleteMedicineCallCount = 0
        updateStockCallCount = 0
        addHistoryCallCount = 0
        medicinesListener = nil
        historyListener = nil
    }
    
    func addTestHistory(for medicineId: String, count: Int) {
        for i in 0..<count {
            historyEntries.append(
                HistoryEntry(
                    id: "history-\(i)",
                    medicineId: medicineId,
                    user: "test@example.com",
                    action: "Test action \(i)",
                    details: "Test details \(i)",
                    timestamp: Date().addingTimeInterval(TimeInterval(-i * 3600))
                )
            )
        }
    }
    
    // Helper to simulate another user adding a medicine
    func simulateRemoteAdd(_ medicine: Medicine) {
        var newMedicine = medicine
        newMedicine.id = UUID().uuidString
        medicines.append(newMedicine)
        
        // Trigger listener as if Firebase sent an update
        medicinesListener?(medicines)
        print("🧪 Mock: Simulated remote add - \(newMedicine.name)")
    }
    
    // Helper to simulate another user updating stock
    func simulateRemoteStockUpdate(medicineId: String, newStock: Int) {
        if let index = medicines.firstIndex(where: { $0.id == medicineId }) {
            medicines[index].stock = newStock
            medicinesListener?(medicines)
            print("🧪 Mock: Simulated remote stock update")
        }
    }
}
