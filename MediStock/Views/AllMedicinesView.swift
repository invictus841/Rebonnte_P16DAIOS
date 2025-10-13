import SwiftUI

struct AllMedicinesView: View {
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var sortBy: SortOption = .name
    
    // ✅ NEW: Search debouncing
    @State private var searchTask: Task<Void, Never>?
    
    enum SortOption {
        case name, stock, aisle
    }
    
    // ✅ OPTIMIZED: Filter and sort medicines (locally for now, but much smaller dataset)
    var filteredMedicines: [Medicine] {
        var medicines = viewModel.allMedicines
        
        // ✅ Note: searchText filtering happens server-side now via searchMedicines()
        // This is just for local sorting
        
        // Sort
        switch sortBy {
        case .name:
            medicines.sort { $0.name < $1.name }
        case .stock:
            medicines.sort { $0.stock < $1.stock }
        case .aisle:
            // Extract numbers from "Aisle X" and sort numerically
            medicines.sort { med1, med2 in
                let num1 = extractAisleNumber(from: med1.aisle)
                let num2 = extractAisleNumber(from: med2.aisle)
                return num1 < num2
            }
        }
        
        return medicines
    }
    
    // Helper function to extract aisle number
    private func extractAisleNumber(from aisle: String) -> Int {
        // Extract number from "Aisle X" format
        let numberString = aisle.replacingOccurrences(of: "Aisle ", with: "")
        return Int(numberString) ?? 0
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ✅ IMPROVED: Search Bar with debouncing
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search medicines...", text: $searchText)
                        .onChange(of: searchText) { oldValue, newValue in
                            // ✅ Debounce search (wait 300ms after user stops typing)
                            searchTask?.cancel()
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                guard !Task.isCancelled else { return }
                                await performSearch(query: newValue)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            Task {
                                await performSearch(query: "")
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Sort Controls
                HStack {
                    Text("Sort:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Menu {
                        Button("Sort by Name") { sortBy = .name }
                        Button("Sort by Stock") { sortBy = .stock }
                        Button("Sort by Aisle") { sortBy = .aisle }
                    } label: {
                        HStack {
                            Text(sortByLabel)
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.primaryAccent)
                    }
                    
                    Spacer()
                    
                    // ✅ Show loading indicator when loading more
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Medicines List
                List {
                    if viewModel.allMedicines.isEmpty {
                        EmptyStateView(
                            systemName: "pills",
                            title: searchText.isEmpty ? "No Medicines" : "No Results",
                            message: searchText.isEmpty ?
                                "Start by adding your first medicine" :
                                "No medicines found matching '\(searchText)'",
                            actionTitle: searchText.isEmpty ? "Add Medicine" : nil,
                            action: searchText.isEmpty ? {} : nil
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredMedicines, id: \.id) { medicine in
                            NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(medicine.name)
                                            .font(.headline)
                                        Text(medicine.aisle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Stock badge
                                    HStack(spacing: 4) {
                                        if medicine.stock == 0 {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        } else if medicine.stock < 10 {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        Text("\(medicine.stock)")
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.semibold)
                                            .foregroundColor(stockColor(medicine.stock))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(stockColor(medicine.stock).opacity(0.15))
                                    )
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            deleteMedicines(at: indexSet, from: filteredMedicines)
                        }
                        
                        // ✅ FIXED: Load More Button - Only show when hasMoreMedicines is true!
                        if viewModel.hasMoreMedicines && searchText.isEmpty && !viewModel.isLoadingMore {
                            Button(action: {
                                Task {
                                    await viewModel.loadMoreMedicines()
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.down.circle")
                                    Text("Load More Medicines")
                                    Spacer()
                                }
                                .foregroundColor(.primaryAccent)
                                .padding()
                            }
                            .listRowBackground(Color.clear)
                        }
                        
                        // ✅ Loading indicator (shown while loading)
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
                        
                        // ✅ "All loaded" message - Only show when NO more medicines
                        if !viewModel.hasMoreMedicines && !viewModel.allMedicines.isEmpty && searchText.isEmpty {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                Text("All medicines loaded")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // ✅ IMPROVED: Status Bar with better info
                if !viewModel.allMedicines.isEmpty {
                    HStack {
                        Text("Showing \(filteredMedicines.count) medicine\(filteredMedicines.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if viewModel.hasMoreMedicines && searchText.isEmpty {
                            Text("• More available")
                                .font(.caption)
                                .foregroundColor(.primaryAccent)
                        } else if !viewModel.hasMoreMedicines && searchText.isEmpty && viewModel.allMedicines.count > 20 {
                            Text("• All loaded (\(viewModel.allMedicines.count) total)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }
            }
            .navigationTitle("All Medicines")
            .navigationBarItems(trailing: NavigationLink(destination: AddMedicineView()) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundColor(.primaryAccent)
            })
        }
    }
    
    // ✅ NEW: Perform server-side search
    private func performSearch(query: String) async {
        await viewModel.searchMedicines(query: query)
    }
    
    private var sortByLabel: String {
        switch viewModel.currentSortField {
        case .name: return "Name"
        case .stock: return "Stock"
        case .aisle: return "Aisle"
        }
    }
    
    private func stockColor(_ stock: Int) -> Color {
        if stock == 0 { return .red }
        if stock < 10 { return .orange }
        return .green
    }
    
    private func deleteMedicines(at offsets: IndexSet, from medicines: [Medicine]) {
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

struct AllMedicinesView_Previews: PreviewProvider {
    static var previews: some View {
        AllMedicinesView()
            .environmentObject(AuthViewModel())
            .environmentObject(MedicineStockViewModel())
    }
}
