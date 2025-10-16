//
//  MedicineService.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 04/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Sort Options

enum MedicineSortField: String {
    case name
    case stock
    case aisle
}

enum MedicineSortOrder {
    case ascending
    case descending
}

protocol MedicineServiceProtocol {
    // Initial load
//    func loadAllMedicines() async throws -> [Medicine]
    
    // Paginated loading with sorting
    func loadMedicines(limit: Int, startAfter: Any?, sortBy: MedicineSortField, order: MedicineSortOrder) async throws -> [Medicine]
    
    //Filtered queries with sorting
    func loadMedicines(forAisle aisle: String, limit: Int, sortBy: MedicineSortField) async throws -> [Medicine]
    func searchMedicines(query: String, limit: Int, sortBy: MedicineSortField) async throws -> [Medicine]
//    func getMedicineCount(forAisle aisle: String?) async throws -> Int
    
    // Real-time listener
    func startMedicinesListener(completion: @escaping ([Medicine]) -> Void)
    func stopMedicinesListener()
    
    //Filtered listener for specific aisle
//    func startMedicinesListener(forAisle aisle: String, completion: @escaping ([Medicine]) -> Void)
    
    // History
    func startHistoryListener(for medicineId: String, completion: @escaping ([HistoryEntry]) -> Void)
    func stopHistoryListener()
    
    // CRUD
    func addMedicine(_ medicine: Medicine) async throws
    func updateMedicine(_ medicine: Medicine) async throws
    func deleteMedicine(id: String) async throws
    func updateStock(medicineId: String, newStock: Int) async throws
    
    // History logging
    func addHistoryEntry(_ entry: HistoryEntry) async throws
    
    // Cleanup
    func stopAllListeners()
}

class FirebaseMedicineService: MedicineServiceProtocol {
    
    private let db = Firestore.firestore()
    private var medicinesListener: ListenerRegistration?
    private var historyListener: ListenerRegistration?
    
    func loadAllMedicines() async throws -> [Medicine] {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        let snapshot = try await db.collection("medicines")
            .order(by: "name")
            .getDocuments()
        
        let medicines = snapshot.documents.compactMap { document in
            try? document.data(as: Medicine.self)
        }
        
        return medicines
    }
    
    func loadMedicines(limit: Int, startAfter: Any?, sortBy: MedicineSortField, order: MedicineSortOrder) async throws -> [Medicine] {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        var query = db.collection("medicines")
            .order(by: sortBy.rawValue, descending: order == .descending)
            .limit(to: limit)
        
        if let startAfterValue = startAfter {
            query = query.start(after: [startAfterValue])
        }
        
        let snapshot = try await query.getDocuments()
        
        let medicines = snapshot.documents.compactMap { document in
            try? document.data(as: Medicine.self)
        }
        
        print("📦 Loaded \(medicines.count) medicines (limit: \(limit), sorted by \(sortBy.rawValue))")
        return medicines
    }
    
    func loadMedicines(forAisle aisle: String, limit: Int, sortBy: MedicineSortField) async throws -> [Medicine] {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        let snapshot = try await db.collection("medicines")
            .whereField("aisle", isEqualTo: aisle)
            .order(by: sortBy.rawValue)
            .limit(to: limit)
            .getDocuments()
        
        let medicines = snapshot.documents.compactMap { document in
            try? document.data(as: Medicine.self)
        }
        
        print("📦 Loaded \(medicines.count) medicines for \(aisle) (sorted by \(sortBy.rawValue))")
        return medicines
    }
    
    func searchMedicines(query: String, limit: Int, sortBy: MedicineSortField) async throws -> [Medicine] {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        let queryUpper = query + "\u{f8ff}"
        
        let snapshot = try await db.collection("medicines")
            .order(by: sortBy.rawValue)
            .whereField(sortBy.rawValue, isGreaterThanOrEqualTo: query)
            .whereField(sortBy.rawValue, isLessThan: queryUpper)
            .limit(to: limit)
            .getDocuments()
        
        let medicines = snapshot.documents.compactMap { document in
            try? document.data(as: Medicine.self)
        }
        
        print("🔍 Found \(medicines.count) medicines matching '\(query)' (sorted by \(sortBy.rawValue))")
        return medicines
    }
    
