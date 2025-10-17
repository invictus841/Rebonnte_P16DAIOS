import SwiftUI

struct AllMedicinesView: View {
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    
    var filteredMedicines: [Medicine] {
        return viewModel.allMedicines
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Sort Menu
                sortMenu
                
                // Medicines List
                medicinesList
                
                // Bottom Info Bar
                if !viewModel.allMedicines.isEmpty {
                    bottomInfoBar
                }
            }
            .navigationTitle("All Medicines")
            .navigationBarItems(trailing: addButton)
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search medicines...", text: $searchText)
                .onChange(of: searchText) { _, newValue in
                    performSearch(query: newValue)
                }
            
            if !searchText.isEmpty {
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: - Sort Menu
    private var sortMenu: some View {
        HStack {
            Text("Sort:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Menu {
                Button("Sort by Name") {
                    changeSort(to: .name)
                }
                Button("Sort by Stock") {
                    changeSort(to: .stock)
                }
                Button("Sort by Aisle") {
                    changeSort(to: .aisle)
                }
            } label: {
                HStack {
                    Text(sortLabel)
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.primaryAccent)
            }
            
            Spacer()
            
            if viewModel.isLoadingMore {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Medicines List
    private var medicinesList: some View {
        List {
            if viewModel.allMedicines.isEmpty {
                emptyState
            } else {
                medicinesRows
                loadMoreButton
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        EmptyStateView(
            systemName: "pills",
            title: searchText.isEmpty ? "No Medicines" : "No Results",
            message: searchText.isEmpty ?
                "Start by adding your first medicine" :
                "No medicines found matching '\(searchText)'"
        )
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Medicine Rows
    private var medicinesRows: some View {
        ForEach(filteredMedicines, id: \.id) { medicine in
            NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                MedicineRow(medicine: medicine)
            }
        }
        .onDelete(perform: deleteMedicines)
    }
    
    // MARK: - Load More Button
    private var loadMoreButton: some View {
        Group {
            if viewModel.hasMoreMedicines && searchText.isEmpty && !viewModel.isLoadingMore {
                Button(action: loadMore) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Load More Medicines")
                    }
                    .foregroundColor(.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .listRowBackground(Color.clear)
            }
            
            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .listRowBackground(Color.clear)
            }
            
            if !viewModel.hasMoreMedicines && !viewModel.allMedicines.isEmpty && searchText.isEmpty {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("All medicines loaded (\(viewModel.allMedicines.count) total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .listRowBackground(Color.clear)
            }
        }
    }
    
    // MARK: - Bottom Info Bar
    private var bottomInfoBar: some View {
        HStack {
            Text("Showing \(filteredMedicines.count) medicine\(filteredMedicines.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if viewModel.hasMoreMedicines && searchText.isEmpty {
                Text("• More available")
                    .font(.caption)
                    .foregroundColor(.primaryAccent)
            } else if !viewModel.hasMoreMedicines && searchText.isEmpty && !viewModel.allMedicines.isEmpty {
                Text("• All loaded")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Add Button
    private var addButton: some View {
        NavigationLink(destination: AddMedicineView()) {
            Image(systemName: "plus")
                .font(.title3)
                .foregroundColor(.primaryAccent)
        }
    }
    
    // MARK: - Helper Properties
    private var sortLabel: String {
        switch viewModel.currentSortField {
        case .name: return "Name"
        case .stock: return "Stock"
        case .aisle: return "Aisle"
        }
    }
    
    // MARK: - Actions
    private func performSearch(query: String) {
        Task {
            await viewModel.searchMedicines(query: query)
        }
    }
    
    private func clearSearch() {
        searchText = ""
        Task {
            await viewModel.searchMedicines(query: "")
        }
    }
    
    private func changeSort(to field: MedicineSortField) {
        Task {
            await viewModel.changeSortOrder(to: field)
        }
    }
    
    private func loadMore() {
        Task {
            await viewModel.loadMoreMedicines()
        }
    }
    
    private func deleteMedicines(at offsets: IndexSet) {
        for index in offsets {
            let medicine = filteredMedicines[index]
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

// MARK: - Preview
struct AllMedicinesView_Previews: PreviewProvider {
    static var previews: some View {
        AllMedicinesView()
            .environmentObject(AuthViewModel())
            .environmentObject(MedicineStockViewModel())
    }
}
