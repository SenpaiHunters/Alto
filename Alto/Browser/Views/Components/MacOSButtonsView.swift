import AppKit
import SwiftUI

// MARK: - MacButtonsViewNew

struct MacButtonsViewNew: View {
    var body: some View {
        NSMacButtons()
    }
}

// MARK: - NSMacButtons

struct NSMacButtons: NSViewRepresentable {
    private let btnTypes: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]

    func makeNSView(context: Context) -> NSView {
        let stack = NSStackView()
        stack.spacing = 6

        btnTypes.compactMap { NSWindow.standardWindowButton($0, for: .titled) }
            .forEach(stack.addArrangedSubview)

        return stack
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - MacButtonsViewModel

@Observable
final class MacButtonsViewModel {
    private(set) var buttonState: ButtonState = .idle

    enum ButtonType: CaseIterable {
        case close
        case minimize
        case fullscreen

        var fillColor: Color {
            switch self {
            case .close: Color(red: 236 / 255, green: 106 / 255, blue: 94 / 255)
            case .minimize: Color(red: 254 / 255, green: 188 / 255, blue: 46 / 255)
            case .fullscreen: Color(red: 40 / 255, green: 200 / 255, blue: 65 / 255)
            }
        }

        var strokeColor: Color {
            switch self {
            case .close: Color(red: 208 / 255, green: 78 / 255, blue: 69 / 255)
            case .minimize: Color(red: 224 / 255, green: 156 / 255, blue: 21 / 255)
            case .fullscreen: Color(red: 21 / 255, green: 169 / 255, blue: 31 / 255)
            }
        }

        var action: () -> () {
            switch self {
            case .close: { NSApp.keyWindow?.close() }
            case .minimize: { NSApp.keyWindow?.miniaturize(nil) }
            case .fullscreen: { NSApp.keyWindow?.toggleFullScreen(nil) }
            }
        }

        var imageName: String {
            switch self {
            case .close: "minus"
            case .minimize: "xmark"
            case .fullscreen: "square.split.diagonal.fill"
            }
        }
    }

    enum ButtonState {
        case idle
        case active
        case hover
    }

    func getButtonColors(for buttonType: ButtonType) -> (fill: Color, stroke: Color) {
        buttonState != .idle
            ? (buttonType.fillColor, buttonType.strokeColor)
            : (Color.primary.opacity(0.2), Color.clear)
    }

    func updateHoverState(_ isHovered: Bool) {
        buttonState = isHovered ? .hover : .idle
    }
}

// MARK: - MacButtonsView

struct MacButtonsView: View {
    private let viewModel = MacButtonsViewModel()

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 7.5) {
                ForEach(MacButtonsViewModel.ButtonType.allCases, id: \.self) { buttonType in
                    MacButtonView(viewModel: viewModel, buttonType: buttonType)
                }
            }
            .onHover(perform: viewModel.updateHoverState)
            .frame(height: geometry.size.height)
            .padding(.leading, geometry.size.height / 3 - 2)
        }
    }
}

// MARK: - MacButtonView

struct MacButtonView: View {
    let viewModel: MacButtonsViewModel
    let buttonType: MacButtonsViewModel.ButtonType

    var body: some View {
        Button(action: buttonType.action) {
            let colors = viewModel.getButtonColors(for: buttonType)

            if viewModel.buttonState == .idle {
                Circle()
                    .fill(colors.fill)
                    .frame(width: 12.5, height: 12.5)
            } else {
                Circle()
                    .fill(colors.stroke)
                    .overlay(
                        Circle()
                            .inset(by: 0.5)
                            .fill(colors.fill)
                    )
                    .frame(width: 12.5, height: 12.5)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
