import Foundation

final class ConversationManager {

    private let databaseManager: DatabaseManager

    private let conversationRepository:
        ConversationRepository

    private let messageRepository:
        MessageRepository

    private(set) var currentConversationId:
        Int64?

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
}
