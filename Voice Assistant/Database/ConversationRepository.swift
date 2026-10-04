import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(
    -1,
    to: sqlite3_destructor_type.self
)

final class ConversationRepository {

    private let database: OpaquePointer?


    init(database: OpaquePointer?) {
        self.database = database
    }

    func createConversation(
        title: String
    ) -> Int64? {

        let sql = """
        INSERT INTO conversations (
            title,
            created_at,
            updated_at
        )
        VALUES (?, ?, ?);
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {

            print("ERROR_PREPARING_CREATE_CONVERSATION")
            return nil
        }

        defer {
            sqlite3_finalize(statement)
        }

        let now = Date().timeIntervalSince1970

        sqlite3_bind_text(
            statement,
            1,
            title,
            -1,
            SQLITE_TRANSIENT
        )

        sqlite3_bind_double(
            statement,
            2,
            now
        )

        sqlite3_bind_double(
            statement,
            3,
            now
        )

        guard sqlite3_step(statement) == SQLITE_DONE else {

            print("ERROR_CREATING_CONVERSATION")

            return nil
        }

        let id = sqlite3_last_insert_rowid(database)

        print("CONVERSATION_CREATED: \(id)")

        return id
    }
    
    // MARK: - Fetch Conversations

    func fetchConversations() -> [
        SidebarConversation
    ] {

        let sql = """
        SELECT
            id,
            title,
            updated_at
        FROM conversations
        ORDER BY updated_at DESC;
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
                "ERROR_PREPARING_FETCH_CONVERSATIONS"
            )

            return []
        }

        defer {
            sqlite3_finalize(statement)
        }

        var conversations: [
            SidebarConversation
        ] = []

        while sqlite3_step(statement) == SQLITE_ROW {

            let id =
                sqlite3_column_int64(
                    statement,
                    0
                )

            let titlePointer =
                sqlite3_column_text(
                    statement,
                    1
                )

            let updatedAt =
                sqlite3_column_double(
                    statement,
                    2
                )

            let title =
                titlePointer != nil
                ? String(
                    cString: titlePointer!
                )
                : "Untitled Conversation"

            conversations.append(
                SidebarConversation(
                    id: id,
                    title: title,
                    date: Date(
                        timeIntervalSince1970:
                            updatedAt
                    )
                )
            )
        }

        print(
            "CONVERSATIONS_FETCHED: \(conversations.count)"
        )

        return conversations
    }
}
