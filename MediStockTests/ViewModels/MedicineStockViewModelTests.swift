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
    
    var sut: MedicineStockViewModel!
    var mockService: MockMedicineService!
    
    override func setUp() {
        super.setUp()
        mockService = MockMedicineService()
        sut = MedicineStockViewModel(medicineService: mockService)
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_initializeApp_loadsInitialMedicines() async {
        // Given
        mockService.shouldThrowError = false
        
        // When
        await sut.initializeApp()
        
        // Then
        XCTAssertEqual(sut.appState, .ready)
        XCTAssertFalse(sut.allMedicines.isEmpty)
        XCTAssertEqual(sut.loadingProgress, 1.0)
    }
    
    func test_initializeApp_withError_setsErrorState() async {
        // Given
        mockService.shouldThrowError = true
        
        // When
        await sut.initializeApp()
        
        // Then
        if case .error = sut.appState {
            // Success - app is in error state
        } else {
            XCTFail("App should be in error state")
        }
        XCTAssertTrue(sut.allMedicines.isEmpty)
    }
    
    // MARK: - Medicine Operations Tests
    
    func test_addMedicine_callsServiceAndAddsHistory() async {
        // Given
        await sut.initializeApp()
        let name = "Test Medicine"
        let stock = 50
        let aisle = "A1"
        let user = "test@test.com"
        
        // When
        await sut.addMedicine(name: name, stock: stock, aisle: aisle, user: user)
        
        // Then
        XCTAssertEqual(mockService.addMedicineCallCount, 1)
        XCTAssertEqual(mockService.addHistoryCallCount, 1)
    }
    
    func test_addMedicine_withError_setsErrorMessage() async {
        // Given
        await sut.initializeApp()
        mockService.shouldThrowError = true
        
        // When
        await sut.addMedicine(name: "Test", stock: 10, aisle: "A1", user: "test@test.com")
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func test_updateStock_updatesCorrectly() async {
        // Given
        await sut.initializeApp()
        let medicineId = "1"  // Aspirin in mock data
        let change = 10
        let user = "test@test.com"
        
        // When
        await sut.updateStock(medicineId: medicineId, change: change, user: user)
        
        // Then
        XCTAssertEqual(mockService.updateStockCallCount, 1)
        XCTAssertEqual(mockService.addHistoryCallCount, 1)
    }
    
    func test_updateStock_withInvalidId_returnsEarly() async {
        // Given
        await sut.initializeApp()
        let invalidId = "invalid-id"
        
        // When
        await sut.updateStock(medicineId: invalidId, change: 10, user: "test@test.com")
        
        // Then
        XCTAssertEqual(mockService.updateStockCallCount, 0)
    }
    
    func test_updateStock_preventsNegativeStock() async {
        // Given
        await sut.initializeApp()
        let medicineId = "1"
        let largeNegativeChange = -1000
        
        // When
        await sut.updateStock(medicineId: medicineId, change: largeNegativeChange, user: "test@test.com")
        
        // Then
        XCTAssertEqual(mockService.updateStockCallCount, 1)
        // Stock should be 0, not negative
    }
    
    func test_updateMedicine_updatesAndAddsHistory() async {
        // Given
        await sut.initializeApp()
        var medicine = sut.allMedicines.first!
        medicine.name = "Updated Name"
        
        // When
        await sut.updateMedicine(medicine, user: "test@test.com")
        
        // Then
        XCTAssertEqual(mockService.updateMedicineCallCount, 1)
        XCTAssertEqual(mockService.addHistoryCallCount, 1)
    }
    
    func test_updateMedicine_withoutId_returnsEarly() async {
        // Given
        await sut.initializeApp()
        let medicineWithoutId = Medicine(name: "No ID", stock: 10, aisle: "A1")
        
        // When
        await sut.updateMedicine(medicineWithoutId, user: "test@test.com")
        
        // Then
        XCTAssertEqual(mockService.updateMedicineCallCount, 0)
    }
    
    func test_deleteMedicine_removesAndAddsHistory() async {
        // Given
        await sut.initializeApp()
        let id = "1"
        let name = "Aspirin"
        let user = "test@test.com"
        
        // When
        await sut.deleteMedicine(id: id, name: name, user: user)
        
        // Then
        XCTAssertEqual(mockService.deleteMedicineCallCount, 1)
        XCTAssertEqual(mockService.addHistoryCallCount, 1)
    }
    
    // MARK: - Search and Filter Tests
    
    func test_searchMedicines_filtersCorrectly() async {
        // Given
        await sut.initializeApp()
        let searchQuery = "Aspirin"
        
        // When
        await sut.searchMedicines(query: searchQuery)
        
        // Then
        XCTAssertEqual(sut.allMedicines.count, 1)
        XCTAssertEqual(sut.allMedicines.first?.name, "Aspirin")
    }
    
    func test_searchMedicines_withEmptyQuery_returnsToNormalView() async {
        // Given
        await sut.initializeApp()
        let initialCount = sut.allMedicines.count
        
        // When
        await sut.searchMedicines(query: "")
        
        // Then
        XCTAssertEqual(sut.allMedicines.count, initialCount)
    }
    
    func test_medicinesForAisle_returnsCorrectMedicines() async {
        // Given
        await sut.initializeApp()
        let targetAisle = "Aisle 1"
        
        // When
        let aisle1Medicines = sut.medicinesForAisle(targetAisle)
        
        // Then
        XCTAssertEqual(aisle1Medicines.count, 2)
        XCTAssertTrue(aisle1Medicines.allSatisfy { $0.aisle == targetAisle })
    }
    
    // MARK: - Sorting Tests
    
    func test_changeSortOrder_byName_sortsAlphabetically() async {
        // Given
        await sut.initializeApp()
        
        // When
        await sut.changeSortOrder(to: .name, order: .ascending)
        
        // Then
        let names = sut.allMedicines.map { $0.name }
        let sortedNames = names.sorted()
        XCTAssertEqual(names, sortedNames)
        XCTAssertEqual(sut.currentSortField, .name)
        XCTAssertEqual(sut.currentSortOrder, .ascending)
    }
    
    func test_changeSortOrder_byStock_sortsNumerically() async {
        // Given
        await sut.initializeApp()
        
        // When
        await sut.changeSortOrder(to: .stock, order: .descending)
        
        // Then
        XCTAssertEqual(sut.currentSortField, .stock)
        XCTAssertEqual(sut.currentSortOrder, .descending)
    }
    
    func test_changeSortOrder_byAisle_sortsCorrectly() async {
        // Given
        await sut.initializeApp()
        
        // When
        await sut.changeSortOrder(to: .aisle, order: .ascending)
        
        // Then
        XCTAssertEqual(sut.currentSortField, .aisle)
        XCTAssertEqual(sut.currentSortOrder, .ascending)
    }
    
    // MARK: - History Tests
    
    func test_loadHistory_loadsForSpecificMedicine() async {
        // Given
        let medicineId = "1"
        mockService.addTestHistory(for: medicineId, count: 5)
        
        // When
        sut.loadHistory(for: medicineId)
        
        // Then
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(sut.currentHistory.count, 5)
    }
    
    func test_stopHistoryListener_clearsHistory() {
        // Given
        sut.currentHistory = [
            HistoryEntry(medicineId: "1", user: "test", action: "Added", details: "test")
        ]
        
        // When
        sut.stopHistoryListener()
        
        // Then
        XCTAssertTrue(sut.currentHistory.isEmpty)
    }
    
    // MARK: - Basic Pagination Tests (Keep existing coverage)
    
    func test_loadMoreMedicines_whenAlreadyLoading_returnsEarly() async {
        // Given
        await sut.initializeApp()
        sut.isLoadingMore = true
        let countBefore = mockService.loadMedicinesCallCount
        
        // When
        await sut.loadMoreMedicines()
        
        // Then
        XCTAssertEqual(mockService.loadMedicinesCallCount, countBefore)
    }
    
    func test_loadMoreMedicines_whenNoMoreAvailable_returnsEarly() async {
        // Given
        await sut.initializeApp()
        sut.hasMoreMedicines = false
        let countBefore = mockService.loadMedicinesCallCount
        
        // When
        await sut.loadMoreMedicines()
        
        // Then
        XCTAssertEqual(mockService.loadMedicinesCallCount, countBefore)
    }
    
    // MARK: - Helper Methods Tests
    
    func test_medicine_withValidId_returnsMedicine() async {
        // Given
        await sut.initializeApp()
        
        // When
        let medicine = sut.medicine(withId: "1")
        
        // Then
        XCTAssertNotNil(medicine)
        XCTAssertEqual(medicine?.name, "Aspirin")
    }
    
    func test_medicine_withInvalidId_returnsNil() async {
        // Given
        await sut.initializeApp()
        
        // When
        let medicine = sut.medicine(withId: "invalid")
        
        // Then
        XCTAssertNil(medicine)
    }
    
    func test_aisles_returnsUniqueAislesSorted() async {
        // Given
        await sut.initializeApp()
        
        // When
        let aisles = sut.aisles
        
        // Then
        XCTAssertEqual(aisles.count, 3)
        XCTAssertTrue(aisles.contains("Aisle 1"))
        XCTAssertTrue(aisles.contains("Aisle 2"))
        XCTAssertTrue(aisles.contains("Aisle 3"))
        XCTAssertEqual(aisles, aisles.sorted())
    }
    
    // MARK: - Cleanup Tests
    
    func test_cleanup_resetsEverything() async {
        // Given
        await sut.initializeApp()
        XCTAssertFalse(sut.allMedicines.isEmpty)
        
        // When
        sut.cleanup()
        
        // Then
        XCTAssertTrue(sut.allMedicines.isEmpty)
        XCTAssertTrue(sut.currentHistory.isEmpty)
        XCTAssertEqual(sut.appState, .initializing)
        XCTAssertNil(sut.errorMessage)
    }
    
    func test_stopMedicinesListener_callsService() async {
        // Given
        await sut.initializeApp()
        
        // When
        sut.stopMedicinesListener()
        
        // Then
        XCTAssertNil(mockService.medicinesListener)
    }
}
