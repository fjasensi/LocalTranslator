import Foundation

struct ModelsResponse: Codable {
    let models: [Model]
}

struct OutputResponse: Codable {
    let output: [Output]
}

struct Output: Codable {
    let type: String
    let content: String
}

struct Model: Codable {
    let type: String
    let publisher: String
    let key: String
    let display_name: String
    let loaded_instances: [LoadedInstances]
}

struct ChatRequest: Codable {
    let model: String
    let input: String
}

struct LoadedInstances: Codable {
    let id: String
}

let origin_language = "spanish"
let destination_language = "english"
let text_to_translate = "Tengo un problema con el código y necesito ayuda"

let model_name = "qwen/qwen3-1.7b"

let url_path = "http://127.0.0.1:1234/api/v1/"
let model_url = URL(string: url_path + "models")!
let chat_url = URL(string: url_path + "chat")!

let prompt = """
Translate the following text from \(origin_language) to \(destination_language).
Return only the translation.
/no_think
\(text_to_translate)
"""

let body = ChatRequest(
    model: model_name,
    input: prompt
)

do {
    // 1. Check model
    var request = URLRequest(url: model_url)
    request.httpMethod = "GET"

    let (data, _) = try await URLSession.shared.data(for: request)

    let results = try JSONDecoder().decode(
        ModelsResponse.self,
        from: data
    )

    guard results.models.contains(where: {
        $0.key == model_name &&
        !$0.loaded_instances.isEmpty
    }) else {
        print("Error: the model \(model_name) is not loaded in LM Studio")
        exit(1)
    }

    // 2. Translation request
    var post_request = URLRequest(url: chat_url)

    post_request.httpMethod = "POST"

    post_request.setValue(
        "application/json",
        forHTTPHeaderField: "Content-Type"
    )

    post_request.httpBody = try JSONEncoder().encode(body)

    let (post_data, _) = try await URLSession.shared.data(
        for: post_request
    )

    let post_results = try JSONDecoder().decode(
        OutputResponse.self,
        from: post_data
    )

    guard let message = post_results.output.first(where: {
        $0.type == "message"
    }) else {
        print("Error: LM Studio didn't return any message")
        exit(1)
    }

    let result = message.content.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    print(result)

} catch {
    print("Error: \(error)")
}
