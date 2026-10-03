import Foundation

final class OllamaClient {

    private let endpoint =
        URL(string: "http://localhost:11434/api/chat")!

    private let model = "qwen3:4b"

    private var messages: [[String: String]] = [

        [
            "role": "system",
            "content": """
            You are a local personal voice assistant.

            Rules:

            - Be natural and conversational.
            - Keep responses reasonably short.
            - Do not use markdown unless necessary.
            - Do not use emojis.
            - Respond in the same language as the user.
            - If the user speaks Hinglish, respond in Hinglish.
            - Never claim you performed an action unless the application actually performed it.
            """
        ]
    ]

    func ask(
        _ prompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {

        messages.append([
            "role": "user",
            "content": prompt
        ])

        var request = URLRequest(url: endpoint)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body: [String: Any] = [

            "model": model,

            "messages": messages,

            "stream": false
        ]

        do {

            request.httpBody =
                try JSONSerialization.data(
                    withJSONObject: body
                )

        } catch {

            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(
            with: request
        ) { [weak self] data, response, error in

            if let error = error {

                completion(.failure(error))
                return
            }

            guard let data = data else {

                completion(
                    .failure(
                        NSError(
                            domain: "OllamaClient",
                            code: 1,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "No response from Ollama"
                            ]
                        )
                    )
                )

                return
            }

            do {

                let json =
                    try JSONSerialization.jsonObject(
                        with: data
                    ) as? [String: Any]

                guard
                    let message =
                        json?["message"] as? [String: Any],

                    let content =
                        message["content"] as? String

                else {

                    throw NSError(
                        domain: "OllamaClient",
                        code: 2,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Invalid Ollama response"
                        ]
                    )
                }

                let responseText =
                    content.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                // Store the response for conversation context.
                self?.messages.append([
                    "role": "assistant",
                    "content": responseText
                ])

                completion(
                    .success(responseText)
                )

            } catch {

                completion(
                    .failure(error)
                )
            }

        }.resume()
    }
}
