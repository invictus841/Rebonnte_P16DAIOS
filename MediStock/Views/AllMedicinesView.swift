import SwiftUI

struct AllMedicinesView: View {
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var sortBy: SortOption = .name
    
    enum SortOption {
        case name, stock, aisle
    }
    
    // Filter and sort medicines
    var filteredMedicines: [Medicine] {
            // Start with ALL medicines for sorting and searching
            var medicines = viewModel.allMedicines
            
            // Search filter
            if !searchText.isEmpty {
                medicines = medicines.filter {
                    $0.name.localizedCaseInsensitiveContains(searchText)
                }
            }
            
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
        
        // Apply display limit AFTER sorting (only when not searching)
        if searchText.isEmpty && viewModel.displayLimit < medicines.count {
            medicines = Array(medicines.prefix(viewModel.displayLimit))
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
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search medicines...", text: $searchText)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Display Controls
                HStack {
                    Text("Show:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Display", selection: $viewModel.displayLimit) {
                        Text("10").tag(10)
                        Text("25").tag(25)
                        Text("50").tag(50)
                        Text("100").tag(100)
                        if viewModel.allMedicines.count > 100 {
                            Text("All").tag(viewModel.allMedicines.count)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 250)
                    
                    Spacer()
                    
                    Menu {
                        Button("Sort by Name") { sortBy = .name }
                        Button("Sort by Stock") { sortBy = .stock }
                        Button("Sort by Aisle") { sortBy = .aisle }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Medicines List
                List {
                    if viewModel.allMedicines.isEmpty {
                        EmptyStateView(
                            systemName: "pills",
                            title: "No Medicines",
                            message: "Start by adding your first medicine",
                            actionTitle: "Add Medicine",
                            action: {
                                // Will navigate via NavigationLink
                            }
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
                        
                        // Show More Button
                        if viewModel.hasMoreToShow && searchText.isEmpty {
                            Button(action: { viewModel.showMore() }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                    Text("Show More")
                                    Spacer()
                                }
                                .foregroundColor(.primaryAccent)
                                .padding()
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // Status Bar
                if !viewModel.allMedicines.isEmpty {
                    HStack {
                        Text("Showing \(filteredMedicines.count) of \(viewModel.allMedicines.count) medicines")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
