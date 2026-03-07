import XCTest
@testable import Lucid

@MainActor
final class FilterStateTests: XCTestCase {
    var filterState: FilterState!

    override func setUp() {
        super.setUp()
        filterState = FilterState()
    }

    override func tearDown() {
        filterState = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialSelectedFilterIsAll() {
        XCTAssertEqual(filterState.selectedFilter, .all)
    }

    func testInitialSearchTextIsEmpty() {
        XCTAssertEqual(filterState.searchText, "")
    }

    func testInitialDebouncedSearchTextIsEmpty() {
        XCTAssertEqual(filterState.debouncedSearchText, "")
    }

    // MARK: - Filter Application Tests

    func testApplyFilterChangesSelectedFilter() {
        filterState.applyFilter(.system)
        XCTAssertEqual(filterState.selectedFilter, .system)
    }

    func testClearSearchResetsSearchText() {
        filterState.searchText = "test"
        filterState.clearSearch()
        XCTAssertEqual(filterState.searchText, "")
    }

    // MARK: - Process Filtering Tests

    func testFilterProcessesWithNoFiltersReturnsAll() {
        let processes = sampleProcesses()
        let filtered = filterState.filter(processes)
        XCTAssertEqual(filtered.count, processes.count)
    }

    func testFilterProcessesByCategory() {
        let processes = sampleProcesses()
        filterState.applyFilter(.system)

        let filtered = filterState.filter(processes)

        XCTAssertTrue(filtered.allSatisfy { $0.safety == .system })
    }

    func testFilterProcessesBySearchText() {
        let processes = sampleProcesses()
        filterState.searchText = "kernel"
        filterState.debouncedSearchText = "kernel" // Simulate debounce complete

        let filtered = filterState.filter(processes)

        XCTAssertTrue(filtered.allSatisfy {
            $0.name.localizedCaseInsensitiveContains("kernel") ||
            $0.description.localizedCaseInsensitiveContains("kernel")
        })
    }

    func testFilterProcessesByCategoryAndSearch() {
        let processes = sampleProcesses()
        filterState.applyFilter(.user)
        filterState.searchText = "chrome"
        filterState.debouncedSearchText = "chrome"

        let filtered = filterState.filter(processes)

        XCTAssertTrue(filtered.allSatisfy {
            $0.safety == .user &&
            ($0.name.localizedCaseInsensitiveContains("chrome") ||
             $0.description.localizedCaseInsensitiveContains("chrome"))
        })
    }

    func testFilterProcessesByPort() {
        let processes = sampleProcesses()
        filterState.applyFilter(.port(8080))

        let filtered = filterState.filter(processes)

        XCTAssertTrue(filtered.allSatisfy { $0.ports.contains(8080) })
    }

    // MARK: - Sorting Tests

    func testSortOrderDefault() {
        XCTAssertEqual(filterState.sortOrder.count, 1)
        XCTAssertEqual(filterState.sortOrder.first?.keyPath, \LucidProcess.cpuUsage)
    }

    func testApplySortOrderUpdatesSortOrder() {
        let newSort = [KeyPathComparator(\LucidProcess.name, order: .forward)]
        filterState.applySortOrder(newSort)

        XCTAssertEqual(filterState.sortOrder.first?.keyPath, \LucidProcess.name)
    }

    // MARK: - Helpers

    private func sampleProcesses() -> [LucidProcess] {
        [
            LucidProcess(pid: 1, name: "kernel_task", description: "System kernel", cpuUsage: 10, memoryBytes: 100_000_000, safety: .system, exePath: "/kernel", ports: []),
            LucidProcess(pid: 2, name: "Chrome", description: "Browser", cpuUsage: 20, memoryBytes: 200_000_000, safety: .user, exePath: "/Apps/Chrome", ports: [8080]),
            LucidProcess(pid: 3, name: "UnknownApp", description: "Unknown", cpuUsage: 5, memoryBytes: 50_000_000, safety: .unknown, exePath: "/tmp/unknown", ports: [3000, 8080])
        ]
    }
}