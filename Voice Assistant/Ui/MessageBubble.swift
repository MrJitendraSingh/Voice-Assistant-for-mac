import SwiftUI

enum MessageRole {
    case user
    case assistant
}

struct ChatMessage: Identifiable {
    
    let id = UUID()
    let role: MessageRole
    let text: String
}

struct MessageBubble: View {
    
    let message: ChatMessage
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 12) {
            
            if message.role == .assistant {
                
                assistantAvatar
                
                messageContent
                
                Spacer(minLength: 80)
                
            } else {
                
                Spacer(minLength: 80)
                
                messageContent
                
                userAvatar
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
    
    // MARK: - Message Content
    
    private var messageContent: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            
            Text(
                message.role == .assistant
                ? "Voice Assistant"
                : "You"
            )
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            
            Text(message.text)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(14)
        .background(
            message.role == .assistant
            ? Color.secondary.opacity(0.08)
            : Color.accentColor.opacity(0.10)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }
    
    // MARK: - Assistant Avatar
    
    private var assistantAvatar: some View {
        
        ZStack {
            
            Circle()
                .fill(Color.accentColor.opacity(0.15))
            
            Image(systemName: "waveform")
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 32, height: 32)
    }
    
    // MARK: - User Avatar
    
    private var userAvatar: some View {
        
        ZStack {
            
            Circle()
                .fill(Color.secondary.opacity(0.15))
            
            Image(systemName: "person.fill")
                .foregroundStyle(.secondary)
        }
        .frame(width: 32, height: 32)
    }
}
