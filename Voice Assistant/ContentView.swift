import SwiftUI

struct ContentView: View {

    // MARK: - Dependencies

    private let databaseManager: DatabaseManager
    private let conversationManager: ConversationManager

    private let ollama = OllamaClient()
    private let tts = TTSService()

    // MARK: - Services

    @State private var speechService = SpeechService()

    // MARK: - UI State

    @State private var isListening = false
    @State private var isThinking = false

    @State private var recognizedText = ""
    @State private var inputText = ""

    @State private var assistantResponse = ""

    @State private var messages: [ChatMessage] = []

    @State private var conversations: [
        SidebarConversation
    ] = []

    @State private var selectedConversationId: Int64?

    // MARK: - Init

    init(databaseManager: DatabaseManager) {

        self.databaseManager = databaseManager

        self.conversationManager =
            ConversationManager(
                databaseManager: databaseManager
            )
    }

    // MARK: - Body

    var body: some View {

        NavigationSplitView {

            SidebarView(
                conversations: conversations,
                selectedConversationId:
                    $selectedConversationId,
                onNewConversation:
                    startNewConversation
            )

        } detail: {

            VStack(spacing: 0) {

                ChatView(
                    messages: messages,
                    isThinking: isThinking
                )

                ComposerView(
                    text: $inputText,
                    isListening: isListening,
                    isThinking: isThinking,
                    onMicrophoneTap:
                        toggleListening,
                    onSend:
                        sendTextMessage
                )
            }
        }
        .frame(
            minWidth: 900,
            minHeight: 650
        )
        .onAppear {
            setupAssistant()
        }
        .onChange(of: selectedConversationId) { _, newConversationId in

            guard let conversationId = newConversationId else {
                return
            }

            loadMessages(
                for: conversationId
            )
        }
    }

    // MARK: - Setup

    private func setupAssistant() {

        speechService.requestPermissions()

        speechService.onFinalText = { text in

            handleRecognizedText(text)
        }

        // Load existing conversations from SQLite.
        let storedConversations =
            conversationManager.fetchConversations()

        conversations = storedConversations

        if let firstConversation = storedConversations.first {

            selectedConversationId =
                firstConversation.id

            conversationManager.resumeConversation(
                id: firstConversation.id
            )

            loadMessages(
                for: firstConversation.id
            )

            print(
                "CONVERSATION_RESUMED: \(firstConversation.id)"
            )

        } else {

            if let id =
                conversationManager.startConversation(
                    title: "New Conversation"
                ) {

                selectedConversationId = id

                conversations =
                    conversationManager.fetchConversations()
            }
        }
    }

    // MARK: - Microphone

    private func toggleListening() {

        if isListening {

            speechService.stopListening()

            isListening = false

        } else {

            recognizedText = ""

            speechService.startListening()

            isListening = true
        }
    }

    // MARK: - Recognized Speech

    private func handleRecognizedText(
        _ text: String
    ) {

        DispatchQueue.main.async {

            recognizedText = text

            inputText = ""

            isListening = false

            isThinking = true

            sendToAssistant(text)
        }
    }

    // MARK: - Text Message

    private func sendTextMessage() {

        let text =
            inputText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !text.isEmpty else {
            return
        }

        inputText = ""

        sendToAssistant(text)
    }

    // MARK: - Send To Assistant

    private func sendToAssistant(
        _ text: String
    ) {

        let trimmedText =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedText.isEmpty else {
            return
        }

        guard let conversationId =
                selectedConversationId
        else {

            print(
                "OLLAMA_ERROR: No selected conversation"
            )

            return
        }

        // Build context BEFORE saving the new user message.
        // This prevents the new prompt from being sent twice.
        let context =
            conversationManager.buildOllamaContext(
                for: conversationId
            )

        // Show the user message immediately in the UI.
        messages.append(
            ChatMessage(
                role: .user,
                text: trimmedText
            )
        )

        inputText = ""

        isThinking = true

        print(
            "OLLAMA_CONTEXT_MESSAGES: \(context.count)"
        )

        ollama.ask(
            trimmedText,
            context: context
        ) { result in

            DispatchQueue.main.async {

                switch result {

                case .success(let response):

                    isThinking = false

                    // Save user message.
                    let userSaved =
                        conversationManager.saveUserMessage(
                            trimmedText
                        )

                    if !userSaved {

                        print(
                            "DATABASE_ERROR: Failed to save user message"
                        )
                    }

                    // Show assistant response.
                    messages.append(
                        ChatMessage(
                            role: .assistant,
                            text: response
                        )
                    )

                    assistantResponse = response

                    print(
                        "ASSISTANT_RESPONSE: \(response)"
                    )

                    // Save assistant response.
                    let assistantSaved =
                        conversationManager
                            .saveAssistantMessage(
                                response
                            )

                    if !assistantSaved {

                        print(
                            "DATABASE_ERROR: Failed to save assistant response"
                        )
                    }

                    // Speak response.
                    tts.speak(response)

                case .failure(let error):

                    isThinking = false

                    let errorMessage =
                        "Sorry, I couldn't connect to the voice assistant."

                    messages.append(
                        ChatMessage(
                            role: .assistant,
                            text: errorMessage
                        )
                    )

                    print(
                        "OLLAMA_ERROR: \(error)"
                    )
                }
            }
        }
    }

    // MARK: - New Conversation

    private func startNewConversation() {

        messages.removeAll()

        inputText = ""

        recognizedText = ""

        assistantResponse = ""

        isThinking = false

        if let id =
            conversationManager.startConversation(
                title: "New Conversation"
            ) {

            selectedConversationId = id
        
        }
    }
    
    // MARK: - Load Messages

    private func loadMessages(
        for conversationId: Int64
    ) {

        let storedMessages =
            conversationManager.fetchMessages(
                for: conversationId
            )

        messages = storedMessages

        print(
            "UI_MESSAGES_LOADED: \(storedMessages.count)"
        )
    }
    
}
