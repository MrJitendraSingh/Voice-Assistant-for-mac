//
//  Voice_AssistantApp.swift
//  Voice Assistant
//
//  Created by Jitendra Singh Lodhi on 03/10/26.
//

import SwiftUI

@main
struct Voice_AssistantApp: App {
    
    private let databaseManager = DatabaseManager()
    var body: some Scene {
        WindowGroup {
            ContentView(databaseManager : databaseManager)
        }
    }
}
