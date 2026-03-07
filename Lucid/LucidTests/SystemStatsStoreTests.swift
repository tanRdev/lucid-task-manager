import XCTest
@testable import Lucid

@MainActor
final class SystemStatsStoreTests: XCTestCase {
    var store: SystemStatsStore!

    override func setUp() {
        super.setUp()
        store = SystemStatsStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialStatsAreZero() {
        XCTAssertEqual(store.stats.cpuUsage, 0)
        XCTAssertEqual(store.stats.memoryUsage, 0)
    }

    func testInitialHistoryIsEmpty() {
        XCTAssertTrue(store.cpuHistory.isEmpty)
        XCTAssertTrue(store.memoryHistory.isEmpty)
    }

    // MARK: - Update Stats Tests

    func testUpdateStatsUpdatesCurrentStats() {
        let newStats = SystemStats(
            cpuUsage: 25.5,
            memoryUsage: 60.0,
            memoryBytes: 8_000_000_000,
            totalMemoryBytes: 16_000_000_000,
            timestamp: Date()
        )

        store.updateStats(newStats)

        XCTAssertEqual(store.stats.cpuUsage, 25.5)
        XCTAssertEqual(store.stats.memoryUsage, 60.0)
    }

    func testUpdateStatsAddsToHistory() {
        let stats1 = SystemStats(cpuUsage: 10, memoryUsage: 20, memoryBytes: 4_000_000_000, totalMemoryBytes: 16_000_000_000, timestamp: Date())
        let stats2 = SystemStats(cpuUsage: 20, memoryUsage: 30, memoryBytes: 5_000_000_000, totalMemoryBytes: 16_000_000_000, timestamp: Date())

        store.updateStats(stats1)
        store.updateStats(stats2)

        XCTAssertEqual(store.cpuHistory, [10, 20])
        XCTAssertEqual(store.memoryHistory, [20, 30])
    }

    func testHistoryLimitedToTwelveEntries() {
        for i in 0..<15 {
            let stats = SystemStats(
                cpuUsage: Double(i),
                memoryUsage: Double(i * 2),
                memoryBytes: UInt64(i) * 1_000_000,
                totalMemoryBytes: 16_000_000_000,
                timestamp: Date()
            )
            store.updateStats(stats)
        }

        XCTAssertEqual(store.cpuHistory.count, 12)
        XCTAssertEqual(store.memoryHistory.count, 12)
        XCTAssertEqual(store.cpuHistory.first, 3) // First 3 evicted
        XCTAssertEqual(store.cpuHistory.last, 14)
    }

    func testUpdateStatsUpdatesTimestamp() {
        let before = Date()
        let newStats = SystemStats(
            cpuUsage: 10,
            memoryUsage: 20,
            memoryBytes: 4_000_000_000,
            totalMemoryBytes: 16_000_000_000,
            timestamp: Date()
        )
        store.updateStats(newStats)
        let after = Date()

        XCTAssertGreaterThanOrEqual(store.lastUpdate, before)
        XCTAssertLessThanOrEqual(store.lastUpdate, after)
    }

    // MARK: - Calculated Stats Tests

    func testAverageCPUCalculatesCorrectly() {
        let stats = [
            SystemStats(cpuUsage: 10, memoryUsage: 20, memoryBytes: 4_000_000_000, totalMemoryBytes: 16_000_000_000, timestamp: Date()),
            SystemStats(cpuUsage: 20, memoryUsage: 30, memoryBytes: 5_000_000_000, totalMemoryBytes: 16_000_000_000, timestamp: Date()),
            SystemStats(cpuUsage: 30, memoryUsage: 40, memoryBytes: 6_000_000_000, totalMemoryBytes: 16_000_000_000, timestamp: Date())
        ]

        for stat in stats {
            store.updateStats(stat)
        }

        XCTAssertEqual(store.averageCPU, 20.0, accuracy: 0.01)
    }

    func testPeakMemoryCalculatesCorrectly() {
        let stats = [
            SystemStats(cpuUsage: 10, memoryUsage: 20, memoryBytes: 4_000_000_000, totalMemoryBytes: 16_000_000_000, timestamp: Date()),
            SystemStats(cpuUsage: 20, memoryUsage: 50, memoryBytes: 8_000_000_000, totalMemoryBytes: 16_000_000_000, timestamp: Date()),
            SystemStats(cpuUsage: 30, memoryUsage: 30, memoryBytes: 5_000_000_000, totalMemoryBytes: 16_000_000_000, timestamp: Date())
        ]

        for stat in stats {
            store.updateStats(stat)
        }

        XCTAssertEqual(store.peakMemoryUsage, 50.0, accuracy: 0.01)
    }

    // MARK: - Formatted Values Tests

    func testFormattedCPU() {
        let stats = SystemStats(
            cpuUsage: 25.5,
            memoryUsage: 60.0,
            memoryBytes: 8_000_000_000,
            totalMemoryBytes: 16_000_000_000,
            timestamp: Date()
        )
        store.updateStats(stats)

        XCTAssertEqual(store.formattedCPU, "25.5%")
    }

    func testFormattedMemory() {
        let stats = SystemStats(
            cpuUsage: 25.5,
            memoryUsage: 60.0,
            memoryBytes: 8_000_000_000,
            totalMemoryBytes: 16_000_000_000,
            timestamp: Date()
        )
        store.updateStats(stats)

        XCTAssertEqual(store.formattedMemory, "60.0%")
    }
}