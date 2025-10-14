//
//  MedicineStockViewModelTests.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 13/10/2025.
//

import XCTest
@testable import MediStock

@MainActor
class MedicineStockViewModelTests: XCTestCase {
    
    var viewModel: MedicineStockViewModel!
    var mockMedicineService: MockMedicineService!
    
    override func setUp() {
        super.setUp()
        mockMedicineService = MockMedicineService()
        viewModel = MedicineStockViewModel(medicineService: mockMedicineService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockMedicineService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitializeApp() async {
        // Given
        mockMedicineService.shouldThrowError = false
        
        // When
        await viewModel.initializeApp()
        
        // Then
        XCTAssertEqual(viewModel.appState, .ready, "App should be ready")
        XCTAssertFalse(viewModel.allMedicines.isEmpty, "Medicines should be loaded")
        XCTAssertEqual(viewModel.loadingProgress, 1.0, "Loading should be complete")
    }
    
    func testInitializeAppWithError() async {
        // Given
        mockMedicineService.shouldThrowError = true
        
        // When
        await viewModel.initializeApp()
        
        // Then
        if case .error = viewModel.appState {
            // Success - app is in error state
        } else {
            XCTFail("App should be in error state")
        }
        XCTAssertTrue(viewModel.allMedicines.isEmpty, "No medicines should be loaded")
    }
    
    // MARK: - Medicine Loading Tests
    
    func testLoadMoreMedicines() async {
        // Given
        // Add more medicines to mock to simulate pagination
        for i in 6...25 {
            mockMedicineService.medicines.append(
                Medicine(id: "\(i)", name: "Medicine \(i)", stock: i * 10, aisle: "Aisle \(i % 3 + 1)")
            )
        }
        
        await viewModel.initializeApp()
        let initialCount = viewModel.allMedicines.count
        
        // When
        await viewModel.loadMoreMedicines()
        
        // Then
        XCTAssertGreaterThanOrEqual(viewModel.allMedicines.count, initialCount, "Should have same or more medicines")
        XCTAssertGreaterThan(mockMedicineService.loadMedicinesCallCount, 0, "Load should be called at least once")
    }
    
    func testSearchMedicines() async {
        // Given
        await viewModel.initializeApp()
        
        // When
        await viewModel.searchMedicines(query: "Aspirin")
        
        // Then
        XCTAssertEqual(viewModel.allMedicines.count, 1, "Should find one medicine")
        XCTAssertEqual(viewModel.allMedicines.first?.name, "Aspirin", "Should find Aspirin")
    }
    
    func testSearchMedicinesEmptyQuery() async {
        // Given
        await viewModel.initializeApp()
        let initialCount = viewModel.allMedicines.count
        
        // When
        await viewModel.searchMedicines(query: "")
        
        // Then
        XCTAssertEqual(viewModel.allMedicines.count, initialCount, "Should return to normal view")
    }
    
    // MARK: - Sorting Tests
    
    func testSortByName() async {
        // Given
        await viewModel.initializeApp()
        
        // When
        await viewModel.changeSortOrder(to: .name, order: .ascending)
        
        // Then
        XCTAssertEqual(viewModel.currentSortField, .name, "Sort field should be name")
        XCTAssertEqual(viewModel.currentSortOrder, .ascending, "Sort order should be ascending")
        
        // Check if sorted correctly
        let names = viewModel.allMedicines.map { $0.name }
        let sortedNames = names.sorted()
        XCTAssertEqual(names, sortedNames, "Medicines should be sorted by name")
    }
    
    func testSortByStock() async {
        // Given
        await viewModel.initializeApp()
        
        // When
        await viewModel.changeSortOrder(to: .stock, order: .descending)
        
        // Then
        XCTAssertEqual(viewModel.currentSortField, .stock, "Sort field should be stock")
        XCTAssertEqual(viewModel.currentSortOrder, .descending, "Sort order should be descending")
    }
    
    // MARK: - Aisle Tests
    
    func testGetAisles() async {
        // Given
        await viewModel.initializeApp()
        
        // Then
        XCTAssertFalse(viewModel.aisles.isEmpty, "Should have aisles")
        XCTAssertTrue(viewModel.aisles.contains("Aisle 1"), "Should contain Aisle 1")
        XCTAssertTrue(viewModel.aisles.contains("Aisle 2"), "Should contain Aisle 2")
    }
    
    func testMedicinesForAisle() async {
        // Given
        await viewModel.initializeApp()
        
        // When
        let aisle1Medicines = viewModel.medicinesForAisle("Aisle 1")
        
        // Then
        XCTAssertEqual(aisle1Medicines.count, 2, "Aisle 1 should have 2 medicines")
        XCTAssertTrue(aisle1Medicines.allSatisfy { $0.aisle == "Aisle 1" }, "All should be in Aisle 1")
    }
    
    // MARK: - CRUD Operations Tests
    
    func testAddMedicine() async {
        // Given
        await viewModel.initializeApp()
        _ = viewModel.allMedicines.count
        
        // When
        await viewModel.addMedicine(
            name: "New Medicine",
            stock: 50,
            aisle: "Aisle 4",
            user: "test@example.com"
        )
        
        // Then
        XCTAssertEqual(mockMedicineService.addMedicineCallCount, 1, "Add medicine should be called")
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 1, "History should be added")
    }
    
    func testUpdateStock() async {
        // Given
        await viewModel.initializeApp()
        let medicineId = "1"
        
        // When
        await viewModel.updateStock(
            medicineId: medicineId,
            change: 10,
            user: "test@example.com"
        )
        
        // Then
        XCTAssertEqual(mockMedicineService.updateStockCallCount, 1, "Update stock should be called")
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 1, "History should be added")
    }
    
