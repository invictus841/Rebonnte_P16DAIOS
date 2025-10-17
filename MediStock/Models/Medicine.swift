import Foundation
import FirebaseFirestore

struct Medicine: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var stock: Int
    var aisle: Int

    init(id: String? = nil, name: String, stock: Int, aisle: Int) {
        self.id = id
        self.name = name
        self.stock = stock
        self.aisle = aisle
    }

    static func == (lhs: Medicine, rhs: Medicine) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.stock == rhs.stock &&
               lhs.aisle == rhs.aisle
    }
}
