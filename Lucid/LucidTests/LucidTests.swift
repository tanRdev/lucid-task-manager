import XCTest
@testable import Lucid

final class LucidTests: XCTestCase {
    // MARK: - DarwinProcess Tests

    func testDarwinProcessCalculateCPUPercentageActivityMonitorStyle() throws {
        // One fully busy core for 1 second == 100% (not divided by core count)
        let result = DarwinProcess.calculateCPUPercentage(
            currentNanos: 1_000_000_000,
            previousNanos: 0,
            elapsedSeconds: 1.0
        )
        XCTAssertEqual(result, 100.0, accuracy: 0.01)

        // Two fully busy cores worth of work == 200%
        let resultMulti = DarwinProcess.calculateCPUPercentage(
            currentNanos: 2_000_000_000,
            previousNanos: 0,
            elapsedSeconds: 1.0
        )
        XCTAssertEqual(resultMulti, 200.0, accuracy: 0.01)

        // Zero elapsed
        XCTAssertEqual(
            DarwinProcess.calculateCPUPercentage(
                currentNanos: 1_000_000_000,
                previousNanos: 0,
                elapsedSeconds: 0
            ),
            0
        )

        // Negative delta
        XCTAssertEqual(
            DarwinProcess.calculateCPUPercentage(
                currentNanos: 0,
                previousNanos: 1_000_000_000,
                elapsedSeconds: 1.0
            ),
            0
        )
    }

    func testSystemCPUDividesOnceByCoreCount() throws {
        // Ten processes each at 100% on a 10-core machine => 100% system
        let system = DarwinProcess.calculateSystemCPUPercentage(
            processCPUPercentages: Array(repeating: 100.0, count: 10),
            coreCount: 10
        )
        XCTAssertEqual(system, 100.0, accuracy: 0.01)

        // Already-normalized mistake would divide again; ensure we do not.
        let half = DarwinProcess.calculateSystemCPUPercentage(
            processCPUPercentages: [100.0, 100.0, 100.0, 100.0, 100.0],
            coreCount: 10
        )
        XCTAssertEqual(half, 50.0, accuracy: 0.01)
    }

    func testDarwinErrorDescription() throws {
        let error = DarwinError.failedToKill(pid: 1234, description: "Operation not permitted")
        XCTAssertEqual(error.errorDescription, "Failed to kill process 1234: Operation not permitted")

        let protected = DarwinError.protected(pid: 1, name: "kernel_task")
        XCTAssertTrue(protected.errorDescription?.contains("protected") == true)
    }

    // MARK: - LucidProcess Tests

    private func makeProcess(
        pid: pid_t = 1234,
        startTime: UInt64 = 100,
        name: String = "Test",
        description: String = "Test Process",
        cpuUsage: Double = 0.5,
        memoryBytes: UInt64 = 100 * 1024 * 1024,
        origin: ProcessOrigin = .user,
        exePath: String = "/usr/bin/test",
        ports: [UInt16] = [],
        userID: uid_t = 501
    ) -> LucidProcess {
        LucidProcess(
            identity: ProcessIdentity(pid: pid, startTime: startTime),
            name: name,
            description: description,
            cpuUsage: cpuUsage,
            memoryBytes: memoryBytes,
            origin: origin,
            exePath: exePath,
            ports: ports,
            userID: userID
        )
    }

    func testLucidProcessMemoryFormattedMB() throws {
        let process = makeProcess(memoryBytes: 512 * 1024 * 1024)
        XCTAssertTrue(process.memoryFormatted.contains("MB"))
        XCTAssertTrue(process.memoryFormatted.contains("512"))
    }

    func testLucidProcessMemoryFormattedGB() throws {
        let process = makeProcess(memoryBytes: 2 * 1024 * 1024 * 1024)
        XCTAssertTrue(process.memoryFormatted.contains("GB"))
        XCTAssertTrue(process.memoryFormatted.contains("2"))
    }

    func testLucidProcessPortsFormatted() throws {
        XCTAssertEqual(makeProcess(ports: []).portsFormatted, "—")
        XCTAssertEqual(makeProcess(ports: [80, 443, 8080]).portsFormatted, "80, 443, 8080")
        XCTAssertEqual(LucidFormat.port(8265), "8265")
        XCTAssertNotEqual(LucidFormat.port(8265), "8,265")
    }

    func testLucidProcessIdentityIncludesStartTime() throws {
        let a = makeProcess(pid: 1234, startTime: 100)
        let b = makeProcess(pid: 1234, startTime: 200, name: "Other")
        XCTAssertNotEqual(a, b)
        XCTAssertNotEqual(a.id, b.id)

        let same = makeProcess(pid: 1234, startTime: 100, name: "Different")
        XCTAssertEqual(a, same)
    }

    func testProtectedOriginBlocksTermination() throws {
        XCTAssertTrue(ProcessOrigin.system.isProtected)
        XCTAssertFalse(ProcessOrigin.system.allowsTermination)
        XCTAssertTrue(ProcessOrigin.user.allowsTermination)
        XCTAssertTrue(ProcessOrigin.unknown.allowsTermination)
    }

    func testOriginLabels() throws {
        XCTAssertEqual(ProcessOrigin.system.label, "System")
        XCTAssertEqual(ProcessOrigin.user.label, "User")
        XCTAssertEqual(ProcessOrigin.unknown.label, "Unknown")
    }

