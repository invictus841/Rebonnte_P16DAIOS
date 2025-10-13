//
//  UIComponents.swift
//  MediStock
//
//  Created by Alexandre Talatinian on 25/09/2025.
//

import SwiftUI

// MARK: - Design System Colors

extension Color {
    static let primaryAccent = Color.blue
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isEnabled
                        ? (configuration.isPressed ? Color.primaryAccent.opacity(0.8) : Color.primaryAccent)
                        : Color.gray.opacity(0.6)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(isEnabled ? .primaryAccent : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isEnabled ? Color.primaryAccent : .gray.opacity(0.6),
                        lineWidth: 1.5
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                configuration.isPressed
                                ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                                : Color.clear
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Button Components

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    
    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .opacity(isLoading ? 0.7 : 1.0)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : "Double tap to activate")
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    
    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryAccent))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .opacity(isLoading ? 0.7 : 1.0)
            }
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : "Double tap to activate")
    }
}

// MARK: - Custom Text Field

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let onCommit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        onCommit: (() -> Void)? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder.isEmpty ? title : placeholder
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.onCommit = onCommit
    }
    
    private var borderColor: Color {
        if isFocused {
            return .primaryAccent
        }
        return colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.05)
        : Color.black.opacity(0.02)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .onSubmit { onCommit?() }
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .onSubmit { onCommit?() }
                }
            }
            .focused($isFocused)
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(text.isEmpty ? "Empty text field" : text)
    }
}

// MARK: - Custom Number Field

struct NumberField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        _ title: String,
        value: Binding<Int>,
        in range: ClosedRange<Int> = 0...9999,
        step: Int = 1
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
    }
    
    private var borderColor: Color {
        if isFocused {
            return .primaryAccent
        }
        return colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.05)
        : Color.black.opacity(0.02)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                Button(action: {
                    let newValue = max(range.lowerBound, value - step)
                    if newValue != value {
                        value = newValue
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }) {
                    Image(systemName: "minus")
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                
                TextField("", value: $value, format: .number)
                    .focused($isFocused)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(minWidth: 60)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(backgroundColor)
                    .onChange(of: value) { _, newValue in
                        value = max(range.lowerBound, min(range.upperBound, newValue))
                    }
                
                Button(action: {
                    let newValue = min(range.upperBound, value + step)
                    if newValue != value {
                        value = newValue
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }) {
                    Image(systemName: "plus")
                        .frame(width: 36, height: 36)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(range.upperBound, value + step)
            case .decrement:
                value = max(range.lowerBound, value - step)
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let systemName: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        systemName: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemName = systemName
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemName)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}
