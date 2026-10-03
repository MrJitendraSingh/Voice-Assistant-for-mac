import SwiftUI

struct ContentView: View {

    private let databaseManager: DatabaseManager
    private let conversationManager: ConversationManager

    @State private var speechService = SpeechService()
    @State private var isListening = false
    @State private var recognizedText = ""
    @State private var assistantResponse = ""
    @State private var isThinking = false

    private let ollama = OllamaClient()
    private let tts = TTSService()

    init(databaseManager: DatabaseManager) {

        self.databaseManager = databaseManager

        self.conversationManager =
            ConversationManager(
                databaseManager: databaseManager
            )
    }

    var body: some View {

        VStack(spacing: 20) {

            Text("Voice Assistant")
                .font(.largeTitle)
                .bold()

            Text(
                recognizedText.isEmpty
                ? "Press Start and speak"
                : recognizedText
            )
            .frame(minWidth: 400, minHeight: 80)
            .padding()
            .background(.gray.opacity(0.1))
            .cornerRadius(12)

            Text(
                isThinking
                ? "Voice Assistant is thinking..."
                : (
                    assistantResponse.isEmpty
                    ? "Response will appear here"
                    : assistantResponse
                )
            )
            .frame(minWidth: 400, minHeight: 80)
            .padding()
            .background(.blue.opacity(0.08))
            .cornerRadius(12)

            Button(
                isListening
                ? "Stop Listening"
                : "Start Listening"
            ) {

                if isListening {

                    speechService.stopListening()
                    isListening = false

                } else {

                    recognizedText = ""
                    assistantResponse = ""

                    speechService.startListening()
                    isListening = true
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .onAppear {
            if conversationManager.currentConversationId == nil {
                conversationManager.startConversation(
                    title: "Voice Assistant"
                )
            }
            speechService.requestPermissions()

            speechService.onFinalText = { text in

                DispatchQueue.main.async {

                    recognizedText = text
                    isListening = false
                    isThinking = true
                }

                ollama.ask(text) { result in

                    DispatchQueue.main.async {

                        isThinking = false

                        switch result {

                        case .success(let response):

                            assistantResponse = response

                            print(
                                "ASSISTANT_RESPONSE: \(response)"
                            )

                            tts.speak(response)

                        case .failure(let error):

                            assistantResponse =
                                "Sorry, I couldn't connect to the voice assistant."

                            print(
                                "OLLAMA_ERROR: \(error)"
                            )
                        }
                    }
                }
            }
        }
    }
}
