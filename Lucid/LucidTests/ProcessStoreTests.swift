import XCTest
@testable import Lucid

@MainActor
final class ProcessStoreTests: XCTestCase {
    var store: ProcessStore!

    override func setUp() {
        super.setUp()
        store = ProcessStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialProcessesIsEmpty() {
        XCTAssertTrue(store.processes.isEmpty)
    }

    func testInitialActivePortsIsEmpty() {
        XCTAssertTrue(store.activePorts.isEmpty)
    }

    func testInitialPortProcessMapIsEmpty() {
        XCTAssertTrue(store.portProcessMap.isEmpty)
    }

    // MARK: - Update Processes Tests

    func testUpdateProcessesSetsProcesses() {
        let processes = sampleProcesses()
        store.updateProcesses(processes)

        XCTAssertEqual(store.processes.count, processes.count)
    }

    func testUpdateProcessesSortsProcesses() {
        let processes = [
            LucidProcess(pid: 1, name: "B", description: "B", cpuUsage: 5, memoryBytes: 100, safety: .user, exePath: "/b", ports: []),
            LucidProcess(pid: 2, name: "A", description: "A", cpuUsage: 10, memoryBytes: 200, safety: .system, exePath: "/a", ports: [])
        ]
        store.updateProcesses(processes)

        // Should be sorted by name (default Comparable implementation)
        XCTAssertEqual(store.processes.first?.name, "A")
        XCTAssertEqual(store.processes.last?.name, "B")
    }

    func testUpdateProcessesCalculatesActivePorts() {
        let processes = [
            LucidProcess(pid: 1, name: "A", description: "A", cpuUsage: 5, memoryBytes: 100, safety: .user, exePath: "/a", ports: [8080]),
            LucidProcess(pid: 2, name: "B", description: "B", cpuUsage: 10, memoryBytes: 200, safety: .system, exePath: "/b", ports: [8080, 3000])
        ]
        store.updateProcesses(processes)

        XCTAssertEqual(store.activePorts.sorted(), [3000, 8080])
    }

    func testUpdateProcessesBuildsPortProcessMap() {
        let processes = [
            LucidProcess(pid: 1, name: "A", description: "A", cpuUsage: 5, memoryBytes: 100, safety: .user, exePath: "/a", ports: [8080]),
            LucidProcess(pid: 2, name: "B", description: "B", cpuUsage: 10, memoryBytes: 200, safety: .system, exePath: "/b", ports: [8080])
        ]
        store.updateProcesses(processes)

        XCTAssertEqual(store.portProcessMap[8080]?.count, 2)
        XCTAssertEqual(store.portProcessMap[8080]?.sorted(), [1, 2])
    }

    func testUpdateProcessesCalculatesFilterCounts() {
        let processes = [
            LucidProcess(pid: 1, name: "System", description: "S", cpuUsage: 5, memoryBytes: 100, safety: .system, exePath: "/s", ports: []),
            LucidProcess(pid: 2, name: "User", description: "U", cpuUsage: 10, memoryBytes: 200, safety: .user, exePath: "/u", ports: []),
            LucidProcess(pid: 3, name: "Unknown", description: "U", cpuUsage: 15, memoryBytes: 300, safety: .unknown, exePath: "/un", ports: [])
        ]
        store.updateProcesses(processes)

        XCTAssertEqual(store.filterCounts.total, 3)
        XCTAssertEqual(store.filterCounts.system, 1)
        XCTAssertEqual(store.filterCounts.user, 1)
        XCTAssertEqual(store.filterCounts.unknown, 1)
    }

    // MARK: - Process Lookup Tests

    func testProcessForPidReturnsCorrectProcess() {
        let processes = sampleProcesses()
        store.updateProcesses(processes)

        let found = store.process(for: 1)

        XCTAssertEqual(found?.name, "kernel_task")
    }

    func testProcessForPidReturnsNilForInvalidPid() {
        let processes = sampleProcesses()
        store.updateProcesses(processes)

        let found = store.process(for: 999)

        XCTAssertNil(found)
    }

    func testProcessesForPortReturnsCorrectPids() {
        let processes = [
            LucidProcess(pid: 1, name: "A", description: "A", cpuUsage: 5, memoryBytes: 100, safety: .user, exePath: "/a", ports: [8080]),
            LucidProcess(pid: 2, name: "B", description: "B", cpuUsage: 10, memoryBytes: 200, safety: .system, exePath: "/b", ports: [8080])
        ]
        store.updateProcesses(processes)

        let pids = store.processes(for: 8080)

        XCTAssertEqual(pids.sorted(), [1, 2])
    }

    func testProcessesForPortReturnsEmptyForUnusedPort() {
        let processes = sampleProcesses()
        store.updateProcesses(processes)

        let pids = store.processes(for: 9999)

        XCTAssertTrue(pids.isEmpty)
    }

    // MARK: - Remove Process Tests

    func testRemoveProcessRemovesFromProcesses() {
        let processes = sampleProcesses()
        store.updateProcesses(processes)

        let processToRemove = processes[0]
        store.removeProcess(processToRemove)

        XCTAssertEqual(store.processes.count, 2)
        XCTAssertNil(store.process(for: processToRemove.pid))
    }

    func testRemoveProcessUpdatesPortMap() {
        let processes = [
            LucidProcess(pid: 1, name: "A", description: "A", cpuUsage: 5, memoryBytes: 100, safety: .user, exePath: "/a", ports: [8080]),
            LucidProcess(pid: 2, name: "B", description: "B", cpuUsage: 10, memoryBytes: 200, safety: .system, exePath: "/b", ports: [8080])
        ]
        store.updateProcesses(processes)
        store.removeProcess(processes[0])

        XCTAssertEqual(store.portProcessMap[8080]?.count, 1)
        XCTAssertEqual(store.portProcessMap[8080]?.first, 2)
    }

    // MARK: - Helpers

    private func sampleProcesses() -> [LucidProcess] {
        [
            LucidProcess(pid: 1, name: "kernel_task", description: "System kernel", cpuUsage: 10, memoryBytes: 100_000_000, safety: .system, exePath: "/kernel", ports: []),
            LucidProcess(pid: 2, name: "Chrome", description: "Browser", cpuUsage: 20, memoryBytes: 200_000_000, safety: .user, exePath: "/Apps/Chrome", ports: [8080]),
            LucidProcess(pid: 3, name: "UnknownApp", description: "Unknown", cpuUsage: 5, memoryBytes: 50_000_000, safety: .unknown, exePath: "/tmp/unknown", ports: [3000])
        ]
    }
}