import SwiftUI

struct AisleListView: View {
    @EnvironmentObject var viewModel: MedicineStockViewModel

    var body: some View {
        NavigationView {
            Group {
                if viewModel.aisles.isEmpty {
                    EmptyStateView(
                        systemName: "square.stack",
                        title: "No Aisles Yet",
                        message: "Aisles will appear here once you add medicines",
                        actionTitle: nil,
                        action: nil
                    )
                } else {
                    List {
                        ForEach(viewModel.aisles, id: \.self) { aisle in
                            NavigationLink(destination: MedicineListView(aisle: aisle)) {
                                HStack {
                                    Image(systemName: "rectangle.stack.fill")
                                        .foregroundColor(.primaryAccent)
                                        .frame(width: 30)
                                    
                                    Text(aisle)
                                        .font(.headline)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text("\(viewModel.aisles.count) aisle\(viewModel.aisles.count == 1 ? "" : "s") in total")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Aisles")
            .navigationBarItems(trailing: NavigationLink(destination: AddMedicineView()) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundColor(.primaryAccent)
            })
        }
    }
}

struct AisleListView_Previews: PreviewProvider {
    static var previews: some View {
        AisleListView()
            .environmentObject(MedicineStockViewModel())
    }
}
