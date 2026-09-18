import AppKit

private enum TranslationDirection: Equatable {
    case englishToSpanish
    case spanishToEnglish

    var sourceLanguage: String {
        switch self {
        case .englishToSpanish:
            return "english"
        case .spanishToEnglish:
            return "spanish"
        }
    }

    var targetLanguage: String {
        switch self {
        case .englishToSpanish:
            return "spanish"
        case .spanishToEnglish:
            return "english"
        }
    }

    var sourceDisplayName: String {
        self == .englishToSpanish ? "English" : "Spanish"
    }

    var targetDisplayName: String {
        self == .englishToSpanish ? "Spanish" : "English"
    }

    var arrow: String {
        self == .englishToSpanish ? "→" : "←"
    }

    var toggled: TranslationDirection {
        self == .englishToSpanish ? .spanishToEnglish : .englishToSpanish
    }
}

final class TranslatorViewController: NSViewController {
    private let client: LMStudioClient
    private var translationDirection: TranslationDirection = .englishToSpanish
    private let sourceLanguageLabel = NSTextField(labelWithString: "English")
    private let targetLanguageLabel = NSTextField(labelWithString: "Spanish")
    private let directionButton = NSButton(title: "→", target: nil, action: nil)
    private let inputTextView = NSTextView()
    private let outputTextView = NSTextView()
    private let translateButton = NSButton(title: "Translate", target: nil, action: nil)
    private let clearButton = NSButton(title: "Clear", target: nil, action: nil)
    private let quitButton = NSButton(title: "Quit", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "Ready")

    init(client: LMStudioClient) {
        self.client = client
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureControls()
        buildLayout()
    }

    func focusInput() {
        view.window?.makeFirstResponder(inputTextView)
    }

    private func configureControls() {
        sourceLanguageLabel.alignment = .center
        sourceLanguageLabel.font = .boldSystemFont(ofSize: 12)
        targetLanguageLabel.alignment = .center
        targetLanguageLabel.font = .boldSystemFont(ofSize: 12)

        directionButton.bezelStyle = .texturedRounded
        directionButton.font = .boldSystemFont(ofSize: 16)
        directionButton.toolTip = "Switch translation direction"
        directionButton.setAccessibilityLabel("Switch translation direction")
        directionButton.target = self
        directionButton.action = #selector(toggleDirection)

        inputTextView.font = .systemFont(ofSize: 14)
        inputTextView.isRichText = false
        inputTextView.isSelectable = true
        inputTextView.allowsUndo = true
        inputTextView.isAutomaticQuoteSubstitutionEnabled = false
        inputTextView.isAutomaticDashSubstitutionEnabled = false

        outputTextView.font = .systemFont(ofSize: 14)
        outputTextView.isRichText = false
        outputTextView.isEditable = false
        outputTextView.isSelectable = true
        outputTextView.drawsBackground = true
        outputTextView.backgroundColor = .underPageBackgroundColor

        translateButton.keyEquivalent = "\r"
        translateButton.target = self
        translateButton.action = #selector(translate)

        clearButton.target = self
        clearButton.action = #selector(clear)

        quitButton.target = self
        quitButton.action = #selector(quit)

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = .systemFont(ofSize: 11)
    }

    private func buildLayout() {
        let titleLabel = NSTextField(labelWithString: "Local Translator")
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.alignment = .center

        let titleContainer = NSView()
        titleContainer.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let inputLabel = NSTextField(labelWithString: "Text to translate")
        inputLabel.font = .boldSystemFont(ofSize: 12)

        let outputLabel = NSTextField(labelWithString: "Translation")
        outputLabel.font = .boldSystemFont(ofSize: 12)

        let inputScrollView = makeScrollView(for: inputTextView)
        let outputScrollView = makeScrollView(for: outputTextView)

        let directionContainer = NSView()
        directionContainer.addSubview(sourceLanguageLabel)
        directionContainer.addSubview(directionButton)
        directionContainer.addSubview(targetLanguageLabel)
        sourceLanguageLabel.translatesAutoresizingMaskIntoConstraints = false
        directionButton.translatesAutoresizingMaskIntoConstraints = false
        targetLanguageLabel.translatesAutoresizingMaskIntoConstraints = false

        let actions = NSStackView(views: [translateButton, clearButton, quitButton])
        actions.orientation = .horizontal
        actions.distribution = .fillEqually
        actions.spacing = 8

        let stack = NSStackView(views: [
            titleContainer,
            directionContainer,
            inputLabel,
            inputScrollView,
            outputLabel,
            outputScrollView,
            actions,
            statusLabel
        ])
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = 10

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -18),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: stack.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            directionContainer.heightAnchor.constraint(equalToConstant: 28),
            directionButton.centerXAnchor.constraint(equalTo: directionContainer.centerXAnchor),
            directionButton.centerYAnchor.constraint(equalTo: directionContainer.centerYAnchor),
            directionButton.widthAnchor.constraint(equalToConstant: 44),
            directionButton.heightAnchor.constraint(equalToConstant: 28),
            sourceLanguageLabel.trailingAnchor.constraint(equalTo: directionButton.leadingAnchor, constant: -8),
            sourceLanguageLabel.centerYAnchor.constraint(equalTo: directionButton.centerYAnchor),
            sourceLanguageLabel.widthAnchor.constraint(equalToConstant: 70),
            targetLanguageLabel.leadingAnchor.constraint(equalTo: directionButton.trailingAnchor, constant: 8),
            targetLanguageLabel.centerYAnchor.constraint(equalTo: directionButton.centerYAnchor),
            targetLanguageLabel.widthAnchor.constraint(equalToConstant: 70),
            inputScrollView.heightAnchor.constraint(equalToConstant: 105),
            outputScrollView.heightAnchor.constraint(equalToConstant: 105),
            actions.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func makeScrollView(for textView: NSTextView) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = textView
        textView.minSize = .zero
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        return scrollView
    }

    @objc private func toggleDirection() {
        translationDirection = translationDirection.toggled
        sourceLanguageLabel.stringValue = translationDirection.sourceDisplayName
        targetLanguageLabel.stringValue = translationDirection.targetDisplayName
        directionButton.title = translationDirection.arrow
        statusLabel.stringValue = "Ready"
        outputTextView.string = ""
    }

    @objc private func clear() {
        inputTextView.string = ""
        outputTextView.string = ""
        statusLabel.stringValue = "Ready"
        focusInput()
    }

    @objc private func translate() {
        let text = inputTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            statusLabel.stringValue = "Enter some text first"
            focusInput()
            return
        }

        let direction = translationDirection

        translateButton.isEnabled = false
        clearButton.isEnabled = false
        directionButton.isEnabled = false
        statusLabel.stringValue = "Translating…"

        Task { [weak self, client] in
            do {
                let result = try await client.translate(
                    text,
                    from: direction.sourceLanguage,
                    to: direction.targetLanguage
                )

                await MainActor.run {
                    self?.outputTextView.string = result
                    self?.statusLabel.stringValue = "Ready"
                    self?.translateButton.isEnabled = true
                    self?.clearButton.isEnabled = true
                    self?.directionButton.isEnabled = true
                }
            } catch {
                await MainActor.run {
                    self?.statusLabel.stringValue = error.localizedDescription
                    self?.translateButton.isEnabled = true
                    self?.clearButton.isEnabled = true
                    self?.directionButton.isEnabled = true
                }
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
