import AppKit
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let client = LMStudioClient(
        baseURL: URL(string: "http://127.0.0.1:1234/api/v1/")!,
        modelKey: "qwen/qwen3-1.7b"
    )
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var globalHotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainMenu()
        configureStatusItem()
        configurePopover()
        registerGlobalHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalHotKey = nil
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem.button else { return }

        button.image = NSImage(
            systemSymbolName: "character.bubble.fill",
            accessibilityDescription: "Local Translator"
        )
        button.image?.isTemplate = true
        button.toolTip = "Local Translator (⌥T)"
        button.target = self
        button.action = #selector(togglePopover)
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")

        editMenu.addItem(
            withTitle: "Cut",
            action: #selector(NSText.cut(_:)),
            keyEquivalent: "x"
        )
        editMenu.addItem(
            withTitle: "Copy",
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        editMenu.addItem(
            withTitle: "Paste",
            action: #selector(NSText.paste(_:)),
            keyEquivalent: "v"
        )
        editMenu.addItem(
            withTitle: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )

        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func configurePopover() {
        let viewController = TranslatorViewController(client: client)
        popover = NSPopover()
        popover.contentViewController = viewController
        popover.contentSize = NSSize(width: 560, height: 470)
        popover.behavior = .transient
        popover.animates = true
    }

    private func registerGlobalHotKey() {
        globalHotKey = GlobalHotKey(keyCode: 17, modifiers: UInt32(optionKey)) { [weak self] in
            self?.togglePopover()
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
            return
        }

        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        NSApp.activate(ignoringOtherApps: true)

        if let viewController = popover.contentViewController as? TranslatorViewController {
            viewController.focusInput()
        }
    }
}
