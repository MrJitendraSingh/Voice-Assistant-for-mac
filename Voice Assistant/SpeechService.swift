import Foundation
import Speech
import AVFoundation

final class SpeechService: NSObject {

    private let speechRecognizer =
        SFSpeechRecognizer(locale: Locale.current)

    private let audioEngine = AVAudioEngine()

    private var recognitionRequest:
        SFSpeechAudioBufferRecognitionRequest?

    private var recognitionTask:
        SFSpeechRecognitionTask?

    private var latestText = ""

    private var isListening = false

    var onFinalText: ((String) -> Void)?

    // MARK: - Permissions

    func requestPermissions() {

        SFSpeechRecognizer.requestAuthorization { status in

            DispatchQueue.main.async {

                switch status {

                case .authorized:
                    print("SPEECH_PERMISSION_GRANTED")

                case .denied:
                    print("ERROR_SPEECH_PERMISSION_DENIED")

                case .restricted:
                    print("ERROR_SPEECH_RESTRICTED")

                case .notDetermined:
                    print("ERROR_SPEECH_NOT_DETERMINED")

                @unknown default:
                    print("ERROR_UNKNOWN_SPEECH_PERMISSION")
                }

                fflush(stdout)
            }
        }

        AVCaptureDevice.requestAccess(for: .audio) { granted in

            DispatchQueue.main.async {

                if granted {
                    print("MIC_PERMISSION_GRANTED")
                } else {
                    print("ERROR_MIC_PERMISSION_DENIED")
                }

                fflush(stdout)
            }
        }
    }

    // MARK: - Start Listening

    func startListening() {

        guard !isListening else {
            return
        }

        guard let recognizer = speechRecognizer else {
            print("ERROR_SPEECH_RECOGNIZER")
            return
        }

        guard recognizer.isAvailable else {
            print("ERROR_SPEECH_RECOGNIZER_UNAVAILABLE")
            return
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        latestText = ""

        let request =
            SFSpeechAudioBufferRecognitionRequest()

        request.shouldReportPartialResults = true
        request.taskHint = .dictation

        // Use on-device recognition when supported.
        if recognizer.supportsOnDeviceRecognition {

            request.requiresOnDeviceRecognition = true

            print("ON_DEVICE_RECOGNITION_ENABLED")

        } else {

            print("ON_DEVICE_RECOGNITION_UNAVAILABLE")
        }

        recognitionRequest = request

        let inputNode = audioEngine.inputNode

        inputNode.removeTap(onBus: 0)

        // Use the microphone's actual hardware format.
        let recordingFormat =
            inputNode.outputFormat(forBus: 0)

        print(
            "AUDIO_FORMAT: \(recordingFormat)"
        )

        fflush(stdout)

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { buffer, _ in

            request.append(buffer)

            print("AUDIO_BUFFER_RECEIVED")

            fflush(stdout)
        }

        // Start recognition before starting the audio engine.
        recognitionTask =
            recognizer.recognitionTask(
                with: request
            ) { [weak self] result, error in

                guard let self = self else {
                    return
                }

                if let result = result {

                    let text =
                        result.bestTranscription
                            .formattedString
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )

                    if !text.isEmpty {

                        self.latestText = text

                        print(
                            "PARTIAL_TEXT: \(text)"
                        )

                        fflush(stdout)
                    }

                    if result.isFinal {

                        self.finishRecognition()
                    }
                }

                if let error = error {

                    print(
                        "ERROR_RECOGNITION: \(error)"
                    )

                    fflush(stdout)
                }
            }

        audioEngine.prepare()

        do {

            try audioEngine.start()

            isListening = true

            print("LISTENING_STARTED")

            fflush(stdout)

        } catch {

            print(
                "ERROR_AUDIO_START: \(error)"
            )

            fflush(stdout)

            inputNode.removeTap(onBus: 0)

            recognitionTask?.cancel()
            recognitionTask = nil

            recognitionRequest = nil
        }
    }

    // MARK: - Stop Listening

    func stopListening() {

        guard isListening else {
            return
        }

        isListening = false

        audioEngine.stop()

        audioEngine.inputNode.removeTap(onBus: 0)

        // Tell Speech Recognition that no more audio is coming.
        recognitionRequest?.endAudio()

        print("LISTENING_STOPPED")

        fflush(stdout)

        // Do not cancel recognitionTask here.
        // Wait for Apple's final recognition result.
    }

    // MARK: - Final Recognition

    private func finishRecognition() {

        let text =
            latestText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !text.isEmpty {

            print(
                "FINAL_TEXT: \(text)"
            )

            fflush(stdout)

            DispatchQueue.main.async {

                self.onFinalText?(text)
            }
        }

        latestText = ""

        recognitionTask = nil

        recognitionRequest = nil
    }
}
