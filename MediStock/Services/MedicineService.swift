//
//  MedicineService.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 04/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Service Protocol (No Firebase types here!)

protocol MedicineServiceProtocol {
    // Initial load
    func loadAllMedicines() async throws -> [Medicine]
    
    // Real-time listener
    func startMedicinesListener(completion: @escaping ([Medicine]) -> Void)
    func stopMedicinesListener()
    
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

// MARK: - Firebase Implementation (All Firebase code isolated here!)

class FirebaseMedicineService: MedicineServiceProtocol {
    
    private let db = Firestore.firestore()
    private var medicinesListener: ListenerRegistration?
    private var historyListener: ListenerRegistration?
    
    // MARK: - Initial Load
    
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
    
    // MARK: - Real-time Updates
    
    func startMedicinesListener(completion: @escaping ([Medicine]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion([])
            return
        }
        
        // CRITICAL: Remove any existing listener FIRST
        medicinesListener?.remove()
        medicinesListener = nil
        
        medicinesListener = db.collection("medicines")
            .order(by: "name")
            .addSnapshotListener { snapshot, error in
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
    
    // MARK: - History Management
    
    func startHistoryListener(for medicineId: String, completion: @escaping ([HistoryEntry]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion([])
            return
        }
        
        // CRITICAL: Remove any existing listener FIRST
        historyListener?.remove()
        historyListener = nil
        
        historyListener = db.collection("history")
            .whereField("medicineId", isEqualTo: medicineId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
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
    
    // MARK: - CRUD Operations
    
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
    
    // MARK: - Cleanup
    
    func stopAllListeners() {
           medicinesListener?.remove()
           historyListener?.remove()
           medicinesListener = nil
           historyListener = nil
       }
       
       deinit {
           // Ensure listeners are removed before deallocation
           medicinesListener?.remove()
           historyListener?.remove()
           print("✅ FirebaseMedicineService deallocated")
       }
}

// MARK: - Service Errors

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
