import SwiftUI

struct AisleListView: View {
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.aisles, id: \.self) { aisle in
                    NavigationLink(destination: MedicineListView(aisle: aisle)) {
                        HStack {
                            Image(systemName: "rectangle.stack.fill")
                                .foregroundColor(.primaryAccent)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(aisle)
                                    .font(.headline)
                                
                                Text("\(medicineCount(for: aisle)) medicines")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationBarTitle("Aisles")
        }
        .onAppear {
            viewModel.fetchAisles()
        }
    }
    
    // MARK: - Helper
    
    private func medicineCount(for aisle: String) -> Int {
        viewModel.medicines.filter { $0.aisle == aisle }.count
    }
}

struct AisleListView_Previews: PreviewProvider {
    static var previews: some View {
        AisleListView()
            .environmentObject(AuthViewModel())
            .environmentObject(MedicineStockViewModel())
    }
}
