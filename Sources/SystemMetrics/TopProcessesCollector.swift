import AppKit
import Darwin
import Foundation
import PulseMacDomain

public final class TopProcessesCollector: TopProcessesProviding, ProcessResourcesProviding {
  private let logicalCpuCount: Double
  private struct CpuSample {
    let cpuTimeNs: UInt64
    let timestampNs: UInt64
    let diskReadBytes: UInt64
    let diskWriteBytes: UInt64
  }

  private struct DiskRateSample {
    let readBytesPerSec: Double
    let writeBytesPerSec: Double
    let timestampNs: UInt64
  }

  private struct ProcessRusageSnapshot {
    let cpuTimeNs: UInt64
    let memoryBytes: UInt64
    let diskReadBytes: UInt64
    let diskWriteBytes: UInt64
  }

  private struct ProcessAppInfo {
    let name: String
    let bundleId: String
    let bundlePath: String
  }

  private var lastSamples: [Int32: CpuSample] = [:]
  private var lastDiskRates: [Int32: DiskRateSample] = [:]
  private let diskRateRetentionNs: UInt64 = 2_000_000_000

  public init() {
    let count = ProcessInfo.processInfo.processorCount
    logicalCpuCount = max(Double(count), 1)
  }

  public func read(limit: Int) -> TopProcessesSnapshot {
    let now = DispatchTime.now().uptimeNanoseconds
    let pids = listPids()
    var nextSamples: [Int32: CpuSample] = [:]
    var processes: [ProcessSnapshot] = []

    for pid in pids {
      guard let rusage = readRusage(pid: pid) else { continue }
      guard let info = readBSDInfo(pid: pid), !info.name.isEmpty else { continue }

      let cpuTime = rusage.cpuTimeNs
      let memoryBytes = rusage.memoryBytes
      let cpuPercent = normalizeCpuPercent(computeCpuPercent(pid: pid, cpuTimeNs: cpuTime, nowNs: now))

      nextSamples[pid] = CpuSample(
        cpuTimeNs: cpuTime,
        timestampNs: now,
        diskReadBytes: rusage.diskReadBytes,
        diskWriteBytes: rusage.diskWriteBytes
      )
      processes.append(ProcessSnapshot(pid: pid, name: info.name, cpuPercent: cpuPercent, memoryBytes: memoryBytes))
    }

    lastSamples = nextSamples
    lastDiskRates = lastDiskRates.filter { nextSamples[$0.key] != nil }

    let topCpu = processes.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(max(0, limit))
    let topMemory = processes.sorted { $0.memoryBytes > $1.memoryBytes }.prefix(max(0, limit))

    return TopProcessesSnapshot(topCpu: Array(topCpu), topMemory: Array(topMemory))
  }

  public func readResources(limit: Int) -> [ProcessResourceSnapshot] {
    let now = DispatchTime.now().uptimeNanoseconds
    let pids = listPids()
    var nextSamples: [Int32: CpuSample] = [:]
    var processes: [ProcessResourceSnapshot] = []

    for pid in pids {
      guard let rusage = readRusage(pid: pid) else { continue }
      guard let info = readBSDInfo(pid: pid), !info.name.isEmpty else { continue }
      let appInfo = readAppInfo(pid: pid)
      let executablePath = readExecutablePath(pid: pid)

      let cpuPercent = normalizeCpuPercent(computeCpuPercent(pid: pid, cpuTimeNs: rusage.cpuTimeNs, nowNs: now))
      let diskRates = computeDiskRates(
        pid: pid,
        diskReadBytes: rusage.diskReadBytes,
        diskWriteBytes: rusage.diskWriteBytes,
        nowNs: now
      )

      nextSamples[pid] = CpuSample(
        cpuTimeNs: rusage.cpuTimeNs,
        timestampNs: now,
        diskReadBytes: rusage.diskReadBytes,
        diskWriteBytes: rusage.diskWriteBytes
      )

      processes.append(
        ProcessResourceSnapshot(
          pid: pid,
          name: info.name,
          cpuPercent: cpuPercent,
          memoryBytes: rusage.memoryBytes,
          diskReadBytesPerSec: diskRates.readBytesPerSec,
          diskWriteBytesPerSec: diskRates.writeBytesPerSec,
          appName: appInfo?.name,
          bundleId: appInfo?.bundleId,
          bundlePath: appInfo?.bundlePath,
          executablePath: executablePath,
          parentPid: info.parentPid
        )
      )
    }

    lastSamples = nextSamples
    lastDiskRates = lastDiskRates.filter { nextSamples[$0.key] != nil }

    let sorted = processes.sorted { $0.cpuPercent > $1.cpuPercent }
    let effectiveLimit = limit <= 0 ? sorted.count : min(limit, sorted.count)
    return Array(sorted.prefix(effectiveLimit))
  }

