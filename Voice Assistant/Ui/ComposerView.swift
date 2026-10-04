//
//  ComposerView.swift
//  Voice Assistant
//
//  Created by Jitendra Singh Lodhi on 03/10/26.
//

import SwiftUI

struct ComposerView: View {

    @Binding var text: String

    let isListening: Bool
    let isThinking: Bool

    let onMicrophoneTap: () -> Void
    let onSend: () -> Void

    var body: some View {

        VStack(spacing: 0) {

            Divider()

            HStack(alignment: .bottom, spacing: 10) {

                // MARK: - Text Field

                TextField(
                    "Message Voice Assistant...",
                    text: $text,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .onSubmit {
                    
                    guard !text.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty else {
                        return
                    }

                    onSend()
                }

                // MARK: - Microphone

                Button {
                    onMicrophoneTap()
                } label: {

                    ZStack {

                        Circle()
                            .fill(
                                isListening
                                ? Color.red.opacity(0.15)
                                : Color.secondary.opacity(0.12)
                            )

                        Image(
                            systemName:
                                isListening
                                ? "stop.fill"
                                : "mic.fill"
                        )
                        .foregroundStyle(
                            isListening
                            ? Color.red
                            : Color.primary
                        )
                    }
                    .frame(
                        width: 36,
                        height: 36
                    )
                }
                .buttonStyle(.plain)
                .help(
                    isListening
                    ? "Stop listening"
                    : "Start listening"
                )

                // MARK: - Send

                Button {

                    onSend()

                } label: {

                    ZStack {

                        Circle()
                            .fill(
                                canSend
                                ? Color.accentColor
                                : Color.secondary.opacity(0.12)
                            )

                        Image(
                            systemName: "arrow.up"
                        )
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            canSend
                            ? Color.white
                            : Color.secondary
                        )
                    }
                    .frame(
                        width: 36,
                        height: 36
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .help("Send message")
            }
            .padding(10)
            .background(
                RoundedRectangle(
                    cornerRadius: 16
                )
                .fill(
                    Color(nsColor: .textBackgroundColor)
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 16
                )
                .stroke(
                    Color.secondary.opacity(0.2),
                    lineWidth: 1
                )
            )
            .padding(
                .horizontal,
                20
            )
            .padding(
                .vertical,
                14
            )

            // MARK: - Status

            HStack {

                if isListening {

                    Image(systemName: "waveform")
                        .foregroundStyle(.red)

                    Text("Listening...")
                        .foregroundStyle(.red)

                } else if isThinking {

                    ProgressView()
                        .controlSize(.small)

                    Text("Thinking...")
                        .foregroundStyle(.secondary)

                } else {

                    Text(
                        "Voice Assistant runs locally on your Mac"
                    )
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .font(.caption)
            .padding(
                .horizontal,
                24
            )
            .padding(
                .bottom,
                10
            )
        }
    }

    // MARK: - Send State

    private var canSend: Bool {

        !text
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
        && !isThinking
    }
}
