import Foundation

struct ModelsResponse: Decodable {
    let models: [Model]
}

struct OutputResponse: Decodable {
    let output: [Output]
}

struct Output: Decodable {
    let type: String
    let content: String
}

struct Model: Decodable {
    let type: String
    let publisher: String
    let key: String
    let displayName: String
    let loadedInstances: [LoadedInstance]
    
    var isLoaded: Bool {
        !loadedInstances.isEmpty
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case publisher
        case key
        case displayName = "display_name"
        case loadedInstances = "loaded_instances"
    }
}

struct ChatRequest: Encodable {
    let model: String
    let input: String
}

struct LoadedInstance: Decodable {
    let id: String
}

let sourceLanguage = "spanish"
let targetLanguage = "english"
let textToTranslate = "Tengo un problema con el código y necesito ayuda"

let modelKey = "qwen/qwen3-1.7b"

let url_path = "http://127.0.0.1:1234/api/v1/"
let modelsURL = URL(string: url_path + "models")!
let chat_url = URL(string: url_path + "chat")!

let prompt = """
Translate the following text from \(sourceLanguage) to \(targetLanguage).
Return only the translation.
/no_think
\(textToTranslate)
"""

let body = ChatRequest(
    model: modelKey,
    input: prompt
)

do {
    // 1. Check model
    var request = URLRequest(url: modelsURL)
    request.httpMethod = "GET"

    let (data, _) = try await URLSession.shared.data(for: request)

    let results = try JSONDecoder().decode(
        ModelsResponse.self,
        from: data
    )

    guard results.models.contains(where: { model in
        model.key == modelKey && model.isLoaded
    }) else {
        print("Error: the model \(modelKey) is not loaded in LM Studio")
        exit(1)
    }

    // 2. Translation request
    var chatRequest = URLRequest(url: chat_url)

    chatRequest.httpMethod = "POST"

    chatRequest.setValue(
        "application/json",
        forHTTPHeaderField: "Content-Type"
    )

    chatRequest.httpBody = try JSONEncoder().encode(body)

    let (post_data, _) = try await URLSession.shared.data(
        for: chatRequest
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
