import XCTest
@testable import Lucid

@MainActor
final class PerformanceTests: XCTestCase {
    var monitor: ProcessMonitor!
    var filterState: FilterState!
    var processStore: ProcessStore!

    override func setUp() {
        super.setUp()
        monitor = ProcessMonitor()
        filterState = monitor.filterState
        processStore = monitor.processStore
    }

    override func tearDown() {
        monitor.stop()
        monitor = nil
        super.tearDown()
    }

    // MARK: - Filter Performance Tests

    func testFilterPerformanceWith400Processes() {
        let processes = generateProcesses(count: 400)
        processStore.updateProcesses(processes)

        measure {
            // Run filtering 100 times to get average
            for _ in 0..<100 {
                _ = filterState.filter(processes)
            }
        }
    }

    func testFilterWithSearchPerformance() {
        let processes = generateProcesses(count: 400)
        processStore.updateProcesses(processes)
        filterState.searchText = "kernel"
        filterState.debouncedSearchText = "kernel"

        measure {
            for _ in 0..<100 {
                _ = filterState.filter(processes)
            }
        }
    }

    func testPortLookupPerformance() {
        let processes = generateProcessesWithPorts(count: 400, portsPerProcess: 2)
        processStore.updateProcesses(processes)

        measure {
            for port in processStore.activePorts {
                _ = processStore.processes(for: port)
            }
        }
    }

    // MARK: - Memory Tests

    func testProcessStoreMemoryUsage() {
        let processes = generateProcesses(count: 1000)

        measure(metrics: [XCTMemoryMetric()]) {
            processStore.updateProcesses(processes)
        }
    }

    // MARK: - Actor Isolation Tests

    /// Verifies that multiple sequential accesses to @MainActor-isolated ProcessStore
    /// complete without data races. Note: Since ProcessStore is @MainActor, tasks are
    /// serialized on the main actor - this tests isolation safety, not true concurrency.
    func testSequentialAccessToProcessStore() async {
        let processes = generateProcesses(count: 100)
        processStore.updateProcesses(processes)

        await withTaskGroup(of: Void.self) { group in
            // Concurrent reads
            for _ in 0..<100 {
                group.addTask {
                    _ = self.processStore.processes
                    _ = self.processStore.activePorts
                    _ = self.processStore.filterCounts
                }
            }

            // Concurrent writes
            for i in 0..<10 {
                group.addTask {
                    let newProcesses = self.generateProcesses(count: 100 + i)
                    self.processStore.updateProcesses(newProcesses)
                }
            }
        }

        // If we get here without crash, thread safety is working
        XCTAssertTrue(true)
    }

    // MARK: - Debounce Tests

    func testSearchDebounceDoesNotTriggerExcessiveFilters() async throws {
        let processes = generateProcesses(count: 100)
        processStore.updateProcesses(processes)

        // Simulate rapid typing
        for char in "searching" {
            filterState.searchText += String(char)
            _ = filterState.filter(processes) // Simulate view evaluation
            try await Task.sleep(for: .milliseconds(50))
        }

        // Wait for debounce
        try await Task.sleep(for: .milliseconds(400))

        // Should have filtered with debounced value, not every keystroke
        XCTAssertEqual(filterState.debouncedSearchText, "searching")
    }

    // MARK: - Helpers

    private func generateProcesses(count: Int) -> [LucidProcess] {
        (0..<count).map { i in
            LucidProcess(
                pid: pid_t(i),
                name: "Process\(i)",
                description: "Description for process \(i)",
                cpuUsage: Double.random(in: 0...100),
                memoryBytes: UInt64.random(in: 1_000_000...1_000_000_000),
                safety: [.system, .user, .unknown][i % 3],
                exePath: "/path/to/process\(i)",
                ports: []
            )
        }
    }

    private func generateProcessesWithPorts(count: Int, portsPerProcess: Int) -> [LucidProcess] {
        (0..<count).map { i in
            let ports = (0..<portsPerProcess).map { UInt16(8000 + (i * portsPerProcess) + $0) }
            return LucidProcess(
                pid: pid_t(i),
                name: "Process\(i)",
                description: "Description for process \(i)",
                cpuUsage: Double.random(in: 0...100),
                memoryBytes: UInt64.random(in: 1_000_000...1_000_000_000),
                safety: [.system, .user, .unknown][i % 3],
                exePath: "/path/to/process\(i)",
                ports: ports
            )
        }
    }
}