import Foundation
import SwiftFormat

CLI.print = { message, _ in
  Swift.print(message)
}

let exitCode = CLI.run(in: FileManager.default.currentDirectoryPath, with: CommandLine.arguments)
exit(exitCode.rawValue)
