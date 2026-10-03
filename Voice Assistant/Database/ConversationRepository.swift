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
}
