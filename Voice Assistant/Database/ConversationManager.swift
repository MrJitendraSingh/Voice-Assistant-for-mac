import Foundation

final class ConversationManager {

    private let databaseManager: DatabaseManager

    private let conversationRepository:
        ConversationRepository

    private let messageRepository:
        MessageRepository

    private(set) var currentConversationId:
        Int64?
    
    // MARK: - Resume Conversation

    func resumeConversation(
        id: Int64
    ) {

        currentConversationId = id

        print(
            "CURRENT_CONVERSATION_RESUMED: \(id)"
        )
    }

    init(databaseManager: DatabaseManager) {

        self.databaseManager = databaseManager

        self.conversationRepository =
            databaseManager.conversationRepository

        self.messageRepository =
            databaseManager.messageRepository
    }

    // MARK: - Start Conversation

    @discardableResult
    func startConversation(
        title: String = "New Conversation"
    ) -> Int64? {

        guard let conversationId =
                conversationRepository.createConversation(
                    title: title
                )
        else {

            print(
                "CONVERSATION_START_FAILED"
            )

            return nil
        }

        currentConversationId = conversationId

        print(
            "CURRENT_CONVERSATION: \(conversationId)"
        )

        return conversationId
    }

    // MARK: - Save User Message

    @discardableResult
    func saveUserMessage(
        _ text: String
    ) -> Bool {

        guard let conversationId =
                currentConversationId
        else {

            print(
                "ERROR: No active conversation"
            )

            return false
        }

        return messageRepository.saveMessage(
            conversationId: conversationId,
            role: "user",
            content: text
        )
    }

    // MARK: - Save Assistant Message

    @discardableResult
    func saveAssistantMessage(
        _ text: String
    ) -> Bool {

        guard let conversationId =
                currentConversationId
        else {

            print(
                "ERROR: No active conversation"
            )

            return false
        }

        return messageRepository.saveMessage(
            conversationId: conversationId,
            role: "assistant",
            content: text
        )
    }
    
    // MARK: - Fetch Conversations

    func fetchConversations() -> [SidebarConversation] {

        let conversations =
            conversationRepository.fetchConversations()

        print(
            "CONVERSATION_MANAGER_FETCHED: \(conversations.count)"
        )

        return conversations
    }
    
    // MARK: - Fetch Messages

    func fetchMessages(
        for conversationId: Int64
    ) -> [ChatMessage] {

        let messages =
            messageRepository.fetchMessages(
                conversationId: conversationId
            )

        print(
            "CONVERSATION_MANAGER_MESSAGES_FETCHED: \(messages.count)"
        )

        return messages
    }
    
    // MARK: - Build Ollama Context

    func buildOllamaContext(
        for conversationId: Int64
    ) -> [[String: String]] {

        let storedMessages =
            messageRepository.fetchMessages(
                conversationId: conversationId
            )

        var context: [[String: String]] = [

            [
                "role": "system",
                "content": """
                You are a local personal voice assistant.

                Rules:

                - Be natural and conversational.
                - Keep responses reasonably short.
                - Do not use markdown unless necessary.
                - Do not use emojis.
                - Respond in the same language as the user.
                - If the user speaks Hinglish, respond in Hinglish.
                - Never claim you performed an action unless the application actually performed it.
                """
            ]
        ]

        for message in storedMessages {

            let role: String

            switch message.role {

            case .user:
                role = "user"

            case .assistant:
                role = "assistant"
            }

            context.append(
                [
                    "role": role,
                    "content": message.text
                ]
            )
        }

        print(
            "OLLAMA_CONTEXT_BUILT: \(context.count) messages"
        )

        return context
    }
}
