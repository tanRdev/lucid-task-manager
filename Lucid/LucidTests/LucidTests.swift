import XCTest
@testable import Lucid

final class LucidTests: XCTestCase {
    // MARK: - DarwinProcess Tests

    func testDarwinProcessCalculateCPUPercentage() throws {
        // Test basic calculation
        let result = DarwinProcess.calculateCPUPercentage(
            currentNanos: 1_000_000_000,  // 1 second
            previousNanos: 0,
            elapsedSeconds: 1.0,
            coreCount: 1
        )
        XCTAssertEqual(result, 100.0, accuracy: 0.01, "1 second of CPU on 1 core over 1 second should be 100%")

        // Test multi-core
        let resultMultiCore = DarwinProcess.calculateCPUPercentage(
            currentNanos: 1_000_000_000,  // 1 second
            previousNanos: 0,
            elapsedSeconds: 1.0,
            coreCount: 8
        )
        XCTAssertEqual(resultMultiCore, 12.5, accuracy: 0.01, "1 second of CPU on 8 cores over 1 second should be 12.5%")

        // Test zero division protection
        let resultZeroTime = DarwinProcess.calculateCPUPercentage(
            currentNanos: 1_000_000_000,
            previousNanos: 0,
            elapsedSeconds: 0,
            coreCount: 1
        )
        XCTAssertEqual(resultZeroTime, 0, "Should return 0 when elapsedSeconds is 0")

        // Test negative delta protection (current < previous)
        let resultNegativeDelta = DarwinProcess.calculateCPUPercentage(
            currentNanos: 0,
            previousNanos: 1_000_000_000,
            elapsedSeconds: 1.0,
            coreCount: 1
        )
        XCTAssertEqual(resultNegativeDelta, 0, "Should return 0 when current < previous")

        // Test cap at 100%
        let resultOver100 = DarwinProcess.calculateCPUPercentage(
            currentNanos: 2_000_000_000,  // 2 seconds
            previousNanos: 0,
            elapsedSeconds: 1.0,
            coreCount: 1
        )
        XCTAssertEqual(resultOver100, 100.0, "Should cap at 100%")
    }

    func testDarwinErrorDescription() throws {
        let error = DarwinError.failedToKill(pid: 1234, description: "Operation not permitted")
        XCTAssertEqual(error.errorDescription, "Failed to kill process 1234: Operation not permitted")
    }

    // MARK: - LucidProcess Tests

    func testLucidProcessMemoryFormattedMB() throws {
        let process = LucidProcess(
            pid: 1234,
            name: "Test",
            description: "Test Process",
            cpuUsage: 0.5,
            memoryBytes: 512 * 1024 * 1024,  // 512 MB
            safety: .user,
            exePath: "/usr/bin/test",
            ports: []
        )
        XCTAssertTrue(process.memoryFormatted.contains("MB"), "512 MB should show as MB")
        XCTAssertTrue(process.memoryFormatted.contains("512"), "Should contain 512")
    }

    func testLucidProcessMemoryFormattedGB() throws {
        let process = LucidProcess(
            pid: 1234,
            name: "Test",
            description: "Test Process",
            cpuUsage: 0.5,
            memoryBytes: 2 * 1024 * 1024 * 1024,  // 2 GB
            safety: .user,
            exePath: "/usr/bin/test",
            ports: []
        )
        XCTAssertTrue(process.memoryFormatted.contains("GB"), "2 GB should show as GB")
        XCTAssertTrue(process.memoryFormatted.contains("2"), "Should contain 2")
    }

    func testLucidProcessMemoryFormattedBoundary() throws {
        // Test 1023 MB (should still be MB)
        let mbProcess = LucidProcess(
            pid: 1234,
            name: "Test",
            description: "Test Process",
            cpuUsage: 0.5,
            memoryBytes: 1023 * 1024 * 1024,
            safety: .user,
            exePath: "/usr/bin/test",
            ports: []
        )
        XCTAssertTrue(mbProcess.memoryFormatted.contains("MB"), "1023 MB should still show as MB")

        // Test 1024 MB (should become GB)
        let gbProcess = LucidProcess(
            pid: 1234,
            name: "Test",
            description: "Test Process",
            cpuUsage: 0.5,
            memoryBytes: 1024 * 1024 * 1024,
            safety: .user,
            exePath: "/usr/bin/test",
            ports: []
        )
        XCTAssertTrue(gbProcess.memoryFormatted.contains("GB"), "1024 MB should show as GB")
    }

