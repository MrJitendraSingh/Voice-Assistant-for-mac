import Foundation
import SQLite3

final class DatabaseManager {

    var database: OpaquePointer?

    private(set) lazy var conversationRepository =
        ConversationRepository(database: database)
    
    private(set) lazy var messageRepository =
        MessageRepository(database: database)

    // MARK: - Initialization

    init() {
        openDatabase()
        createTables()
    }

    deinit {
        closeDatabase()
    }

    // MARK: - Open Database

    private func openDatabase() {

        let fileManager = FileManager.default

        guard let appSupportURL =
                fileManager.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                ).first
        else {
            print("DATABASE_ERROR: App Support directory not found")
            return
        }

        let mjDirectory =
            appSupportURL.appendingPathComponent(
                "VoiceAssistant",
                isDirectory: true
            )

        do {

            try fileManager.createDirectory(
                at: mjDirectory,
                withIntermediateDirectories: true
            )

        } catch {

            print(
                "DATABASE_DIRECTORY_ERROR: \(error)"
            )

            return
        }

        let databaseURL =
            mjDirectory.appendingPathComponent(
                "assistant.sqlite"
            )

        if sqlite3_open(
            databaseURL.path,
            &database
        ) == SQLITE_OK {

            print(
                "DATABASE_OPENED: \(databaseURL.path)"
            )

        } else {

            print("DATABASE_OPEN_ERROR")

            if database != nil {

                sqlite3_close(database)

                database = nil
            }
        }
    }

    // MARK: - Create Tables

    private func createTables() {

        guard database != nil else {

            print(
                "DATABASE_ERROR: Cannot create tables because database is not open"
            )

            return
        }

        // Enable foreign key support.
        sqlite3_exec(
            database,
            "PRAGMA foreign_keys = ON;",
            nil,
            nil,
            nil
        )

        let sql = """
        CREATE TABLE IF NOT EXISTS conversations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );

        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversation_id INTEGER NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at REAL NOT NULL,

            FOREIGN KEY (conversation_id)
                REFERENCES conversations(id)
                ON DELETE CASCADE
        );
        """

        var errorMessage: UnsafeMutablePointer<CChar>?

        let result = sqlite3_exec(
            database,
            sql,
            nil,
            nil,
            &errorMessage
        )

        if result == SQLITE_OK {

            print("DATABASE_TABLES_READY")

        } else {

            if let errorMessage = errorMessage {

                let message =
                    String(cString: errorMessage)

                print(
                    "DATABASE_TABLE_ERROR: \(message)"
                )

                sqlite3_free(errorMessage)

            } else {

                print(
                    "DATABASE_TABLE_ERROR: Unknown error"
                )
            }
        }
    }
    
    // MARK: - Close Database

    private func closeDatabase() {

        guard database != nil else {
            return
        }

        sqlite3_close(database)

        database = nil

        print("DATABASE_CLOSED")
    }
}
