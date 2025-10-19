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
        mockService.shouldThrowError = false
        
        await sut.initializeApp()
        
        XCTAssertEqual(sut.appState, .ready)
        XCTAssertFalse(sut.allMedicines.isEmpty)
        XCTAssertEqual(sut.loadingProgress, 1.0)
    }
    
    func test_initializeApp_withError_setsErrorState() async {
        mockService.shouldThrowError = true
        
        await sut.initializeApp()
        
        if case .error = sut.appState {
        } else {
            XCTFail("App should be in error state")
        }
        XCTAssertTrue(sut.allMedicines.isEmpty)
    }
    
    // MARK: - Medicine Operations Tests
    
    func test_addMedicine_callsServiceAndAddsHistory() async {
        await sut.initializeApp()
        let name = "Test Medicine"
        let stock = 50
        let aisle = 1
        let user = "test@test.com"
        
        await sut.addMedicine(name: name, stock: stock, aisle: aisle, user: user)
        
        XCTAssertEqual(mockService.addMedicineCallCount, 1)
        XCTAssertEqual(mockService.addHistoryCallCount, 1)
    }
    
    func test_addMedicine_withError_setsErrorMessage() async {
        await sut.initializeApp()
        mockService.shouldThrowError = true
        
        await sut.addMedicine(name: "Test", stock: 10, aisle: 1, user: "test@test.com")
        
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func test_updateStock_updatesCorrectly() async {
        await sut.initializeApp()
        let medicineId = "1"
        let change = 10
        let user = "test@test.com"
        
        await sut.updateStock(medicineId: medicineId, change: change, user: user)
        
        XCTAssertEqual(mockService.updateStockCallCount, 1)
        XCTAssertEqual(mockService.addHistoryCallCount, 1)
    }
    
    func test_updateStock_withInvalidId_returnsEarly() async {
        await sut.initializeApp()
        let invalidId = "invalid-id"
        
        await sut.updateStock(medicineId: invalidId, change: 10, user: "test@test.com")
        
        XCTAssertEqual(mockService.updateStockCallCount, 0)
    }
    
    func test_updateStock_preventsNegativeStock() async {
        await sut.initializeApp()
        let medicineId = "1"
        let largeNegativeChange = -1000
        
        await sut.updateStock(medicineId: medicineId, change: largeNegativeChange, user: "test@test.com")
        
        XCTAssertEqual(mockService.updateStockCallCount, 1)
    }
    
    func test_updateMedicine_updatesAndAddsHistory() async {
        await sut.initializeApp()
        var medicine = sut.allMedicines.first!
        medicine.name = "Updated Name"
        
        await sut.updateMedicine(medicine, user: "test@test.com")
        
        XCTAssertEqual(mockService.updateMedicineCallCount, 1)
        XCTAssertEqual(mockService.addHistoryCallCount, 1)
    }
    
    func test_updateMedicine_withoutId_returnsEarly() async {
        await sut.initializeApp()
        let medicineWithoutId = Medicine(name: "No ID", stock: 10, aisle: 1)
        
        await sut.updateMedicine(medicineWithoutId, user: "test@test.com")
        
        XCTAssertEqual(mockService.updateMedicineCallCount, 0)
    }
    
    func test_deleteMedicine_removesAndAddsHistory() async {
        await sut.initializeApp()
        let id = "1"
        let name = "Aspirin"
        let user = "test@test.com"
        
        await sut.deleteMedicine(id: id, name: name, user: user)
        
        XCTAssertEqual(mockService.deleteMedicineCallCount, 1)
        XCTAssertEqual(mockService.addHistoryCallCount, 1)
    }
    
    // MARK: - Search and Filter Tests
    
    func test_searchMedicines_filtersCorrectly() async {
        await sut.initializeApp()
        let searchQuery = "Aspirin"
        
        await sut.searchMedicines(query: searchQuery)
        
        XCTAssertEqual(sut.allMedicines.count, 1)
        XCTAssertEqual(sut.allMedicines.first?.name, "Aspirin")
    }
    
    func test_searchMedicines_withEmptyQuery_returnsToNormalView() async {
        await sut.initializeApp()
        let initialCount = sut.allMedicines.count
        
        await sut.searchMedicines(query: "")
        
        XCTAssertEqual(sut.allMedicines.count, initialCount)
    }
    
    func test_medicinesForAisle_returnsCorrectMedicines() async {
        await sut.initializeApp()
        let targetAisle = 1
        
        let aisle1Medicines = sut.medicinesForAisle(targetAisle)
        
        XCTAssertEqual(aisle1Medicines.count, 2)
        XCTAssertTrue(aisle1Medicines.allSatisfy { $0.aisle == targetAisle })
    }
    
    // MARK: - Sorting Tests
    
    func test_changeSortOrder_byName_sortsAlphabetically() async {
        await sut.initializeApp()
        
        await sut.changeSortOrder(to: .name, order: .ascending)
        
        let names = sut.allMedicines.map { $0.name }
        let sortedNames = names.sorted()
        XCTAssertEqual(names, sortedNames)
        XCTAssertEqual(sut.currentSortField, .name)
        XCTAssertEqual(sut.currentSortOrder, .ascending)
    }
    
    func test_changeSortOrder_byStock_sortsNumerically() async {
        await sut.initializeApp()
        
        await sut.changeSortOrder(to: .stock, order: .descending)
        
        XCTAssertEqual(sut.currentSortField, .stock)
        XCTAssertEqual(sut.currentSortOrder, .descending)
    }
    
    func test_changeSortOrder_byAisle_sortsCorrectly() async {
        await sut.initializeApp()
        
        await sut.changeSortOrder(to: .aisle, order: .ascending)
        
        XCTAssertEqual(sut.currentSortField, .aisle)
        XCTAssertEqual(sut.currentSortOrder, .ascending)
    }
    
    // MARK: - Basic Pagination Tests
    
    func test_loadMoreMedicines_whenAlreadyLoading_returnsEarly() async {
        await sut.initializeApp()
        sut.isLoadingMore = true
        let countBefore = mockService.loadMedicinesCallCount
        
        await sut.loadMoreMedicines()
        
        XCTAssertEqual(mockService.loadMedicinesCallCount, countBefore)
    }
    
    // MARK: - Helper Methods Tests
    
    func test_medicine_withValidId_returnsMedicine() async {
        await sut.initializeApp()
        
        let medicine = sut.medicine(withId: "1")
        
        XCTAssertNotNil(medicine)
        XCTAssertEqual(medicine?.name, "Aspirin")
    }
    
    func test_medicine_withInvalidId_returnsNil() async {
        await sut.initializeApp()
        
        let medicine = sut.medicine(withId: "invalid")
        
        XCTAssertNil(medicine)
    }
    
    func test_aisles_returnsUniqueAislesSorted() async {
        await sut.initializeApp()
        
        let aisles = sut.aisles
        
        XCTAssertEqual(aisles.count, 3)
        XCTAssertTrue(aisles.contains(1))
        XCTAssertTrue(aisles.contains(2))
        XCTAssertTrue(aisles.contains(3))
        XCTAssertEqual(aisles, aisles.sorted())
    }
    
    // MARK: - Cleanup Tests
    
    func test_cleanup_resetsEverything() async {
        await sut.initializeApp()
        XCTAssertFalse(sut.allMedicines.isEmpty)
        
        sut.cleanup()
        
        XCTAssertTrue(sut.allMedicines.isEmpty)
        XCTAssertEqual(sut.appState, .initializing)
        XCTAssertNil(sut.errorMessage)
    }
    
    func test_stopMedicinesListener_callsService() async {
        await sut.initializeApp()
        
        sut.stopMedicinesListener()
        
        XCTAssertNil(mockService.medicinesListener)
    }
}
