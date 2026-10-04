import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(
    -1,
    to: sqlite3_destructor_type.self
)

final class MessageRepository {

    private let database: OpaquePointer?

    init(database: OpaquePointer?) {
        self.database = database
    }

    // MARK: - Save Message

    @discardableResult
    func saveMessage(
        conversationId: Int64,
        role: String,
        content: String
    ) -> Bool {

        let sql = """
        INSERT INTO messages (
            conversation_id,
            role,
            content,
            created_at
        )
        VALUES (?, ?, ?, ?);
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {

            print("ERROR_PREPARING_SAVE_MESSAGE")

            return false
        }

        defer {
            sqlite3_finalize(statement)
        }

        let now = Date().timeIntervalSince1970

        sqlite3_bind_int64(
            statement,
            1,
            conversationId
        )

        sqlite3_bind_text(
            statement,
            2,
            role,
            -1,
            SQLITE_TRANSIENT
        )

        sqlite3_bind_text(
            statement,
            3,
            content,
            -1,
            SQLITE_TRANSIENT
        )

        sqlite3_bind_double(
            statement,
            4,
            now
        )

        guard sqlite3_step(statement) == SQLITE_DONE else {

            let errorMessage =
                String(
                    cString: sqlite3_errmsg(database)
                )

            print(
                "ERROR_SAVING_MESSAGE: \(errorMessage)"
            )

            return false
        }

        print(
            "MESSAGE_SAVED: \(role)"
        )

        return true
    }
    
    
    // MARK: - Fetch Messages

    func fetchMessages(
        conversationId: Int64
    ) -> [ChatMessage] {

        let sql = """
        SELECT
            id,
            role,
            content
        FROM messages
        WHERE conversation_id = ?
        ORDER BY created_at ASC, id ASC;
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {

            print(
                "ERROR_PREPARING_FETCH_MESSAGES"
            )

            return []
        }

        defer {
            sqlite3_finalize(statement)
        }

        sqlite3_bind_int64(
            statement,
            1,
            conversationId
        )

        var messages: [ChatMessage] = []

        while sqlite3_step(statement) == SQLITE_ROW {

            let rolePointer =
                sqlite3_column_text(
                    statement,
                    1
                )

            let contentPointer =
                sqlite3_column_text(
                    statement,
                    2
                )

            guard
                let rolePointer = rolePointer,
                let contentPointer = contentPointer
            else {
                continue
            }

            let role =
                String(
                    cString: rolePointer
                )

            let content =
                String(
                    cString: contentPointer
                )

            let messageRole: MessageRole

            switch role {

            case "user":
                messageRole = .user

            case "assistant":
                messageRole = .assistant

            default:
                continue
            }

            messages.append(
                ChatMessage(
                    role: messageRole,
                    text: content
                )
            )
        }

        print(
            "MESSAGES_FETCHED: \(messages.count)"
        )

        return messages
    }
    
}