    func testWeakDaemonHeuristicIsUnknown() throws {
        let result = ProcessDictionary.smartLookup(
            name: "somedaemonthingd",
            path: "/tmp/somedaemonthingd",
            nsAppName: nil
        )
        XCTAssertEqual(result.1, .unknown)
    }

    func testApplePathIsSystem() throws {
        let result = ProcessDictionary.smartLookup(
            name: "customd",
            path: "/usr/libexec/customd",
            nsAppName: nil
        )
        XCTAssertEqual(result.1, .system)
    }

    // MARK: - Kill Path Tests

    func testClassifyKillTargetsBlocksProtectedSystem() throws {
        let protected = makeProcess(origin: .system)
        let result = ProcessMonitor.classifyKillTargets([protected], confirmedRisky: true)

        XCTAssertTrue(result.allowed.isEmpty)
        XCTAssertTrue(result.risky.isEmpty)
        XCTAssertEqual(result.errors.count, 1)
        XCTAssertTrue(result.errors[0].contains("protected system process"))
    }

    func testClassifyKillTargetsUnknownOriginRequiresConfirmation() throws {
        let unknown = makeProcess(origin: .unknown, userID: geteuid())

        let unconfirmed = ProcessMonitor.classifyKillTargets([unknown], confirmedRisky: false)
        XCTAssertTrue(unconfirmed.allowed.isEmpty)
        XCTAssertEqual(unconfirmed.risky.count, 1)
        XCTAssertTrue(unconfirmed.errors[0].contains("confirmation required"))

        let confirmed = ProcessMonitor.classifyKillTargets([unknown], confirmedRisky: true)
        XCTAssertEqual(confirmed.allowed.count, 1)
        XCTAssertTrue(confirmed.errors.isEmpty)
    }

    func testClassifyKillTargetsForeignUserRequiresConfirmation() throws {
        let foreign = makeProcess(origin: .user, userID: geteuid() + 1)

        let unconfirmed = ProcessMonitor.classifyKillTargets([foreign], confirmedRisky: false)
        XCTAssertTrue(unconfirmed.allowed.isEmpty)
        XCTAssertEqual(unconfirmed.risky.count, 1)

        let confirmed = ProcessMonitor.classifyKillTargets([foreign], confirmedRisky: true)
        XCTAssertEqual(confirmed.allowed.count, 1)
    }

    @MainActor
    func testKillProcessesRefusesProtectedWithoutSignaling() async throws {
        let monitor = ProcessMonitor()
        let protected = makeProcess(origin: .system)

        let result = await monitor.killProcesses([protected])

        guard case .failure(let error) = result else {
            return XCTFail("Expected protected kill to fail")
        }
        XCTAssertEqual(error.errors.count, 1)
        XCTAssertTrue(error.errors[0].contains("protected system process"))
        XCTAssertTrue(error.riskyTargets.isEmpty)
        XCTAssertTrue(error.survivors.isEmpty)
    }

    @MainActor
    func testKillProcessesTerminatesSpawnedProcess() async throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sleep")
        task.arguments = ["30"]
        try task.run()
        defer { task.terminate() }

        let pid = task.processIdentifier
        let info = DarwinProcess.getProcessInfo(pid: pid)
        XCTAssertNotNil(info)

        let target = LucidProcess(
            identity: ProcessIdentity(pid: pid, startTime: info?.startTime ?? 0),
            name: "sleep",
            description: "Spawned test sleeper",
            cpuUsage: 0,
            memoryBytes: 0,
            origin: .user,
            exePath: "/bin/sleep",
            ports: [],
            userID: geteuid()
        )

        let monitor = ProcessMonitor()
        let result = await monitor.killProcesses([target])

        guard case .success = result else {
            return XCTFail("Expected kill to succeed, got \(result)")
        }
        XCTAssertFalse(DarwinProcess.isAlive(pid: pid))
    }

    @MainActor
    func testKillProcessesFailsForExitedProcess() async throws {
        let monitor = ProcessMonitor()
        // Unused pid: identity re-check must fail before any signal is sent.
        let stale = makeProcess(pid: 999_999, userID: geteuid())

        let result = await monitor.killProcesses([stale])

        guard case .failure(let error) = result else {
            return XCTFail("Expected kill of stale pid to fail")
        }
        XCTAssertTrue(error.errors[0].contains("no longer matches"))
    }

    func testKillProcessPermissionDenied() throws {
        try XCTSkipIf(geteuid() == 0, "root can signal launchd — EPERM is unreachable")

        let result = DarwinProcess.killProcess(pid: 1)

        guard case .failure(let error) = result else {
            return XCTFail("Expected signaling launchd to be denied")
        }
        guard case .failedToKill(let pid, let description) = error else {
            return XCTFail("Expected failedToKill, got \(error)")
        }
        XCTAssertEqual(pid, 1)
        XCTAssertFalse(description.isEmpty)
    }

    func testIsAliveReportsExitedPidAsDead() throws {
        XCTAssertFalse(DarwinProcess.isAlive(pid: 999_999))
        XCTAssertTrue(DarwinProcess.isAlive(pid: getpid()))
    }
}
