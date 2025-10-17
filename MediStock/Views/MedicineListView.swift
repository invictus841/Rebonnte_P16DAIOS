import SwiftUI

struct MedicineListView: View {
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let aisle: Int
    
    // Computed property that always gets fresh data from viewModel
    var medicines: [Medicine] {
        viewModel.medicinesForAisle(aisle)
    }

    var body: some View {
        Group {
            if medicines.isEmpty {
                EmptyStateView(
                    systemName: "pills",
                    title: "No Medicines",
                    message: "No medicines in Aisle \(aisle) yet",
                    actionTitle: "Add Medicine",
                    action: {}
                )
            } else {
                List {
                    ForEach(medicines, id: \.id) { medicine in
                        NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                            MedicineRow(medicine: medicine)
                        }
                    }
                    .onDelete { indexSet in
                        deleteMedicines(at: indexSet)
                    }
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("\(medicines.count) medicine\(medicines.count == 1 ? "" : "s") in Aisle \(aisle)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Aisle \(aisle)")
        .navigationBarItems(trailing: NavigationLink(destination: AddMedicineView()) {
            Image(systemName: "plus")
                .foregroundColor(.primaryAccent)
        })
    }
    
    private func deleteMedicines(at offsets: IndexSet) {
        for index in offsets {
            let medicine = medicines[index]
            guard let id = medicine.id else { continue }
            
            Task {
                await viewModel.deleteMedicine(
                    id: id,
                    name: medicine.name,
                    user: authViewModel.userEmail
                )
            }
        }
    }
}

struct MedicineListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MedicineListView(aisle: 1)
                .environmentObject(AuthViewModel())
                .environmentObject(MedicineStockViewModel())
        }
    }
}
