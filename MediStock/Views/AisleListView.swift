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
                            
                            Text(aisle)
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Info Footer
                if !viewModel.aisles.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("\(viewModel.aisles.count) aisle\(viewModel.aisles.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationBarTitle("Aisles")
        }
        .onAppear {
            // Fetch aisles list (loads all medicines to extract unique aisles)
            viewModel.fetchAisles()
        }
    }
}

struct AisleListView_Previews: PreviewProvider {
    static var previews: some View {
        AisleListView()
            .environmentObject(AuthViewModel())
            .environmentObject(MedicineStockViewModel())
    }
}
