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

            AllMedicinesView()
                .tabItem {
                    Label("All Medicines", systemImage: "pills.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
        .accentColor(.primaryAccent)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
            .environmentObject(MedicineStockViewModel())
    }
}