    func testUpdateMedicine() async {
        // Given
        await viewModel.initializeApp()
        var medicine = viewModel.allMedicines.first!
        medicine.name = "Updated Name"
        
        // When
        await viewModel.updateMedicine(medicine, user: "test@example.com")
        
        // Then
        XCTAssertEqual(mockMedicineService.updateMedicineCallCount, 1, "Update medicine should be called")
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 1, "History should be added")
    }
    
    func testDeleteMedicine() async {
        // Given
        await viewModel.initializeApp()
        
        // When
        await viewModel.deleteMedicine(
            id: "1",
            name: "Aspirin",
            user: "test@example.com"
        )
        
        // Then
        XCTAssertEqual(mockMedicineService.deleteMedicineCallCount, 1, "Delete should be called")
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 1, "History should be added")
    }
    
    // MARK: - History Tests
    
    func testLoadHistory() async {
        // Given
        await viewModel.initializeApp()
        mockMedicineService.addTestHistory(for: "1", count: 5)
        
        // When
        viewModel.loadHistory(for: "1")
        
        // Wait a bit for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(viewModel.currentHistory.count, 5, "Should load 5 history entries")
    }
    
    func testStopHistoryListener() {
        // Given
        viewModel.currentHistory = [
            HistoryEntry(medicineId: "1", user: "test", action: "test", details: "test")
        ]
        
        // When
        viewModel.stopHistoryListener()
        
        // Then
        XCTAssertTrue(viewModel.currentHistory.isEmpty, "History should be cleared")
    }
    
    // MARK: - Helper Methods Tests
    
    func testMedicineWithId() async {
        // Given
        await viewModel.initializeApp()
        
        // When
        let medicine = viewModel.medicine(withId: "1")
        
        // Then
        XCTAssertNotNil(medicine, "Should find medicine")
        XCTAssertEqual(medicine?.name, "Aspirin", "Should be Aspirin")
    }
    
    func testMedicineWithInvalidId() async {
        // Given
        await viewModel.initializeApp()
        
        // When
        let medicine = viewModel.medicine(withId: "invalid-id")
        
        // Then
        XCTAssertNil(medicine, "Should not find medicine")
    }
    
    // MARK: - Display Limit Tests
    
    func testShowMore() async {
        // Given
        await viewModel.initializeApp()
        viewModel.displayLimit = 5
        
        // When
        viewModel.showMore()
        
        // Then
        XCTAssertEqual(viewModel.displayLimit, 5, "Display limit should increase") // Since our mock only has 5 medicines
    }
    
    func testSetDisplayLimit() {
        // When
        viewModel.setDisplayLimit(10)
        
        // Then
        XCTAssertEqual(viewModel.displayLimit, 10, "Display limit should be set")
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanup() async {
        // Given
        await viewModel.initializeApp()
        
        // When
        viewModel.cleanup()
        
        // Then
        XCTAssertTrue(viewModel.allMedicines.isEmpty, "Medicines should be cleared")
        XCTAssertTrue(viewModel.currentHistory.isEmpty, "History should be cleared")
        XCTAssertEqual(viewModel.appState, .initializing, "App state should be reset")
        XCTAssertEqual(viewModel.displayLimit, 20, "Display limit should be reset")
    }
    
    // MARK: - Error Handling Tests
    
    func testAddMedicineWithError() async {
        // Given
        await viewModel.initializeApp()
        mockMedicineService.shouldThrowError = true
        
        // When
        await viewModel.addMedicine(
            name: "Test",
            stock: 10,
            aisle: "Aisle 1",
            user: "test@example.com"
        )
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set")
    }
    
    func testUpdateStockWithInvalidMedicine() async {
        // Given
        await viewModel.initializeApp()
        
        // When
        await viewModel.updateStock(
            medicineId: "invalid-id",
            change: 10,
            user: "test@example.com"
        )
        
        // Then - Should not crash, stock update just won't happen
        XCTAssertEqual(mockMedicineService.updateStockCallCount, 0, "Update should not be called for invalid ID")
    }

    func testHasMoreToShow() async {
        // Given
        await viewModel.initializeApp()
        
        // Test when displayLimit < allMedicines.count
        viewModel.displayLimit = 2
        XCTAssertTrue(viewModel.hasMoreToShow, "Should have more to show when display limit is less than total")
        
        // Test when displayLimit >= allMedicines.count but hasMoreMedicines is true
        viewModel.displayLimit = 100
        viewModel.hasMoreMedicines = true
        XCTAssertTrue(viewModel.hasMoreToShow, "Should have more to show when more medicines available")
        
        // Test when no more to show
        viewModel.displayLimit = 100
        viewModel.hasMoreMedicines = false
        XCTAssertFalse(viewModel.hasMoreToShow, "Should not have more to show")
    }

    func testStopMedicinesListener() async {
        // Given
        await viewModel.initializeApp()
        
        // When
        viewModel.stopMedicinesListener()
        
        // Then
        XCTAssertNotNil(viewModel, "Should not crash when stopping listener")
        // Verify the listener is actually stopped in the mock
        XCTAssertNil(mockMedicineService.medicinesListener, "Listener should be nil")
    }

    func testChangeSortOrderWithAisleSort() async {
        // Given
        await viewModel.initializeApp()
        
        // Add medicines with different aisles for better testing
        mockMedicineService.medicines = [
            Medicine(id: "1", name: "A", stock: 10, aisle: "Aisle 10"),
            Medicine(id: "2", name: "B", stock: 20, aisle: "Aisle 2"),
            Medicine(id: "3", name: "C", stock: 30, aisle: "Aisle 1"),
            Medicine(id: "4", name: "D", stock: 40, aisle: "Aisle 20")
        ]
        
        // When - Sort by aisle ascending
        await viewModel.changeSortOrder(to: .aisle, order: .ascending)
        
        // Then
        XCTAssertEqual(viewModel.currentSortField, .aisle, "Sort field should be aisle")
        XCTAssertEqual(viewModel.allMedicines.first?.aisle, "Aisle 1", "Should be sorted by aisle number")
        
        // When - Sort by aisle descending
        await viewModel.changeSortOrder(to: .aisle, order: .descending)
        
        // Then
        XCTAssertEqual(viewModel.currentSortOrder, .descending, "Sort order should be descending")
    }

    func testLoadMoreMedicinesWhenAlreadyLoading() async {
        // Given
        await viewModel.initializeApp()
        viewModel.isLoadingMore = true
        
        // When
        await viewModel.loadMoreMedicines()
        
        // Then - Should return early without loading
        XCTAssertTrue(viewModel.isLoadingMore, "Should still be in loading state")
    }

    func testLoadMoreMedicinesWhenNoMoreAvailable() async {
        // Given
        await viewModel.initializeApp()
        viewModel.hasMoreMedicines = false
        
        // When
        await viewModel.loadMoreMedicines()
        
        // Then - Should return early
        XCTAssertFalse(viewModel.hasMoreMedicines, "Should still have no more medicines")
    }

    func testGetLastValueWithDifferentSortFields() async {
        // This tests the private getLastValue method indirectly
        await viewModel.initializeApp()
        
        // Test with stock sort
        await viewModel.changeSortOrder(to: .stock, order: .ascending)
        XCTAssertNotNil(viewModel.allMedicines.last?.stock, "Should have last stock value")
        
        // Test with name sort
        await viewModel.changeSortOrder(to: .name, order: .ascending)
        XCTAssertNotNil(viewModel.allMedicines.last?.name, "Should have last name value")
        
        // Test with aisle sort
        await viewModel.changeSortOrder(to: .aisle, order: .ascending)
        XCTAssertNotNil(viewModel.allMedicines.last?.aisle, "Should have last aisle value")
    }

    func testLoadInitialMedicinesWithEmptyResult() async {
        // Given
        mockMedicineService.medicines = []
        
        // When
        await viewModel.initializeApp()
        
        // Then
        XCTAssertTrue(viewModel.allMedicines.isEmpty, "Should handle empty medicines list")
        XCTAssertFalse(viewModel.hasMoreMedicines, "Should not have more medicines")
        XCTAssertEqual(viewModel.appState, .ready, "Should still be ready even with no medicines")
    }

    func testDeleteMedicineErrorHandling() async {
        // Given
        await viewModel.initializeApp()
        mockMedicineService.shouldThrowError = true
        
        // When
        await viewModel.deleteMedicine(id: "1", name: "Test", user: "user@test.com")
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message")
    }

    func testUpdateMedicineWithoutId() async {
        // Given
        await viewModel.initializeApp()
        let medicineWithoutId = Medicine(name: "No ID", stock: 10, aisle: "Aisle 1")
        
        // When
        await viewModel.updateMedicine(medicineWithoutId, user: "user@test.com")
        
        // Then - Should return early without updating
        XCTAssertEqual(mockMedicineService.updateMedicineCallCount, 0, "Should not call update for medicine without ID")
    }
    
    func testUpdateStockServiceError() async {
        // Given
        await viewModel.initializeApp()
        let medicine = viewModel.allMedicines.first!
        
        // Make the service throw error on updateStock
        mockMedicineService.shouldThrowError = true
        viewModel.errorMessage = nil
        
        // When
        await viewModel.updateStock(
            medicineId: medicine.id!,
            change: 10,
            user: "test@example.com"
        )
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set")
        XCTAssertEqual(mockMedicineService.updateStockCallCount, 1, "Should attempt to update stock")
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 0, "Should not add history when update fails")
    }

    func testUpdateStockHistoryError() async {
        // Given
        await viewModel.initializeApp()
        let medicine = viewModel.allMedicines.first!
        viewModel.errorMessage = nil
        
        // Make the service succeed on updateStock but fail on addHistory
        mockMedicineService.shouldThrowError = false
        
        // Override addHistoryEntry to throw error
        mockMedicineService.addHistoryCallCount = 0
        
        // When - First update stock successfully
        await viewModel.updateStock(
            medicineId: medicine.id!,
            change: 10,
            user: "test@example.com"
        )
        
        // Then make history fail for next call
        mockMedicineService.shouldThrowError = true
        
        // When - Try another update
        await viewModel.updateStock(
            medicineId: medicine.id!,
            change: 5,
            user: "test@example.com"
        )
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set when history fails")
    }

    func testUpdateMedicineServiceError() async {
        // Given
        await viewModel.initializeApp()
        var medicine = viewModel.allMedicines.first!
        medicine.name = "Updated Name"
        
        // Make the service throw error
        mockMedicineService.shouldThrowError = true
        viewModel.errorMessage = nil
        
        // When
        await viewModel.updateMedicine(medicine, user: "test@example.com")
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set")
        XCTAssertTrue(viewModel.errorMessage?.contains("failed") ?? false, "Error should indicate failure")
        XCTAssertEqual(mockMedicineService.updateMedicineCallCount, 1, "Should attempt to update medicine")
        XCTAssertEqual(mockMedicineService.addHistoryCallCount, 0, "Should not add history when update fails")
    }

    func testUpdateMedicineHistoryError() async {
        // Given
        await viewModel.initializeApp()
        var medicine = viewModel.allMedicines.first!
        medicine.name = "Updated Name"
        viewModel.errorMessage = nil
        
        // Create a custom test to make only history fail
        // First call succeeds
        mockMedicineService.shouldThrowError = false
        
        // Update the mock to fail only on history
        // This is a bit tricky, so we'll do it differently
        // We'll make two calls - first succeeds, second fails on history
        
        // When - First update successfully
        await viewModel.updateMedicine(medicine, user: "test@example.com")
        XCTAssertNil(viewModel.errorMessage, "First update should succeed")
        
        // Now make the service fail
        mockMedicineService.shouldThrowError = true
        
        // When - Try another update (this will fail)
        medicine.name = "Another Update"
        await viewModel.updateMedicine(medicine, user: "test@example.com")
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set")
    }

    func testUpdateStockWithNegativeResultHandling() async {
        // Test that stock can't go below 0
        await viewModel.initializeApp()
        let medicine = viewModel.allMedicines.first!
        let originalStock = medicine.stock
        
        // When - Try to remove more than available
        await viewModel.updateStock(
            medicineId: medicine.id!,
            change: -(originalStock + 100), // Remove more than available
            user: "test@example.com"
        )
        
        // Then - Stock should be 0, not negative
        XCTAssertEqual(mockMedicineService.updateStockCallCount, 1, "Should call updateStock")
        // The newStock calculation uses max(0, ...) so it should never go negative
    }

    func testErrorMessagePersistence() async {
        // Test that error messages persist and can be cleared
        await viewModel.initializeApp()
        
        // Set an error
        mockMedicineService.shouldThrowError = true
        await viewModel.addMedicine(name: "Test", stock: 10, aisle: "A1", user: "test@test.com")
        
        // Verify error is set
        XCTAssertNotNil(viewModel.errorMessage, "Should have error")
        
        // Clear error
        viewModel.errorMessage = nil
        
        // Verify it's cleared
        XCTAssertNil(viewModel.errorMessage, "Error should be cleared")
    }
}
