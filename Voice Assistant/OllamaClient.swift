import Foundation

final class OllamaClient {

    private let endpoint =
        URL(string: "http://localhost:11434/api/chat")!

    private let model = "qwen3:4b"

    // MARK: - Ask

    func ask(
        _ prompt: String,
        context: [[String: String]],
        completion: @escaping (Result<String, Error>) -> Void
    ) {

        var messages = context

        // Add the new user message to the selected
        // conversation context.
        messages.append(
            [
                "role": "user",
                "content": prompt
            ]
        )

        var request = URLRequest(
            url: endpoint
        )

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

            completion(
                .failure(error)
            )

            return
        }

        URLSession.shared.dataTask(
            with: request
        ) { data, response, error in

            if let error = error {

                completion(
                    .failure(error)
                )

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
                        json?["message"]
                            as? [String: Any],

                    let content =
                        message["content"]
                            as? String

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