  private func computeCpuPercent(pid: Int32, cpuTimeNs: UInt64, nowNs: UInt64) -> Double {
    guard let last = lastSamples[pid] else { return 0 }
    guard cpuTimeNs >= last.cpuTimeNs else { return 0 }
    guard nowNs >= last.timestampNs else { return 0 }

    let deltaCpu = cpuTimeNs - last.cpuTimeNs
    let deltaTime = nowNs - last.timestampNs
    guard deltaTime > 0 else { return 0 }

    return (Double(deltaCpu) / Double(deltaTime)) * 100.0
  }

  private func normalizeCpuPercent(_ rawPercent: Double) -> Double {
    guard rawPercent > 0 else { return 0 }
    return rawPercent / logicalCpuCount
  }

  private func computeDiskRates(
    pid: Int32,
    diskReadBytes: UInt64,
    diskWriteBytes: UInt64,
    nowNs: UInt64
  ) -> (readBytesPerSec: Double, writeBytesPerSec: Double) {
    guard let last = lastSamples[pid] else { return (0, 0) }
    guard nowNs >= last.timestampNs else { return (0, 0) }

    let deltaTime = Double(nowNs - last.timestampNs) / 1_000_000_000.0
    guard deltaTime > 0 else { return (0, 0) }

    let readDelta = diskReadBytes >= last.diskReadBytes ? diskReadBytes - last.diskReadBytes : 0
    let writeDelta = diskWriteBytes >= last.diskWriteBytes ? diskWriteBytes - last.diskWriteBytes : 0

    let readRate = Double(readDelta) / deltaTime
    let writeRate = Double(writeDelta) / deltaTime
    let hasActivity = readRate > 0 || writeRate > 0

    if hasActivity {
      lastDiskRates[pid] = DiskRateSample(
        readBytesPerSec: readRate,
        writeBytesPerSec: writeRate,
        timestampNs: nowNs
      )
      return (readRate, writeRate)
    }

    if let cached = lastDiskRates[pid] {
      let age = nowNs >= cached.timestampNs ? nowNs - cached.timestampNs : diskRateRetentionNs + 1
      if age <= diskRateRetentionNs {
        return (cached.readBytesPerSec, cached.writeBytesPerSec)
      }
    }

    return (readRate, writeRate)
  }

  private func listPids() -> [Int32] {
    let count = proc_listallpids(nil, 0)
    guard count > 0 else { return [] }

    let bufferSize = Int(count)
    var pids = [pid_t](repeating: 0, count: bufferSize)
    let size = Int32(pids.count * MemoryLayout<pid_t>.size)
    let actual = proc_listallpids(&pids, size)
    guard actual > 0 else { return [] }

    return Array(pids.prefix(Int(actual))).filter { $0 > 0 }
  }

  private func readRusage(
    pid: Int32
  ) -> ProcessRusageSnapshot? {
    var info = rusage_info_v2()
    var rawInfo: rusage_info_t?
    let result = withUnsafeMutablePointer(to: &info) { infoPtr -> Int32 in
      rawInfo = UnsafeMutableRawPointer(infoPtr)
      return withUnsafeMutablePointer(to: &rawInfo) { rawPtr in
        proc_pid_rusage(pid, RUSAGE_INFO_V2, rawPtr)
      }
    }
    guard result == 0 else { return nil }

    let cpuTime = UInt64(info.ri_user_time) + UInt64(info.ri_system_time)
    let memoryBytes = UInt64(info.ri_resident_size)
    let diskReadBytes = UInt64(info.ri_diskio_bytesread)
    let diskWriteBytes = UInt64(info.ri_diskio_byteswritten)
    return ProcessRusageSnapshot(
      cpuTimeNs: cpuTime,
      memoryBytes: memoryBytes,
      diskReadBytes: diskReadBytes,
      diskWriteBytes: diskWriteBytes
    )
  }

  private func readBSDInfo(pid: Int32) -> (name: String, parentPid: Int32)? {
    var info = proc_bsdinfo()
    let expectedSize = Int32(MemoryLayout<proc_bsdinfo>.size)
    let result = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, expectedSize)
    guard result == expectedSize else { return nil }

    let name = withUnsafePointer(to: &info.pbi_name) { pointer in
      let namePtr = UnsafeRawPointer(pointer).assumingMemoryBound(to: CChar.self)
      return String(cString: namePtr)
    }
    return (name: name, parentPid: Int32(info.pbi_ppid))
  }

  private func readExecutablePath(pid: Int32) -> String? {
    var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
    let result = proc_pidpath(pid, &buffer, UInt32(buffer.count))
    guard result > 0 else { return nil }
    return String(cString: buffer)
  }

  private func readAppInfo(pid: Int32) -> ProcessAppInfo? {
    guard let app = NSRunningApplication(processIdentifier: pid) else { return nil }
    guard let bundleId = app.bundleIdentifier else { return nil }
    guard let bundleURL = app.bundleURL else { return nil }
    let name = app.localizedName ?? bundleId
    return ProcessAppInfo(name: name, bundleId: bundleId, bundlePath: bundleURL.path)
  }
}
