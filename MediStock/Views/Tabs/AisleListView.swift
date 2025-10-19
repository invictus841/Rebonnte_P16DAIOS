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
                                        .accessibilityHidden(true)
                                    
                                    Text("Aisle \(aisle)")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(viewModel.medicinesForAisle(aisle).count)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.primaryAccent)
                                        .clipShape(Capsule())
                                        .accessibilityLabel("\(viewModel.medicinesForAisle(aisle).count) medicines")
                                }
                                .padding(.vertical, 8)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Aisle \(aisle), \(viewModel.medicinesForAisle(aisle).count) medicines")
                            .accessibilityHint("Double tap to view medicines in this aisle")
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
            }
            .accessibilityLabel("Add new medicine")
            .accessibilityHint("Double tap to create a new medicine entry"))
        }
    }
}

struct AisleListView_Previews: PreviewProvider {
    static var previews: some View {
        AisleListView()
            .environmentObject(MedicineStockViewModel())
    }
}
