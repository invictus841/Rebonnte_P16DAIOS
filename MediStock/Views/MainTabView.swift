import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var medicineViewModel: MedicineStockViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AisleListView()
                .tabItem {
                    Label("Aisles", systemImage: "rectangle.stack.fill")
                }
                .tag(0)
                .badge(medicineViewModel.aisles.count)

            AllMedicinesView()
                .tabItem {
                    Label("All Medicines", systemImage: "pills.fill")
                }
                .tag(1)
                .badge(stockStatusBadge)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
        .accentColor(.primaryAccent)
    }
    
    private var lowStockCount: Int {
        medicineViewModel.allMedicines.filter { $0.stock > 0 && $0.stock < 10 }.count
    }
    
    private var outOfStockCount: Int {
        medicineViewModel.allMedicines.filter { $0.stock == 0 }.count
    }
    
    private var stockStatusBadge: String? {
        let out = outOfStockCount
        let low = lowStockCount
        
        if out == 0 && low == 0 {
            return nil  // No badge if everything is fine
        }
        
        // Format with emojis: 🔴 for emergency (out of stock), ) 🟡 for warning (low stock)
        if out > 0 && low > 0 {
            return "\(out)🔴 \(low)🟡"
        } else if out > 0 {
            return "\(out)🟡"
        } else {
            return "\(low)🟡"
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
            .environmentObject(MedicineStockViewModel())
    }
}
