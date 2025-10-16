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
            Medicine(id: "1", name: "Aspirin", stock: 25, aisle: "Aisle 1"),
            Medicine(id: "2", name: "Paracetamol", stock: 10, aisle: "Aisle 1"),
            Medicine(id: "3", name: "Ibuprofen", stock: 0, aisle: "Aisle 2"),
            Medicine(id: "4", name: "Amoxicillin", stock: 5, aisle: "Aisle 2"),
            Medicine(id: "5", name: "Vitamin C", stock: 100, aisle: "Aisle 3")
        ]
    }
    
    // Load all medicines
    func loadAllMedicines() async throws -> [Medicine] {
        if shouldThrowError {
            throw MedicineServiceError.notAuthenticated
        }
        
        if loadDelay > 0 {
            try? await Task.sleep(nanoseconds: loadDelay)
        }
        
        return medicines
    }
    
    // Load medicines with pagination
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
    
    // Load medicines for specific aisle
    func loadMedicines(forAisle aisle: String, limit: Int, sortBy: MedicineSortField) async throws -> [Medicine] {
        if shouldThrowError {
            throw MedicineServiceError.notAuthenticated
        }
        
        return medicines.filter { $0.aisle == aisle }.prefix(limit).map { $0 }
    }
    
    // Search medicines
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
                let num1 = Int(med1.aisle.replacingOccurrences(of: "Aisle ", with: "")) ?? 0
                let num2 = Int(med2.aisle.replacingOccurrences(of: "Aisle ", with: "")) ?? 0
                return num1 < num2
            }
        }
        
        return Array(sorted.prefix(limit))
    }
    
    // Get medicine count
    func getMedicineCount(forAisle aisle: String?) async throws -> Int {
        if shouldThrowError {
            throw MedicineServiceError.notAuthenticated
        }
        
        if let aisle = aisle {
            return medicines.filter { $0.aisle == aisle }.count
        }
        return medicines.count
    }
    
    // Start medicines listener
    func startMedicinesListener(completion: @escaping ([Medicine]) -> Void) {
        medicinesListener = completion
        completion(medicines)
    }
    
    // Start medicines listener for aisle
    func startMedicinesListener(forAisle aisle: String, completion: @escaping ([Medicine]) -> Void) {
        medicinesListener = completion
        let filtered = medicines.filter { $0.aisle == aisle }
        completion(filtered)
    }
    
    // Stop medicines listener
    func stopMedicinesListener() {
        medicinesListener = nil
    }
    
    // Start history listener
    func startHistoryListener(for medicineId: String, completion: @escaping ([HistoryEntry]) -> Void) {
        historyListener = completion
        let filtered = historyEntries.filter { $0.medicineId == medicineId }
        completion(filtered)
    }
    
    // Stop history listener
    func stopHistoryListener() {
        historyListener = nil
    }
    
    // Add medicine
    func addMedicine(_ medicine: Medicine) async throws {
        addMedicineCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.invalidData
        }
        
        var newMedicine = medicine
        newMedicine.id = UUID().uuidString
        medicines.append(newMedicine)
        
        // Notify listener
        medicinesListener?(medicines)
    }
    
    // Update medicine
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
        }
    }
    
    // Delete medicine
    func deleteMedicine(id: String) async throws {
        deleteMedicineCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.unknown("Delete failed")
        }
        
        medicines.removeAll { $0.id == id }
        medicinesListener?(medicines)
    }
    
    // Update stock
    func updateStock(medicineId: String, newStock: Int) async throws {
        updateStockCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.unknown("Stock update failed")
        }
        
        if let index = medicines.firstIndex(where: { $0.id == medicineId }) {
            medicines[index].stock = newStock
            medicinesListener?(medicines)
        }
    }
    
    // Add history entry
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        addHistoryCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.unknown("History add failed")
        }
        
        var newEntry = entry
        newEntry.id = UUID().uuidString
        historyEntries.append(newEntry)
        
        if entry.medicineId == historyListener.map({ _ in entry.medicineId }) ?? "" {
            historyListener?(historyEntries.filter { $0.medicineId == entry.medicineId })
        }
    }
    
    // Stop all listeners
    func stopAllListeners() {
        medicinesListener = nil
        historyListener = nil
    }
    
    // Test helper methods
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
}
