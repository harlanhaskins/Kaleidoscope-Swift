import Foundation

do {
    try REPL().run()
} catch {
    print("error: \(error)")
}
