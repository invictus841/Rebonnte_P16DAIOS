import Foundation
import Firebase

class MedicineStockViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var aisles: [String] = []
    @Published var history: [HistoryEntry] = []
    private var db = Firestore.firestore()
    
    private var medicinesListener: ListenerRegistration?
    private var historyListener: ListenerRegistration?

    func fetchMedicines() {
        // Guard against fetching when not authenticated
        guard Auth.auth().currentUser != nil else {
            print("Not authenticated - skipping fetch")
            return
        }
        
        medicinesListener?.remove()
        
        medicinesListener = db.collection("medicines").addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            self.medicines = querySnapshot?.documents.compactMap { document in
                try? document.data(as: Medicine.self)
            } ?? []
        }
    }
    
    func fetchAisles() {
            // Guard against fetching when not authenticated
            guard Auth.auth().currentUser != nil else {
                print("Not authenticated - skipping fetch")
                return
            }
            
            medicinesListener?.remove()
            
        medicinesListener = db.collection("medicines").addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            let allMedicines = querySnapshot?.documents.compactMap { document in
                try? document.data(as: Medicine.self)
            } ?? []
            self.aisles = Array(Set(allMedicines.map { $0.aisle })).sorted()
            self.medicines = allMedicines
        }
    }
    
    func addMedicine(_ medicine: Medicine, user: String) async throws {
        // Generate a new document ID
        let docRef = db.collection("medicines").document()
        
        // Create medicine with the generated ID
        var newMedicine = medicine
        newMedicine.id = docRef.documentID
        
        // Save to Firebase
        try docRef.setData(from: newMedicine)
        
        // Add to history
        await MainActor.run {
            addHistory(
                action: "Added \(medicine.name)",
                user: user,
                medicineId: docRef.documentID,
                details: "Added new medicine with initial stock of \(medicine.stock) in \(medicine.aisle)"
            )
        }
    }

    func deleteMedicine(id: String, medicineName: String, user: String) {
        // Delete from Firebase
        db.collection("medicines").document(id).delete { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error deleting medicine: \(error)")
            } else {
                // Add to history
                self.addHistory(
                    action: "Deleted \(medicineName)",
                    user: user,
                    medicineId: id,
                    details: "Medicine removed from inventory"
                )
                
                // Remove from local array (snapshot listener will handle this, but for immediate UI update)
                if let index = self.medicines.firstIndex(where: { $0.id == id }) {
                    self.medicines.remove(at: index)
                }
            }
        }
    }

    func increaseStock(_ medicine: Medicine, user: String) {
        updateStock(medicine, by: 1, user: user)
    }

    func decreaseStock(_ medicine: Medicine, user: String) {
        updateStock(medicine, by: -1, user: user)
    }

    func updateStock(_ medicine: Medicine, by amount: Int, user: String) {
        guard let id = medicine.id else { return }
        let newStock = medicine.stock + amount
        db.collection("medicines").document(id).updateData([
            "stock": newStock
        ]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error updating stock: \(error)")
            } else {
                if let index = self.medicines.firstIndex(where: { $0.id == id }) {
                    self.medicines[index].stock = newStock
                }
                self.addHistory(action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(amount)", user: user, medicineId: id, details: "Stock changed from \(medicine.stock - amount) to \(newStock)")
            }
        }
    }

    func updateMedicine(_ medicine: Medicine, user: String) {
        guard let id = medicine.id else { return }
        do {
            try db.collection("medicines").document(id).setData(from: medicine)
            addHistory(action: "Updated \(medicine.name)", user: user, medicineId: id, details: "Updated medicine details")
        } catch let error {
            print("Error updating document: \(error)")
        }
    }

    private func addHistory(action: String, user: String, medicineId: String, details: String) {
        let history = HistoryEntry(medicineId: medicineId, user: user, action: action, details: details)
        do {
            try db.collection("history").document(history.id ?? UUID().uuidString).setData(from: history)
        } catch let error {
            print("Error adding history: \(error)")
        }
    }

    func fetchHistory(for medicine: Medicine) {
            guard let medicineId = medicine.id else { return }
            
            // Guard against fetching when not authenticated
            guard Auth.auth().currentUser != nil else {
                print("Not authenticated - skipping fetch")
                return
            }
            
            historyListener?.remove()
            
        historyListener = db.collection("history").whereField("medicineId", isEqualTo: medicineId).addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting history: \(error)")
                return
            }
            self.history = querySnapshot?.documents.compactMap { document in
                try? document.data(as: HistoryEntry.self)
            } ?? []
        }
    }
    
    func stopListening() {
        medicinesListener?.remove()
        historyListener?.remove()
        medicinesListener = nil
        historyListener = nil
        
        // Clear data
        medicines = []
        aisles = []
        history = []
    }
    
    deinit {
        stopListening()
    }
}