    func getMedicineCount(forAisle aisle: String?) async throws -> Int {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        let query: Query
        
        if let aisle = aisle {
            query = db.collection("medicines")
                .whereField("aisle", isEqualTo: aisle)
        } else {
            query = db.collection("medicines")
        }
        
        let snapshot = try await query.count.getAggregation(source: .server)
        return Int(truncating: snapshot.count)
    }
    
    func startMedicinesListener(completion: @escaping ([Medicine]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion([])
            return
        }
        
        medicinesListener?.remove()
        medicinesListener = nil
        
        medicinesListener = db.collection("medicines")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard self != nil else { return }
                
                if let error = error {
                    print("❌ Listener error: \(error)")
                    completion([])
                    return
                }
                
                let medicines = snapshot?.documents.compactMap {
                    try? $0.data(as: Medicine.self)
                } ?? []
                
                completion(medicines)
            }
    }
    
    func startMedicinesListener(forAisle aisle: String, completion: @escaping ([Medicine]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion([])
            return
        }
        
        medicinesListener?.remove()
        medicinesListener = nil
        
        medicinesListener = db.collection("medicines")
            .whereField("aisle", isEqualTo: aisle)
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard self != nil else { return }
                
                if let error = error {
                    print("❌ Listener error: \(error)")
                    completion([])
                    return
                }
                
                let medicines = snapshot?.documents.compactMap {
                    try? $0.data(as: Medicine.self)
                } ?? []
                
                completion(medicines)
            }
    }
    
    func stopMedicinesListener() {
        medicinesListener?.remove()
        medicinesListener = nil
    }
    
    func startHistoryListener(for medicineId: String, completion: @escaping ([HistoryEntry]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion([])
            return
        }
        
        historyListener?.remove()
        historyListener = nil
        
        historyListener = db.collection("history")
            .whereField("medicineId", isEqualTo: medicineId)
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, error in
                guard self != nil else { return }
                
                let entries = snapshot?.documents.compactMap {
                    try? $0.data(as: HistoryEntry.self)
                } ?? []
                
                completion(entries)
            }
    }
    
    func stopHistoryListener() {
        historyListener?.remove()
        historyListener = nil
    }
    
    func addMedicine(_ medicine: Medicine) async throws {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        let docRef = db.collection("medicines").document()
        var newMedicine = medicine
        newMedicine.id = docRef.documentID
        
        try docRef.setData(from: newMedicine)
    }
    
    func updateMedicine(_ medicine: Medicine) async throws {
        guard let id = medicine.id else {
            throw MedicineServiceError.invalidData
        }
        
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        try db.collection("medicines")
            .document(id)
            .setData(from: medicine)
    }
    
    func deleteMedicine(id: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        try await db.collection("medicines")
            .document(id)
            .delete()
    }
    
    func updateStock(medicineId: String, newStock: Int) async throws {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        try await db.collection("medicines")
            .document(medicineId)
            .updateData(["stock": newStock])
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        let docRef = db.collection("history").document()
        var newEntry = entry
        newEntry.id = docRef.documentID
        
        try docRef.setData(from: newEntry)
    }
    
    func stopAllListeners() {
        medicinesListener?.remove()
        historyListener?.remove()
        medicinesListener = nil
        historyListener = nil
    }
    
    deinit {
        medicinesListener?.remove()
        historyListener?.remove()
        print("✅ FirebaseMedicineService deallocated")
    }
}

enum MedicineServiceError: LocalizedError {
    case notAuthenticated
    case invalidData
    case firestoreError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidData:
            return "Invalid data received"
        case .firestoreError(let message):
            return "Database error: \(message)"
        case .unknown(let message):
            return message
        }
    }
}
