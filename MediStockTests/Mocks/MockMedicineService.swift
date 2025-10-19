//
//  MockMedicineService.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 13/10/2025.
//

import Foundation
@testable import MediStock

class MockMedicineService: MedicineServiceProtocol {
    var medicines: [Medicine] = []
    var historyEntries: [HistoryEntry] = []
    
    var shouldThrowError = false
    var loadDelay: UInt64 = 0
    
    var loadMedicinesCallCount = 0
    var addMedicineCallCount = 0
    var updateMedicineCallCount = 0
    var deleteMedicineCallCount = 0
    var updateStockCallCount = 0
    var addHistoryCallCount = 0
    
    var medicinesListener: (([Medicine]) -> Void)?
    var historyListener: (([HistoryEntry]) -> Void)?
    
    init() {
        setupTestData()
    }
    
    // MARK: - Setup
    
    private func setupTestData() {
        medicines = [
            Medicine(id: "1", name: "Aspirin", stock: 25, aisle: 1),
            Medicine(id: "2", name: "Paracetamol", stock: 10, aisle: 1),
            Medicine(id: "3", name: "Ibuprofen", stock: 0, aisle: 2),
            Medicine(id: "4", name: "Amoxicillin", stock: 5, aisle: 2),
            Medicine(id: "5", name: "Vitamin C", stock: 100, aisle: 3)
        ]
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
    
    // MARK: - Real-time Listeners
    
    func startMedicinesListener(
        onSuccess: @escaping ([Medicine]) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        if shouldThrowError {
            onError(MedicineServiceError.notAuthenticated)
            print("🧪 Mock listener simulating error")
        } else {
            medicinesListener = onSuccess
            onSuccess(medicines)
            print("🧪 Mock listener started with \(medicines.count) medicines")
        }
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
    
    func addMedicine(_ medicine: Medicine) async throws -> Medicine {
        addMedicineCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.invalidData
        }
        
        var newMedicine = medicine
        newMedicine.id = UUID().uuidString
        medicines.append(newMedicine)
        
        medicinesListener?(medicines)
        
        return newMedicine
    }
    
    func updateMedicine(_ medicine: Medicine) async throws {
        updateMedicineCallCount += 1
        
        guard medicine.id != nil else {
            throw MedicineServiceError.invalidData
        }
        
        if shouldThrowError {
            throw MedicineServiceError.unknown("Update failed")
        }
        
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
            medicinesListener?(medicines)
        }
    }
    
    func deleteMedicine(id: String) async throws {
        deleteMedicineCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.unknown("Delete failed")
        }
        
        medicines.removeAll { $0.id == id }
        medicinesListener?(medicines)
    }
    
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
    
    // MARK: - History Operations
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        addHistoryCallCount += 1
        
        if shouldThrowError {
            throw MedicineServiceError.notAuthenticated
        }
        
        historyEntries.append(entry)
        
        let filtered = historyEntries.filter { $0.medicineId == entry.medicineId }
        historyListener?(filtered)
    }
    
    // MARK: - Cleanup
    
    func stopAllListeners() {
        medicinesListener = nil
        historyListener = nil
    }
}
