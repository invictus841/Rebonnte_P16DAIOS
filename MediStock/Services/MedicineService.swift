//
//  MedicineService.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 04/10/2025.
//

import Foundation
import Firebase
import FirebaseFirestore

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
            return "Invalid data received from server"
        case .firestoreError(let message):
            return "Database error: \(message)"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Service Protocol

protocol MedicineServiceProtocol {
    /// Start listening to medicine changes
    func startMedicinesListener(completion: @escaping ([Medicine]) -> Void)
    
    /// Start listening to history changes for a specific medicine
    func startHistoryListener(for medicineId: String, completion: @escaping ([HistoryEntry]) -> Void)
    
    /// Stop all listeners
    func stopAllListeners()
    
    /// Add a new medicine
    func addMedicine(_ medicine: Medicine) async throws -> String
    
    /// Update an existing medicine
    func updateMedicine(_ medicine: Medicine) async throws
    
    /// Delete a medicine
    func deleteMedicine(id: String) async throws
    
    /// Update medicine stock
    func updateStock(medicineId: String, newStock: Int) async throws
    
    /// Add history entry
    func addHistoryEntry(_ entry: HistoryEntry) async throws
}

// MARK: - Firebase Implementation

class FirebaseMedicineService: MedicineServiceProtocol {
    private let db = Firestore.firestore()
    private var medicinesListener: ListenerRegistration?
    private var historyListener: ListenerRegistration?
    
    // MARK: - Listeners
    
    func startMedicinesListener(completion: @escaping ([Medicine]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            print("Not authenticated - skipping listener")
            return
        }
        
        // Remove old listener
        medicinesListener?.remove()
        
        medicinesListener = db.collection("medicines").addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening to medicines: \(error)")
                completion([])
                return
            }
            
            let medicines = querySnapshot?.documents.compactMap { document in
                try? document.data(as: Medicine.self)
            } ?? []
            
            completion(medicines)
        }
    }
    
    func startHistoryListener(for medicineId: String, completion: @escaping ([HistoryEntry]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            print("Not authenticated - skipping listener")
            return
        }
        
        // Remove old listener
        historyListener?.remove()
        
        historyListener = db.collection("history")
            .whereField("medicineId", isEqualTo: medicineId)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error listening to history: \(error)")
                    completion([])
                    return
                }
                
                let history = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: HistoryEntry.self)
                } ?? []
                
                completion(history)
            }
    }
    
    func stopAllListeners() {
        medicinesListener?.remove()
        medicinesListener = nil
        historyListener?.remove()
        historyListener = nil
    }
    
    // MARK: - CRUD Operations
    
    func addMedicine(_ medicine: Medicine) async throws -> String {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        // Generate a new document ID
        let docRef = db.collection("medicines").document()
        
        // Create medicine with the generated ID
        var newMedicine = medicine
        newMedicine.id = docRef.documentID
        
        do {
            try docRef.setData(from: newMedicine)
            return docRef.documentID
        } catch {
            throw MedicineServiceError.firestoreError(error.localizedDescription)
        }
    }
    
    func updateMedicine(_ medicine: Medicine) async throws {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        guard let id = medicine.id else {
            throw MedicineServiceError.invalidData
        }
        
        do {
            try db.collection("medicines").document(id).setData(from: medicine)
        } catch {
            throw MedicineServiceError.firestoreError(error.localizedDescription)
        }
    }
    
    func deleteMedicine(id: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        do {
            try await db.collection("medicines").document(id).delete()
        } catch {
            throw MedicineServiceError.firestoreError(error.localizedDescription)
        }
    }
    
    func updateStock(medicineId: String, newStock: Int) async throws {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        do {
            try await db.collection("medicines").document(medicineId).updateData([
                "stock": newStock
            ])
        } catch {
            throw MedicineServiceError.firestoreError(error.localizedDescription)
        }
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        let docId = entry.id ?? UUID().uuidString
        
        do {
            try db.collection("history").document(docId).setData(from: entry)
        } catch {
            throw MedicineServiceError.firestoreError(error.localizedDescription)
        }
    }
    
    deinit {
        stopAllListeners()
    }
}
