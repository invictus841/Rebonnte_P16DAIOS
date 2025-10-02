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

    func addRandomMedicine(user: String) {
        let medicine = Medicine(name: "Medicine \(Int.random(in: 1...100))", stock: Int.random(in: 1...100), aisle: "Aisle \(Int.random(in: 1...10))")
        do {
            try db.collection("medicines").document(medicine.id ?? UUID().uuidString).setData(from: medicine)
            addHistory(action: "Added \(medicine.name)", user: user, medicineId: medicine.id ?? "", details: "Added new medicine")
        } catch let error {
            print("Error adding document: \(error)")
        }
    }

    func deleteMedicines(at offsets: IndexSet) {
        offsets.map { medicines[$0] }.forEach { medicine in
            if let id = medicine.id {
                db.collection("medicines").document(id).delete { error in
                    if let error = error {
                        print("Error removing document: \(error)")
                    }
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
