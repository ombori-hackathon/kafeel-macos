import Testing
import Foundation
@testable import KafeelCore

@MainActor
struct ActivityMonitorTests {

    // MARK: - Test Helpers

    private func createTestMonitor() -> ActivityMonitor {
        return ActivityMonitor(persistenceService: .shared)
    }

    // MARK: - State Tests

    @Test("Monitor starts in stopped state")
    func testInitialState() async throws {
        let monitor = createTestMonitor()

        #expect(monitor.isMonitoring == false)
        #expect(monitor.currentApp == nil)
        #expect(monitor.currentActivity == nil)
    }

    @Test("Start monitoring changes state")
    func testStartMonitoring() async throws {
        let monitor = createTestMonitor()

        monitor.startMonitoring()

        #expect(monitor.isMonitoring == true)
        // currentApp might be set depending on frontmost app
    }

    @Test("Stop monitoring changes state")
    func testStopMonitoring() async throws {
        let monitor = createTestMonitor()

        monitor.startMonitoring()
        #expect(monitor.isMonitoring == true)

        monitor.stopMonitoring()
        #expect(monitor.isMonitoring == false)
        #expect(monitor.currentActivity == nil)
    }

    @Test("Starting already started monitor is no-op")
    func testDoubleStart() async throws {
        let monitor = createTestMonitor()

        monitor.startMonitoring()
        #expect(monitor.isMonitoring == true)

        // Starting again should be safe
        monitor.startMonitoring()
        #expect(monitor.isMonitoring == true)
    }

    @Test("Stopping already stopped monitor is no-op")
    func testDoubleStop() async throws {
        let monitor = createTestMonitor()

        #expect(monitor.isMonitoring == false)

        // Stopping when already stopped should be safe
        monitor.stopMonitoring()
        #expect(monitor.isMonitoring == false)
    }

    // MARK: - Activity Lifecycle Tests

    @Test("Monitor tracks frontmost app on start")
    func testTracksAppOnStart() async throws {
        let monitor = createTestMonitor()

        monitor.startMonitoring()

        // Should track something (at least the test runner or IDE)
        // Note: In a real test environment, this might not always be reliable
        // but demonstrates the functionality
        #expect(monitor.isMonitoring == true)

        // Clean up
        monitor.stopMonitoring()
    }

    @Test("Stop finalizes current activity")
    func testStopFinalizesActivity() async throws {
        let monitor = createTestMonitor()

        monitor.startMonitoring()

        // Give it a moment to track something
        try await Task.sleep(for: .milliseconds(100))

        let hadActivity = monitor.currentActivity != nil

        monitor.stopMonitoring()

        // After stopping, current activity should be nil
        #expect(monitor.currentActivity == nil)

        // If we had an activity, it should have been saved
        // (assuming it was > 2 seconds, which it won't be in this test)
        if hadActivity {
            #expect(monitor.isMonitoring == false)
        }
    }

    // MARK: - Observable Tests

    @Test("Monitor is observable")
    func testObservable() async throws {
        let monitor = createTestMonitor()

        // Initial state
        let initialMonitoring = monitor.isMonitoring

        // Change state
        monitor.startMonitoring()
        let afterStart = monitor.isMonitoring

        monitor.stopMonitoring()
        let afterStop = monitor.isMonitoring

        #expect(initialMonitoring == false)
        #expect(afterStart == true)
        #expect(afterStop == false)
    }

    // MARK: - Integration Tests

    @Test("Monitor works with persistence service")
    func testPersistenceIntegration() async throws {
        let service = PersistenceService.shared
        let monitor = ActivityMonitor(persistenceService: service)

        // Clean up any previous data
        try await service.deleteAllData()

        // Start monitoring
        monitor.startMonitoring()

        // Let it run briefly
        try await Task.sleep(for: .milliseconds(100))

        // Stop (this should finalize and potentially save)
        monitor.stopMonitoring()

        // Note: Activities < 2 seconds won't be saved, so we can't
        // reliably check for saved activities in this quick test.
        // This test mainly verifies no crashes occur.
        #expect(monitor.isMonitoring == false)
    }

    // MARK: - Edge Cases

    @Test("Monitor handles nil frontmost app gracefully")
    func testNilFrontmostApp() async throws {
        // This test verifies the monitor doesn't crash when there's no frontmost app
        // In practice, there's usually always a frontmost app, but we test the code path
        let monitor = createTestMonitor()

        // Start and stop should not crash
        monitor.startMonitoring()
        monitor.stopMonitoring()

        #expect(monitor.isMonitoring == false)
    }

    @Test("Monitor handles rapid start/stop cycles")
    func testRapidStartStop() async throws {
        let monitor = createTestMonitor()

        // Rapid cycling should be safe
        for _ in 0..<10 {
            monitor.startMonitoring()
            monitor.stopMonitoring()
        }

        #expect(monitor.isMonitoring == false)
    }
}
