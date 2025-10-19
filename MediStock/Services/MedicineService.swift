//
//  MedicineService.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 04/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

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

    func searchMedicines(query: String, limit: Int, sortBy: MedicineSortField) async throws -> [Medicine]
    
    func startMedicinesListener(completion: @escaping ([Medicine]) -> Void)
    func stopMedicinesListener()
    
    func startHistoryListener(for medicineId: String, completion: @escaping ([HistoryEntry]) -> Void)
    func stopHistoryListener()
    
    func addMedicine(_ medicine: Medicine) async throws -> Medicine
    func updateMedicine(_ medicine: Medicine) async throws
    func deleteMedicine(id: String) async throws
    func updateStock(medicineId: String, newStock: Int) async throws
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws
    
    func stopAllListeners()
}

class FirebaseMedicineService: MedicineServiceProtocol {
    
    private let db = Firestore.firestore()
    private var medicinesListener: ListenerRegistration?
    private var historyListener: ListenerRegistration?
    
    func searchMedicines(query: String, limit: Int, sortBy: MedicineSortField) async throws -> [Medicine] {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        let queryUpper = query + "\u{f8ff}"
        
        let snapshot = try await db.collection("medicines")
            .whereField("name", isGreaterThanOrEqualTo: query)
            .whereField("name", isLessThan: queryUpper)
            .order(by: sortBy.rawValue, descending: false)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Medicine.self) }
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
    
    func addMedicine(_ medicine: Medicine) async throws -> Medicine {
            guard Auth.auth().currentUser != nil else {
                throw MedicineServiceError.notAuthenticated
            }
            
            let docRef = db.collection("medicines").document()
            var newMedicine = medicine
            newMedicine.id = docRef.documentID
            
            try docRef.setData(from: newMedicine)
            
            return newMedicine
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
