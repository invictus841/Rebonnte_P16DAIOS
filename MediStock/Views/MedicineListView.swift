import SwiftUI

struct MedicineListView: View {
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let aisle: String
    
    // Simply filter from the already-loaded medicines
    var medicines: [Medicine] {
        viewModel.medicinesForAisle(aisle)
    }

    var body: some View {
        Group {
            if medicines.isEmpty {
                EmptyStateView(
                    systemName: "pills",
                    title: "No Medicines",
                    message: "No medicines in \(aisle) yet",
                    actionTitle: "Add Medicine",
                    action: {
                        // This will be handled by NavigationLink
                    }
                )
            } else {
                List {
                    ForEach(medicines, id: \.id) { medicine in
                        NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(medicine.name)
                                        .font(.headline)
                                    
                                    HStack {
                                        Text("Stock: \(medicine.stock)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        if medicine.stock == 0 {
                                            Label("Out of Stock", systemImage: "exclamationmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        } else if medicine.stock < 10 {
                                            Label("Low Stock", systemImage: "exclamationmark.triangle.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                // Stock indicator
                                Circle()
                                    .fill(stockColor(medicine.stock))
                                    .frame(width: 10, height: 10)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        deleteMedicines(at: indexSet)
                    }
                    
                    // Footer
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("\(medicines.count) medicine\(medicines.count == 1 ? "" : "s") in \(aisle)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(aisle)
        .navigationBarItems(trailing: NavigationLink(destination: AddMedicineView()) {
            Image(systemName: "plus")
                .foregroundColor(.primaryAccent)
        })
    }
    
    private func stockColor(_ stock: Int) -> Color {
        if stock == 0 { return .red }
        if stock < 10 { return .orange }
        return .green
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
            MedicineListView(aisle: "Aisle 1")
                .environmentObject(AuthViewModel())
                .environmentObject(MedicineStockViewModel())
        }
    }
}
