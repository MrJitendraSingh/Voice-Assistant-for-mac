import SwiftUI

struct ChatView: View {

    let messages: [ChatMessage]
    let isThinking: Bool

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Chat Header

            HStack {

                VStack(alignment: .leading, spacing: 4) {

                    Text("Voice Assistant")
                        .font(.headline)

                    Text(
                        messages.isEmpty
                        ? "New conversation"
                        : "\(messages.count) messages"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            // MARK: - Messages

            if messages.isEmpty {

                emptyState

            } else {

                ScrollViewReader { proxy in

                    ScrollView {

                        LazyVStack(spacing: 4) {

                            ForEach(messages) { message in

                                MessageBubble(
                                    message: message
                                )
                                .id(message.id)
                            }

                            if isThinking {

                                thinkingIndicator
                                    .id("thinking")
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) { _, _ in

                        scrollToBottom(
                            using: proxy
                        )
                    }
                    .onChange(of: isThinking) { _, thinking in

                        if thinking {
                            scrollToBottom(
                                using: proxy
                            )
                        }
                    }
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {

        VStack(spacing: 16) {

            Spacer()

            ZStack {

                Circle()
                    .fill(
                        Color.accentColor
                            .opacity(0.12)
                    )

                Image(systemName: "waveform")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        Color.accentColor
                    )
            }
            .frame(
                width: 72,
                height: 72
            )

            Text("How can I help you?")

                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "Speak naturally or type a message to get started."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Thinking Indicator

    private var thinkingIndicator: some View {

        HStack(alignment: .top, spacing: 12) {

            ZStack {

                Circle()
                    .fill(
                        Color.accentColor
                            .opacity(0.15)
                    )

                Image(systemName: "waveform")
                    .foregroundStyle(
                        Color.accentColor
                    )
            }
            .frame(
                width: 32,
                height: 32
            )

            HStack(spacing: 5) {

                Circle()
                    .frame(
                        width: 6,
                        height: 6
                    )

                Circle()
                    .frame(
                        width: 6,
                        height: 6
                    )

                Circle()
                    .frame(
                        width: 6,
                        height: 6
                    )
            }
            .foregroundStyle(.secondary)
            .padding(.top, 12)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    // MARK: - Scroll

    private func scrollToBottom(
        using proxy: ScrollViewProxy
    ) {

        guard let lastMessage = messages.last else {
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {

            proxy.scrollTo(
                lastMessage.id,
                anchor: .bottom
            )
        }
    }
}
