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
    
    // These are fine as properties for integration tests
    var authViewModel: AuthViewModel!
    var medicineViewModel: MedicineStockViewModel!
    var mockAuthService: MockAuthService!
    var mockMedicineService: MockMedicineService!
    
    override func setUp() {
        super.setUp()
        
        // Setup mocks
        mockAuthService = MockAuthService()
        mockMedicineService = MockMedicineService()
        
        // Setup view models
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
    
    // MARK: - Basic User Flow (SIMPLIFIED)
    
    func test_basicUserFlow_loginAddMedicineLogout() async {
        // Given - User credentials
        let email = "user@test.com"
        let password = "password123"
        
        // When - User logs in
        await authViewModel.signIn(email: email, password: password)
        
        // Then - User is authenticated
        XCTAssertTrue(authViewModel.isAuthenticated)
        
        // When - App initializes
        await medicineViewModel.initializeApp()
        
        // Then - Medicines are loaded
        XCTAssertEqual(medicineViewModel.appState, .ready)
        XCTAssertFalse(medicineViewModel.allMedicines.isEmpty)
        
        // When - User adds a medicine
        await medicineViewModel.addMedicine(
            name: "New Medicine",
            stock: 100,
            aisle: "Aisle 1",
            user: authViewModel.userEmail
        )
        
        // Then - Medicine is added
        XCTAssertEqual(mockMedicineService.addMedicineCallCount, 1)
        
        // When - User logs out
        authViewModel.signOut()
        
        // Then - User is logged out and data is cleared
        XCTAssertFalse(authViewModel.isAuthenticated)
        medicineViewModel.cleanup()
        XCTAssertTrue(medicineViewModel.allMedicines.isEmpty)
    }
    
    // MARK: - Search and Update Flow (SIMPLIFIED)
    
    func test_searchAndUpdateMedicine() async {
        // Given - User is logged in and app is ready
        await authViewModel.signIn(email: "user@test.com", password: "password")
        await medicineViewModel.initializeApp()
        
        // When - User searches for Aspirin
        await medicineViewModel.searchMedicines(query: "Aspirin")
        
        // Then - Only Aspirin is found
        XCTAssertEqual(medicineViewModel.allMedicines.count, 1)
        XCTAssertEqual(medicineViewModel.allMedicines.first?.name, "Aspirin")
        
        // When - User updates stock
        let medicine = medicineViewModel.allMedicines.first!
        await medicineViewModel.updateStock(
            medicineId: medicine.id!,
            change: 10,
            user: authViewModel.userEmail
        )
        
        // Then - Stock is updated and history is recorded
        XCTAssertEqual(mockMedicineService.updateStockCallCount, 1)
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 1)
    }
    
    // MARK: - Aisle Management (SIMPLIFIED)
    
    func test_aisleFiltering() async {
        // Given - User is logged in and app is ready
        await authViewModel.signIn(email: "user@test.com", password: "password")
        await medicineViewModel.initializeApp()
        
        // When - Getting aisles
        let aisles = medicineViewModel.aisles
        
        // Then - Should have 3 aisles
        XCTAssertEqual(aisles.count, 3)
        
        // When - Filtering by Aisle 1
        let aisle1Medicines = medicineViewModel.medicinesForAisle("Aisle 1")
        
        // Then - Should have 2 medicines in Aisle 1
        XCTAssertEqual(aisle1Medicines.count, 2)
    }
    
    // MARK: - Stock Levels (SIMPLIFIED)
    
    func test_stockLevels() async {
        // Given - User is logged in and app is ready
        await authViewModel.signIn(email: "user@test.com", password: "password")
        await medicineViewModel.initializeApp()
        
        // When - Checking stock levels
        let outOfStock = medicineViewModel.allMedicines.filter { $0.stock == 0 }
        let lowStock = medicineViewModel.allMedicines.filter { $0.stock > 0 && $0.stock < 10 }
        
        // Then - Should have correct stock distribution
        XCTAssertEqual(outOfStock.count, 1)
        XCTAssertEqual(lowStock.count, 1)
    }
    
    // MARK: - Error Handling (SIMPLIFIED)
    
    func test_errorHandling() async {
        // Given - Wrong credentials
        mockAuthService.shouldSucceed = false
        
        // When - Trying to login
        await authViewModel.signIn(email: "wrong@test.com", password: "wrong")
        
        // Then - Should not authenticate and show error
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNotNil(authViewModel.errorMessage)
        
        // Given - Correct credentials
        mockAuthService.shouldSucceed = true
        authViewModel.clearError()
        
        // When - Login with correct credentials
        await authViewModel.signIn(email: "test@test.com", password: "password")
        
        // Then - Should authenticate
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.errorMessage)
    }
    
    // MARK: - CRUD Operations (SIMPLIFIED)
    
    func test_crudOperations() async {
        // Given - Setup
        await authViewModel.signIn(email: "admin@test.com", password: "adminpass")
        await medicineViewModel.initializeApp()
        
        // CREATE
        await medicineViewModel.addMedicine(
            name: "Test Medicine",
            stock: 75,
            aisle: "Aisle 7",
            user: authViewModel.userEmail
        )
        XCTAssertEqual(mockMedicineService.addMedicineCallCount, 1)
        
        // READ
        let addedMedicine = mockMedicineService.medicines.first { $0.name == "Test Medicine" }
        XCTAssertNotNil(addedMedicine)
        
        // UPDATE
        if var medicine = addedMedicine {
            medicine.stock = 100
            await medicineViewModel.updateMedicine(medicine, user: authViewModel.userEmail)
            XCTAssertEqual(mockMedicineService.updateMedicineCallCount, 1)
        }
        
        // DELETE
        if let medicine = addedMedicine {
            await medicineViewModel.deleteMedicine(
                id: medicine.id!,
                name: medicine.name,
                user: authViewModel.userEmail
            )
            XCTAssertEqual(mockMedicineService.deleteMedicineCallCount, 1)
        }
    }
}
