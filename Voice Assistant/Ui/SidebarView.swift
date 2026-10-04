import SwiftUI

struct SidebarConversation: Identifiable {
    
    let id: Int64
    let title: String
    let date: Date
}

struct SidebarView: View {
    
    let conversations: [SidebarConversation]
    
    @Binding var selectedConversationId: Int64?
    
    let onNewConversation: () -> Void
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            // MARK: - Header
            
            HStack {
                
                Text("Voice Assistant")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    onNewConversation()
                } label: {
                    
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("New conversation")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            Divider()
            
            // MARK: - New Chat
            
            Button {
                onNewConversation()
            } label: {
                
                HStack(spacing: 10) {
                    
                    Image(systemName: "plus")
                    
                    Text("New Chat")
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        Color.accentColor.opacity(0.10)
                    )
            )
            .padding(10)
            
            // MARK: - Conversations
            
            ScrollView {
                
                LazyVStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    
                    if conversations.isEmpty {
                        
                        Text("No conversations yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        
                    } else {
                        
                        Text("Conversations")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                        
                        ForEach(conversations) { conversation in
                            
                            conversationRow(
                                conversation
                            )
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            
            Divider()
            
            // MARK: - Bottom
            
            HStack(spacing: 10) {
                
                Image(systemName: "person.circle")
                    .font(.title3)
                
                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    
                    Text("Local Assistant")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Running on this Mac")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(14)
        }
        .frame(minWidth: 240, idealWidth: 260)
        .background(
            Color(nsColor: .controlBackgroundColor)
        )
    }
    
    // MARK: - Conversation Row
    
    private func conversationRow(
        _ conversation: SidebarConversation
    ) -> some View {
        
        Button {
            
            selectedConversationId =
                conversation.id
            
        } label: {
            
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                
                Text(conversation.title)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(
                    conversation.date,
                    style: .relative
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    selectedConversationId == conversation.id
                    ? Color.accentColor.opacity(0.12)
                    : Color.clear
                )
        )
        .padding(.horizontal, 8)
    }
}
