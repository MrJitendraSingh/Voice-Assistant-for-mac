import Foundation

final class TTSService {

    func speak(_ text: String) {

        guard !text.isEmpty else {
            return
        }

        let task = Process()

        task.executableURL = URL(
            fileURLWithPath: "/usr/bin/say"
        )

        task.arguments = [text]

        do {
            try task.run()
        } catch {
            print("TTS_ERROR: \(error)")
        }
    }
}
