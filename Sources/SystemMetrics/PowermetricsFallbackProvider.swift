import Darwin
import Foundation
import PulseMacDomain

public final class PowermetricsFallbackProvider: ThermalFallbackProviding {
  private struct RunResult {
    let exitCode: Int32
    let output: String
    let error: String
  }

  public init() {}

  public func readOnce(completion: @escaping (ThermalFallbackSample) -> Void) {
    DispatchQueue.global(qos: .utility).async { [self] in
      let samplers = Self.preferredSamplers()
      var lastOutput = ""
      var lastError = ""

      for sampler in samplers {
        let result = runPowermetrics(sampler: sampler)
        lastOutput = result.output
        lastError = result.error

        if result.exitCode == 0 {
          let temperatures = Self.extractTemperatures(from: result.output)
          let fans = Self.extractFans(from: result.output)
          let tempValue = temperatures.max()

          let sample = ThermalFallbackSample(
            temperatureC: tempValue,
            fanRPMs: fans,
            rawOutput: result.output,
            errorMessage: (tempValue == nil && fans.isEmpty) ? "Powermetrics sem dados de sensores." : nil
          )
          DispatchQueue.main.async {
            completion(sample)
          }
          return
        }

        if Self.isUnrecognizedSampler(result.error + result.output) {
          continue
        }

        DiagnosticsLogger.shared.record(
          "Powermetrics retornou erro: \(result.error.isEmpty ? result.output : result.error)",
          context: "Sensores"
        )
        let sample = ThermalFallbackSample(
          temperatureC: nil,
          fanRPMs: [],
          rawOutput: result.output.isEmpty ? result.error : result.output,
          errorMessage: "Powermetrics retornou erro."
        )
        DispatchQueue.main.async {
          completion(sample)
        }
        return
      }

      let combined = lastOutput.isEmpty ? lastError : lastOutput
      DiagnosticsLogger.shared.record(
        "Powermetrics sem dados de sensores. Detalhe: \(combined)",
        context: "Sensores"
      )
      let sample = ThermalFallbackSample(
        temperatureC: nil,
        fanRPMs: [],
        rawOutput: combined,
        errorMessage: "Powermetrics nao suporta os samplers disponiveis neste macOS."
      )
      DispatchQueue.main.async {
        completion(sample)
      }
    }
  }

  private static func preferredSamplers() -> [String] {
    let brand = cpuBrandString().lowercased()
    if brand.contains("apple") {
      return ["thermal", "smcstats", "smc"]
    }
    return ["smc", "thermal", "smcstats"]
  }

  private static func cpuBrandString() -> String {
    var size = 0
    sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
    guard size > 0 else { return "" }
    var buffer = [CChar](repeating: 0, count: size)
    sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
    return String(cString: buffer)
  }

  private static func isUnrecognizedSampler(_ text: String) -> Bool {
    text.lowercased().contains("unrecognized sampler")
  }

  private func runPowermetrics(sampler: String) -> RunResult {
    let script = "do shell script \"/usr/bin/powermetrics --samplers \(sampler) -n 1\" with administrator privileges"
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    task.arguments = ["-e", script]

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    task.standardOutput = outputPipe
    task.standardError = errorPipe

    do {
      try task.run()
    } catch {
      DiagnosticsLogger.shared.record(
        "Falha ao executar powermetrics: \(error.localizedDescription)",
        context: "Sensores"
      )
      return RunResult(
        exitCode: 1,
        output: "",
        error: "Falha ao executar powermetrics: \(error.localizedDescription)"
      )
    }

    task.waitUntilExit()
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: outputData, encoding: .utf8) ?? ""
    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
    return RunResult(exitCode: task.terminationStatus, output: output, error: errorOutput)
  }

  private static func extractTemperatures(from text: String) -> [Double] {
    let pattern = #"(?i)(cpu|gpu|soc|die|package|core|cluster).*?([0-9]+(?:\.[0-9]+)?)\s*c"#
    return extractNumbers(pattern: pattern, in: text)
  }

  private static func extractFans(from text: String) -> [Double] {
    let pattern = #"(?i)fan.*?([0-9]+(?:\.[0-9]+)?)\s*rpm"#
    return extractNumbers(pattern: pattern, in: text)
  }

  private static func extractNumbers(pattern: String, in text: String) -> [Double] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
    let range = NSRange(text.startIndex ..< text.endIndex, in: text)
    let matches = regex.matches(in: text, options: [], range: range)
    var values: [Double] = []
    for match in matches {
      if match.numberOfRanges < 2 { continue }
      let valueRange = match.range(at: 2)
      guard let range = Range(valueRange, in: text) else { continue }
      let valueText = String(text[range])
      if let value = Double(valueText) {
        values.append(value)
      }
    }
    return values
  }
}