    func testLucidProcessCpuFormatted() throws {
        let process = LucidProcess(
            pid: 1234,
            name: "Test",
            description: "Test Process",
            cpuUsage: 42.567,
            memoryBytes: 100 * 1024 * 1024,
            safety: .user,
            exePath: "/usr/bin/test",
            ports: []
        )
        XCTAssertTrue(process.cpuFormatted.contains("42.6"), "Should round to 1 decimal")
        XCTAssertTrue(process.cpuFormatted.contains("%"), "Should contain percent sign")
    }

    func testLucidProcessPortsFormattedEmpty() throws {
        let process = LucidProcess(
            pid: 1234,
            name: "Test",
            description: "Test Process",
            cpuUsage: 0.5,
            memoryBytes: 100 * 1024 * 1024,
            safety: .user,
            exePath: "/usr/bin/test",
            ports: []
        )
        XCTAssertEqual(process.portsFormatted, "-", "Empty ports should show as dash")
    }

    func testLucidProcessPortsFormattedMultiple() throws {
        let process = LucidProcess(
            pid: 1234,
            name: "Test",
            description: "Test Process",
            cpuUsage: 0.5,
            memoryBytes: 100 * 1024 * 1024,
            safety: .user,
            exePath: "/usr/bin/test",
            ports: [80, 443, 8080]
        )
        XCTAssertEqual(process.portsFormatted, "80, 443, 8080", "Should format ports as comma-separated")
    }

    func testLucidProcessEquality() throws {
        let process1 = LucidProcess(
            pid: 1234,
            name: "Test",
            description: "Test Process",
            cpuUsage: 0.5,
            memoryBytes: 100 * 1024 * 1024,
            safety: .user,
            exePath: "/usr/bin/test",
            ports: []
        )

        let process2 = LucidProcess(
            pid: 1234,
            name: "Different Name",
            description: "Different Description",
            cpuUsage: 99.9,
            memoryBytes: 999 * 1024 * 1024,
            safety: .system,
            exePath: "/different/path",
            ports: [8080]
        )

        XCTAssertEqual(process1, process2, "Processes with same PID should be equal")
    }

    func testLucidProcessComparison() throws {
        let processA = LucidProcess(
            pid: 2,
            name: "AAA",
            description: "Process A",
            cpuUsage: 0.5,
            memoryBytes: 100 * 1024 * 1024,
            safety: .user,
            exePath: "/usr/bin/aaa",
            ports: []
        )

        let processB = LucidProcess(
            pid: 1,
            name: "ZZZ",
            description: "Process Z",
            cpuUsage: 0.5,
            memoryBytes: 100 * 1024 * 1024,
            safety: .user,
            exePath: "/usr/bin/zzz",
            ports: []
        )

        XCTAssertTrue(processA < processB, "AAA should be less than ZZZ")
    }

    func testLucidProcessHashable() throws {
        let process1 = LucidProcess(
            pid: 1234,
            name: "Test",
            description: "Test Process",
            cpuUsage: 0.5,
            memoryBytes: 100 * 1024 * 1024,
            safety: .user,
            exePath: "/usr/bin/test",
            ports: []
        )

        let process2 = LucidProcess(
            pid: 1234,
            name: "Different",
            description: "Different",
            cpuUsage: 99.9,
            memoryBytes: 999 * 1024 * 1024,
            safety: .system,
            exePath: "/different",
            ports: [8080]
        )

        let set: Set<LucidProcess> = [process1, process2]
        XCTAssertEqual(set.count, 1, "Processes with same PID should hash to same value in a Set")
    }

    func testLucidProcessIdentifiable() throws {
        let process = LucidProcess(
            pid: 1234,
            name: "Test",
            description: "Test Process",
            cpuUsage: 0.5,
            memoryBytes: 100 * 1024 * 1024,
            safety: .user,
            exePath: "/usr/bin/test",
            ports: []
        )

        XCTAssertEqual(process.id, 1234, "ID should be the PID")
    }

    // MARK: - Safety Tests

    func testSafetyLabels() throws {
        XCTAssertEqual(Safety.system.label, "System")
        XCTAssertEqual(Safety.user.label, "User")
        XCTAssertEqual(Safety.unknown.label, "Unknown")
    }

    func testSafetySystemImages() throws {
        XCTAssertEqual(Safety.system.systemImage, "gearshape.fill")
        XCTAssertEqual(Safety.user.systemImage, "person.fill")
        XCTAssertEqual(Safety.unknown.systemImage, "questionmark.circle.fill")
    }

    func testSafetyColorsExist() throws {
        // Just verify that colors exist - SwiftUI Color doesn't expose component values
        XCTAssertNotNil(Safety.system.color)
        XCTAssertNotNil(Safety.user.color)
        XCTAssertNotNil(Safety.unknown.color)
    }
}
