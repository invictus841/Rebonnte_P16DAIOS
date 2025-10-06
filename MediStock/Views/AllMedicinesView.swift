import SwiftUI

struct AllMedicinesView: View {
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var filterText: String = ""
    @State private var sortOption: SortOption = .none

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter and Sort Controls
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
                .padding(.bottom, 8)
                
                // Page Size Selector
                HStack {
                    Text("Show per page:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Page Size", selection: $viewModel.medicinesPageSize) {
                        Text("5").tag(5)
                        Text("10").tag(10)
                        Text("20").tag(20)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 200)
                    .onChange(of: viewModel.medicinesPageSize) { _, _ in
                        // Reset and refetch with new page size
                        viewModel.medicinesLimit = viewModel.medicinesPageSize
                        viewModel.fetchMedicines()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
                
                // Medicine List
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
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    .onDelete(perform: deleteMedicines)
                    
                    // Load More Button
                    if shouldShowLoadMore {
                        VStack(spacing: 12) {
                            SecondaryButton("Load More (\(viewModel.medicinesPageSize) more)") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.loadMoreMedicines()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    
                    // Info Footer
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("Showing \(viewModel.medicines.count) medicine\(viewModel.medicines.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
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
            // Only fetch if medicines array is empty to avoid redundant calls
            if viewModel.medicines.isEmpty {
                viewModel.fetchMedicines()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var filteredAndSortedMedicines: [Medicine] {
        var medicines = viewModel.medicines

        // Filtering
        if !filterText.isEmpty {
            medicines = medicines.filter { $0.name.lowercased().contains(filterText.lowercased()) }
        }

        // Sorting
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
    
    var shouldShowLoadMore: Bool {
        // Show button if we have exactly the limit (might be more to load)
        // AND we're not filtering (load more doesn't work with filters)
        filterText.isEmpty && viewModel.medicines.count == viewModel.medicinesLimit
    }
    
    // MARK: - Delete Action
    
    private func deleteMedicines(at offsets: IndexSet) {
        let medicinesToDelete = offsets.map { filteredAndSortedMedicines[$0] }
        
        for medicine in medicinesToDelete {
            guard let id = medicine.id else { continue }
            
            viewModel.deleteMedicine(
                id: id,
                medicineName: medicine.name,
                user: authViewModel.userEmail
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
