//
//  MedicineService.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 04/10/2025.
//

import Foundation
import FirebaseAuth
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
    /// Start listening to medicine changes with optional limit
    func startMedicinesListener(limit: Int, completion: @escaping ([Medicine]) -> Void)
    
    /// Start listening to ALL medicines (no limit) - for building aisles list
    func startAllMedicinesListener(completion: @escaping ([Medicine]) -> Void)
    
    /// Start listening to medicines for a specific aisle
    func startAisleMedicinesListener(aisle: String, completion: @escaping ([Medicine]) -> Void)
    
    /// Start listening to history changes for a specific medicine with optional limit
    func startHistoryListener(for medicineId: String, limit: Int, completion: @escaping ([HistoryEntry]) -> Void)
    
    /// Stop history listener only
    func stopHistoryListener()
    
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
    private var aisleListener: ListenerRegistration?
    
    // MARK: - Listeners
    
    func startMedicinesListener(limit: Int, completion: @escaping ([Medicine]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            print("Not authenticated - skipping listener")
            return
        }
        
        // Remove old listener
        medicinesListener?.remove()
        medicinesListener = nil
        
        medicinesListener = db.collection("medicines")
            .order(by: "name")  // Sort alphabetically for consistent ordering
            .limit(to: limit)    // Dynamic limit for lazy loading
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard self != nil else { return }
                
                if let error = error {
                    print("Error listening to medicines: \(error)")
                    completion([])
                    return
                }
                
                let medicines = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                } ?? []
                
                print("📊 Loaded \(medicines.count) medicines (limit: \(limit))")
                completion(medicines)
            }
    }
    
    func startAllMedicinesListener(completion: @escaping ([Medicine]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            print("Not authenticated - skipping listener")
            return
        }
        
        // Remove old listener
        medicinesListener?.remove()
        medicinesListener = nil
        
        // Load ALL medicines (no limit) to get complete aisles list
        medicinesListener = db.collection("medicines")
            .order(by: "name")  // Sort alphabetically
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard self != nil else { return }
                
                if let error = error {
                    print("Error listening to all medicines: \(error)")
                    completion([])
                    return
                }
                
                let medicines = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                } ?? []
                
                print("📊 Loaded ALL medicines: \(medicines.count) (for aisles list)")
                completion(medicines)
            }
    }
    
    func startAisleMedicinesListener(aisle: String, completion: @escaping ([Medicine]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            print("Not authenticated - skipping listener")
            return
        }
        
        // Remove old aisle listener
        aisleListener?.remove()
        aisleListener = nil
        
        aisleListener = db.collection("medicines")
            .whereField("aisle", isEqualTo: aisle)
            .order(by: "name")  // Sort alphabetically
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard self != nil else { return }
                
                if let error = error {
                    print("Error listening to aisle medicines: \(error)")
                    completion([])
                    return
                }
                
                let medicines = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                } ?? []
                
                print("📊 Loaded \(medicines.count) medicines for aisle '\(aisle)'")
                completion(medicines)
            }
    }
    
    func startHistoryListener(for medicineId: String, limit: Int, completion: @escaping ([HistoryEntry]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            print("Not authenticated - skipping listener")
            return
        }
        
        // Remove old listener
        stopHistoryListener()
        
        historyListener = db.collection("history")
            .whereField("medicineId", isEqualTo: medicineId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)  // Dynamic limit for lazy loading
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard self != nil else { return }
                
                if let error = error {
                    print("Error listening to history: \(error)")
                    completion([])
                    return
                }
                
                let history = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: HistoryEntry.self)
                } ?? []
                
                print("📊 Loaded \(history.count) history entries (limit: \(limit))")
                completion(history)
            }
    }
    
    func stopHistoryListener() {
        historyListener?.remove()
        historyListener = nil
    }
    
    func stopAllListeners() {
        medicinesListener?.remove()
        medicinesListener = nil
        
        aisleListener?.remove()
        aisleListener = nil
        
        historyListener?.remove()
        historyListener = nil
        
        print("All Firestore listeners stopped")
    }
    
    // MARK: - CRUD Operations
    
    func addMedicine(_ medicine: Medicine) async throws -> String {
        guard Auth.auth().currentUser != nil else {
            throw MedicineServiceError.notAuthenticated
        }
        
        let docRef = db.collection("medicines").document()
        
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
        print("FirebaseMedicineService deinitialized")
        stopAllListeners()
    }
}
