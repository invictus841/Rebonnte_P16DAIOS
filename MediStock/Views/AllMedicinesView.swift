import SwiftUI

struct AllMedicinesView: View {
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var filterText: String = ""
    @State private var sortOption: SortOption = .none

    var body: some View {
        NavigationView {
            VStack {
                // Filtrage et Tri
                HStack {
                    TextField("Filter by name", text: $filterText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 10)
                    
                    Spacer()

                    Picker("Sort by", selection: $sortOption) {
                        Text("None").tag(SortOption.none)
                        Text("Name").tag(SortOption.name)
                        Text("Stock").tag(SortOption.stock)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.trailing, 10)
                }
                .padding(.top, 10)
                
                // Liste des Médicaments
                List {
                    ForEach(filteredAndSortedMedicines, id: \.id) { medicine in
                        NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                            VStack(alignment: .leading) {
                                Text(medicine.name)
                                    .font(.headline)
                                Text("Stock: \(medicine.stock)")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .onDelete(perform: deleteMedicines)
                }
                .navigationBarTitle("All Medicines")
                .navigationBarItems(trailing: NavigationLink(destination: AddMedicineView()) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.primaryAccent)
                })
            }
        }
        .onAppear {
            viewModel.fetchMedicines()
        }
    }
    
    var filteredAndSortedMedicines: [Medicine] {
        var medicines = viewModel.medicines

        // Filtrage
        if !filterText.isEmpty {
            medicines = medicines.filter { $0.name.lowercased().contains(filterText.lowercased()) }
        }

        // Tri
        switch sortOption {
        case .name:
            medicines.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .stock:
            medicines.sort { $0.stock < $1.stock }
        case .none:
            break
        }

        return medicines
    }
    
    // MARK: - Delete Action
    
    private func deleteMedicines(at offsets: IndexSet) {
        let medicinesToDelete = offsets.map { filteredAndSortedMedicines[$0] }
        
        for medicine in medicinesToDelete {
            guard let id = medicine.id else { continue }
            
            viewModel.deleteMedicine(
                id: id,
                medicineName: medicine.name,
                user: authViewModel.userUID
            )
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case none
    case name
    case stock

    var id: String { self.rawValue }
}

struct AllMedicinesView_Previews: PreviewProvider {
    static var previews: some View {
        AllMedicinesView()
            .environmentObject(AuthViewModel())
            .environmentObject(MedicineStockViewModel())
    }
}
