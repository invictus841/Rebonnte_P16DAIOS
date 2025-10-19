//
//  IntegrationTests.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 13/10/2025.
//

import XCTest
@testable import MediStock

@MainActor
class IntegrationTests: XCTestCase {
    
    var authViewModel: AuthViewModel!
    var medicineViewModel: MedicineStockViewModel!
    var mockAuthService: MockAuthService!
    var mockMedicineService: MockMedicineService!
    
    override func setUp() {
        super.setUp()
        
        mockAuthService = MockAuthService()
        mockMedicineService = MockMedicineService()
        
        authViewModel = AuthViewModel(authService: mockAuthService)
        medicineViewModel = MedicineStockViewModel(medicineService: mockMedicineService)
    }
    
    override func tearDown() {
        authViewModel = nil
        medicineViewModel = nil
        mockAuthService = nil
        mockMedicineService = nil
        super.tearDown()
    }
    
    // MARK: - Basic User Flow
    
    func test_basicUserFlow_loginAddMedicineLogout() async {
        let email = "user@test.com"
        let password = "password123"
        
        await authViewModel.signIn(email: email, password: password)
        
        XCTAssertTrue(authViewModel.isAuthenticated)
        
        await medicineViewModel.initializeApp()
        
        XCTAssertEqual(medicineViewModel.appState, .ready)
        XCTAssertFalse(medicineViewModel.allMedicines.isEmpty)
        
        await medicineViewModel.addMedicine(
            name: "New Medicine",
            stock: 100,
            aisle: 1,
            user: authViewModel.userEmail
        )
        
        XCTAssertEqual(mockMedicineService.addMedicineCallCount, 1)
        
        authViewModel.signOut()
        
        XCTAssertFalse(authViewModel.isAuthenticated)
        medicineViewModel.cleanup()
        XCTAssertTrue(medicineViewModel.allMedicines.isEmpty)
    }
    
    // MARK: - Search and Update Flow
    
    func test_searchAndUpdateMedicine() async {
        await authViewModel.signIn(email: "user@test.com", password: "password")
        await medicineViewModel.initializeApp()
        
        await medicineViewModel.searchMedicines(query: "Aspirin")
        
        XCTAssertEqual(medicineViewModel.allMedicines.count, 1)
        XCTAssertEqual(medicineViewModel.allMedicines.first?.name, "Aspirin")
        
        let medicine = medicineViewModel.allMedicines.first!
        await medicineViewModel.updateStock(
            medicineId: medicine.id!,
            change: 10,
            user: authViewModel.userEmail
        )
        
        XCTAssertEqual(mockMedicineService.updateStockCallCount, 1)
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 1)
    }
    
    // MARK: - Aisle Management
    
    func test_aisleFiltering() async {
        await authViewModel.signIn(email: "user@test.com", password: "password")
        await medicineViewModel.initializeApp()
        
        let aisles = medicineViewModel.aisles
        
        XCTAssertEqual(aisles.count, 3)
        
        let aisle1Medicines = medicineViewModel.medicinesForAisle(1)
        
        XCTAssertEqual(aisle1Medicines.count, 2)
    }
    
    // MARK: - Stock Levels
    
    func test_stockLevels() async {
        await authViewModel.signIn(email: "user@test.com", password: "password")
        await medicineViewModel.initializeApp()
        
        let outOfStock = medicineViewModel.allMedicines.filter { $0.stock == 0 }
        let lowStock = medicineViewModel.allMedicines.filter { $0.stock > 0 && $0.stock < 10 }
        
        XCTAssertEqual(outOfStock.count, 1)
        XCTAssertEqual(lowStock.count, 1)
    }
    
    // MARK: - Error Handling
    
    func test_errorHandling() async {
        mockAuthService.shouldSucceed = false
        
        await authViewModel.signIn(email: "wrong@test.com", password: "wrong")
        
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNotNil(authViewModel.errorMessage)
        
        mockAuthService.shouldSucceed = true
        authViewModel.clearError()
        
        await authViewModel.signIn(email: "test@test.com", password: "password")
        
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.errorMessage)
    }
}
