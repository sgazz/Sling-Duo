#if GRAPHICS_PROFILE
import Foundation
import QuartzCore
import Darwin
import os

/// Opt-in measurement harness, excluded from ordinary Debug/Release builds.
@MainActor
final class GraphicsProfileSession {
    private let log = OSLog(subsystem: "Gazza.SlingDuo.GraphicsProfile", category: .pointsOfInterest)
    private var phase = ""
    private var start = CACurrentMediaTime()
    private var phaseUnixStart = 0.0
    private var cpuStart = 0.0
    private var frames: [Double] = []
    private var previousFrame: Double?
    private var maximumFootprint: UInt64 = 0
    private var rows = ["phase,wall_seconds,cpu_percent_one_core,footprint_mib,peak_sampled_footprint_mib,frames,median_frame_ms,p95_frame_ms,app_owned_texture_count,phase_start_unix_seconds,phase_start_monotonic_seconds"]

    func frame(_ time: TimeInterval) {
        guard !phase.isEmpty else { return }
        if let previousFrame { frames.append((time - previousFrame) * 1000) }
        previousFrame = time
        maximumFootprint = max(maximumFootprint, Self.footprint())
    }

    func begin(_ phase: String) {
        self.phase = phase
        start = CACurrentMediaTime()
        phaseUnixStart = Date().timeIntervalSince1970
        cpuStart = Self.cpuSeconds()
        previousFrame = nil
        frames.removeAll(keepingCapacity: true)
        maximumFootprint = Self.footprint()
        os_signpost(.event, log: log, name: "GraphicsPhase", "%{public}s", phase)
    }

    func end(textureCount: Int) {
        let wall = CACurrentMediaTime() - start
        let sorted = frames.sorted()
        func percentile(_ fraction: Double) -> Double {
            guard !sorted.isEmpty else { return 0 }
            return sorted[min(sorted.count - 1, Int(Double(sorted.count - 1) * fraction))]
        }
        let footprint = Self.footprint()
        let cpu = (Self.cpuSeconds() - cpuStart) / max(0.001, wall) * 100
        rows.append(String(format: "%@,%.3f,%.2f,%.3f,%.3f,%d,%.3f,%.3f,%d,%.6f,%.6f", phase, wall, cpu,
                           Double(footprint) / 1048576, Double(max(maximumFootprint, footprint)) / 1048576,
                           frames.count, percentile(0.5), percentile(0.95), textureCount, phaseUnixStart, start))
        phase = ""
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("graphics-profile.csv")
        try? (rows.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    private static func cpuSeconds() -> Double {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        return Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)
            + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
    }

    private static func footprint() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info.phys_footprint : 0
    }
}
#endif
