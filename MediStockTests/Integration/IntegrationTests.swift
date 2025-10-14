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
    
    // MARK: - Complete User Flow Tests
    
    func testCompleteUserLoginAndMedicineManagementFlow() async {
        // Step 1: User logs in
        await authViewModel.signIn(email: "user@test.com", password: "password123")
        XCTAssertTrue(authViewModel.isAuthenticated, "User should be logged in")
        
        // Step 2: App initializes and loads medicines
        await medicineViewModel.initializeApp()
        XCTAssertEqual(medicineViewModel.appState, .ready, "App should be ready")
        XCTAssertFalse(medicineViewModel.allMedicines.isEmpty, "Medicines should be loaded")
        
        // Step 3: User searches for a specific medicine
        await medicineViewModel.searchMedicines(query: "Aspirin")
        XCTAssertEqual(medicineViewModel.allMedicines.count, 1, "Should find Aspirin")
        
        // Step 4: User updates stock
        let medicine = medicineViewModel.allMedicines.first!
        await medicineViewModel.updateStock(
            medicineId: medicine.id!,
            change: 10,
            user: authViewModel.userEmail
        )
        XCTAssertEqual(mockMedicineService.updateStockCallCount, 1, "Stock should be updated")
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 1, "History should be recorded")
        
        // Step 5: User logs out
        authViewModel.signOut()
        XCTAssertFalse(authViewModel.isAuthenticated, "User should be logged out")
        
        // Step 6: Cleanup
        medicineViewModel.cleanup()
        XCTAssertTrue(medicineViewModel.allMedicines.isEmpty, "Data should be cleared")
    }
    
    func testNewUserSignupAndAddMedicineFlow() async {
        // Step 1: New user signs up
        await authViewModel.signUp(email: "newuser@test.com", password: "newpassword123")
        XCTAssertTrue(authViewModel.isAuthenticated, "New user should be authenticated")
        XCTAssertEqual(authViewModel.userEmail, "newuser@test.com", "Email should match")
        
        // Step 2: Initialize app for new user
        await medicineViewModel.initializeApp()
        XCTAssertEqual(medicineViewModel.appState, .ready, "App should be ready")
        
        // Step 3: Add a new medicine
        let initialCount = medicineViewModel.allMedicines.count
        await medicineViewModel.addMedicine(
            name: "New Medicine",
            stock: 100,
            aisle: "Aisle 10",
            user: authViewModel.userEmail
        )
        
        // Verify medicine was added
        XCTAssertEqual(mockMedicineService.addMedicineCallCount, 1, "Medicine should be added")
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 1, "History should be added")
        
        // Step 4: Verify the new medicine appears in the list
        mockMedicineService.startMedicinesListener { medicines in
            XCTAssertEqual(medicines.count, initialCount + 1, "Should have one more medicine")
        }
    }
    
    // MARK: - Aisle Management Flow
    
    func testAisleFilteringAndManagementFlow() async {
        // Step 1: Login and initialize
        await authViewModel.signIn(email: "user@test.com", password: "password")
        await medicineViewModel.initializeApp()
        
        // Step 2: Get all aisles
        let aisles = medicineViewModel.aisles
        XCTAssertFalse(aisles.isEmpty, "Should have aisles")
        XCTAssertEqual(aisles.count, 3, "Should have 3 aisles")
        
        // Step 3: Filter medicines by aisle
        let aisle1Medicines = medicineViewModel.medicinesForAisle("Aisle 1")
        XCTAssertEqual(aisle1Medicines.count, 2, "Aisle 1 should have 2 medicines")
        
        // Step 4: Add medicine to specific aisle
        await medicineViewModel.addMedicine(
            name: "New Aisle 1 Medicine",
            stock: 50,
            aisle: "Aisle 1",
            user: authViewModel.userEmail
        )
        
        // Step 5: Verify aisle now has more medicines
        mockMedicineService.startMedicinesListener(forAisle: "Aisle 1") { medicines in
            XCTAssertEqual(medicines.count, 3, "Aisle 1 should now have 3 medicines")
        }
    }
    
    // MARK: - Stock Management Flow
    
    func testLowStockAndOutOfStockFlow() async {
        // Step 1: Setup
        await authViewModel.signIn(email: "user@test.com", password: "password")
        await medicineViewModel.initializeApp()
        
        // Step 2: Find medicines with different stock levels
        let outOfStock = medicineViewModel.allMedicines.filter { $0.stock == 0 }
        let lowStock = medicineViewModel.allMedicines.filter { $0.stock > 0 && $0.stock < 10 }
        let normalStock = medicineViewModel.allMedicines.filter { $0.stock >= 10 }
        
        XCTAssertEqual(outOfStock.count, 1, "Should have 1 out of stock medicine")
        XCTAssertEqual(lowStock.count, 1, "Should have 1 low stock medicine")
        XCTAssertEqual(normalStock.count, 3, "Should have 3 normal stock medicines")
        
        // Step 3: Update out of stock medicine
        if let outOfStockMedicine = outOfStock.first {
            await medicineViewModel.updateStock(
                medicineId: outOfStockMedicine.id!,
                change: 50,
                user: authViewModel.userEmail
            )
            
            // Verify stock was updated
            XCTAssertEqual(mockMedicineService.updateStockCallCount, 1, "Stock should be updated")
        }
        
        // Step 4: Deplete stock to zero
        if let normalStockMedicine = normalStock.first {
            let currentStock = normalStockMedicine.stock
            await medicineViewModel.updateStock(
                medicineId: normalStockMedicine.id!,
                change: -currentStock,
                user: authViewModel.userEmail
            )
            
            // Verify stock is now zero
            XCTAssertEqual(mockMedicineService.updateStockCallCount, 2, "Stock should be updated again")
        }
    }
    
    // MARK: - History Tracking Flow
    
    func testCompleteHistoryTrackingFlow() async {
        // Step 1: Setup
        await authViewModel.signIn(email: "tracker@test.com", password: "password")
        await medicineViewModel.initializeApp()
        
        // Step 2: Get a medicine
        let medicine = medicineViewModel.allMedicines.first!
        let medicineId = medicine.id!
        
        // Step 3: Perform multiple operations
        
        // Add stock
        await medicineViewModel.updateStock(
            medicineId: medicineId,
            change: 20,
            user: authViewModel.userEmail
        )
        
        // Remove stock
        await medicineViewModel.updateStock(
            medicineId: medicineId,
            change: -5,
            user: authViewModel.userEmail
        )
        
        // Update medicine details
        var updatedMedicine = medicine
        updatedMedicine.name = "Updated Name"
        updatedMedicine.aisle = "Aisle 5"
        await medicineViewModel.updateMedicine(updatedMedicine, user: authViewModel.userEmail)
        
        // Step 4: Load history
            mockMedicineService.historyEntries = [] // Clear any existing entries
            mockMedicineService.addTestHistory(for: medicineId, count: 3)
            medicineViewModel.loadHistory(for: medicineId)
            
            // Wait for history to load
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Step 5: Verify history
            XCTAssertEqual(medicineViewModel.currentHistory.count, 3, "Should have 3 history entries")
        }
    
    // MARK: - Error Handling Flow
    
    func testErrorHandlingFlow() async {
        // Step 1: Try login with wrong credentials
        mockAuthService.shouldSucceed = false
        await authViewModel.signIn(email: "wrong@test.com", password: "wrongpass")
        XCTAssertFalse(authViewModel.isAuthenticated, "Should not be authenticated")
        XCTAssertNotNil(authViewModel.errorMessage, "Should have error message")
        
        // Step 2: Clear error and login correctly
        authViewModel.clearError()
        XCTAssertNil(authViewModel.errorMessage, "Error should be cleared")
        
        mockAuthService.shouldSucceed = true
        await authViewModel.signIn(email: "correct@test.com", password: "correctpass")
        XCTAssertTrue(authViewModel.isAuthenticated, "Should be authenticated now")
        
        // Step 3: Initialize app with medicine service error
        mockMedicineService.shouldThrowError = true
        await medicineViewModel.initializeApp()
        
        if case .error = medicineViewModel.appState {
            // Expected error state
        } else {
            XCTFail("App should be in error state")
        }
        
        // Step 4: Retry with success
        mockMedicineService.shouldThrowError = false
        mockMedicineService.reset()
        medicineViewModel.cleanup()
        await medicineViewModel.initializeApp()
        XCTAssertEqual(medicineViewModel.appState, .ready, "App should recover and be ready")
    }
    
    // MARK: - Sorting and Filtering Flow
    
    func testSortingAndFilteringFlow() async {
        // Step 1: Setup
        await authViewModel.signIn(email: "user@test.com", password: "password")
        await medicineViewModel.initializeApp()
        
        // Step 2: Sort by name ascending
        await medicineViewModel.changeSortOrder(to: .name, order: .ascending)
        let namesSortedAsc = medicineViewModel.allMedicines.map { $0.name }
        XCTAssertEqual(namesSortedAsc, namesSortedAsc.sorted(), "Should be sorted by name ascending")
        
        // Step 3: Sort by stock descending
        await medicineViewModel.changeSortOrder(to: .stock, order: .descending)
        let stocks = medicineViewModel.allMedicines.map { $0.stock }
        XCTAssertEqual(stocks, stocks.sorted(by: >), "Should be sorted by stock descending")
        
        // Step 4: Search for specific medicine
        await medicineViewModel.searchMedicines(query: "Vita")
        XCTAssertEqual(medicineViewModel.allMedicines.count, 1, "Should find Vitamin C")
        XCTAssertEqual(medicineViewModel.allMedicines.first?.name, "Vitamin C", "Should be Vitamin C")
        
        // Step 5: Clear search
        await medicineViewModel.searchMedicines(query: "")
        XCTAssertEqual(medicineViewModel.allMedicines.count, 5, "Should show all medicines again")
    }
    
    // MARK: - Pagination Flow
    
    func testPaginationFlow() async {
        // Step 1: Setup
        await authViewModel.signIn(email: "user@test.com", password: "password")
        
        // Add more test data for pagination
        for i in 6...30 {
            mockMedicineService.medicines.append(
                Medicine(id: "\(i)", name: "Medicine \(i)", stock: i * 10, aisle: "Aisle \(i % 5 + 1)")
            )
        }
        
        // Step 2: Initialize with first page
        await medicineViewModel.initializeApp()
        let firstPageCount = medicineViewModel.allMedicines.count
        XCTAssertLessThanOrEqual(firstPageCount, 20, "Should load first page")
        
        // Step 3: Load more
        await medicineViewModel.loadMoreMedicines()
        let secondPageCount = medicineViewModel.allMedicines.count
        XCTAssertGreaterThan(secondPageCount, firstPageCount, "Should have loaded more medicines")
        
        // Step 4: Check display limit
        medicineViewModel.setDisplayLimit(10)
        XCTAssertEqual(medicineViewModel.displayLimit, 10, "Display limit should be 10")
        
        let displayed = medicineViewModel.displayedMedicines
        XCTAssertEqual(displayed.count, 10, "Should display only 10 medicines")
        
        // Step 5: Show more
            medicineViewModel.showMore()
            let expectedLimit = min(medicineViewModel.displayLimit + 20, medicineViewModel.allMedicines.count)
            XCTAssertEqual(medicineViewModel.displayLimit, expectedLimit, "Should increase display limit appropriately")
        }
    
    // MARK: - Medicine CRUD Full Flow
    
    func testCompleteMedicineCRUDFlow() async {
        // Step 1: Setup
        await authViewModel.signIn(email: "admin@test.com", password: "adminpass")
        await medicineViewModel.initializeApp()
        
        let initialCount = medicineViewModel.allMedicines.count
        
        // Step 2: CREATE - Add new medicine
        await medicineViewModel.addMedicine(
            name: "Test Medicine",
            stock: 75,
            aisle: "Aisle 7",
            user: authViewModel.userEmail
        )
        XCTAssertEqual(mockMedicineService.addMedicineCallCount, 1, "Medicine should be added")
        
        // Step 3: READ - Find the medicine
        let addedMedicine = mockMedicineService.medicines.first { $0.name == "Test Medicine" }
        XCTAssertNotNil(addedMedicine, "Should find the added medicine")
        
        // Step 4: UPDATE - Modify the medicine
        if var medicine = addedMedicine {
            medicine.name = "Updated Test Medicine"
            medicine.stock = 100
            await medicineViewModel.updateMedicine(medicine, user: authViewModel.userEmail)
            XCTAssertEqual(mockMedicineService.updateMedicineCallCount, 1, "Medicine should be updated")
        }
        
        // Step 5: DELETE - Remove the medicine
        if let medicine = addedMedicine {
            await medicineViewModel.deleteMedicine(
                id: medicine.id!,
                name: medicine.name,
                user: authViewModel.userEmail
            )
            XCTAssertEqual(mockMedicineService.deleteMedicineCallCount, 1, "Medicine should be deleted")
        }
        
        // Step 6: Verify final state
        XCTAssertEqual(mockMedicineService.medicines.count, initialCount, "Should be back to initial count")
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 3, "Should have 3 history entries (add, update, delete)")
    }
}
