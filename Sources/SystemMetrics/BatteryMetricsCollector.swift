import Foundation
import IOKit.ps
import PulseMacDomain

public final class BatteryMetricsCollector: BatteryMetricsProviding {
  public init() {}

  public func read() -> BatteryMetrics? {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
    guard let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }

    for source in sources {
      guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else { continue }
      guard let type = description[kIOPSTypeKey as String] as? String else { continue }
      if type != kIOPSInternalBatteryType { continue }

      let current = Self.doubleValue(description[kIOPSCurrentCapacityKey as String])
      let max = Self.doubleValue(description[kIOPSMaxCapacityKey as String])
      let design = Self.doubleValue(description[kIOPSDesignCapacityKey as String])
      let cycleCount = Self.intValue(description["Cycle Count"])
      let isCharged = description[kIOPSIsChargedKey as String] as? Bool
      let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false
      let timeToEmpty = Self.intValue(description[kIOPSTimeToEmptyKey as String])
      let timeToFull = Self.intValue(description[kIOPSTimeToFullChargeKey as String])
      let health = description[kIOPSBatteryHealthKey as String] as? String

      let powerState = description[kIOPSPowerSourceStateKey as String] as? String ?? ""
      let sourceType: PowerSource = if powerState == kIOPSACPowerValue {
        .acPower
      } else if powerState == kIOPSBatteryPowerValue {
        .battery
      } else {
        .unknown
      }

      let safeMax = max ?? 0
      let safeCurrent = current ?? 0
      let percent = safeMax > 0 ? (safeCurrent / safeMax) * 100.0 : 0
      return BatteryMetrics(
        chargePercent: percent,
        isCharging: isCharging,
        powerSource: sourceType,
        currentCapacity: current,
        maxCapacity: max,
        designCapacity: design,
        cycleCount: cycleCount,
        isCharged: isCharged,
        timeToEmptyMinutes: timeToEmpty,
        timeToFullMinutes: timeToFull,
        health: health
      )
    }

    return nil
  }

  private static func doubleValue(_ value: Any?) -> Double? {
    if let doubleValue = value as? Double { return doubleValue }
    if let intValue = value as? Int { return Double(intValue) }
    if let numberValue = value as? NSNumber { return numberValue.doubleValue }
    return nil
  }

  private static func intValue(_ value: Any?) -> Int? {
    if let intValue = value as? Int { return intValue }
    if let numberValue = value as? NSNumber { return numberValue.intValue }
    return nil
  }
}
