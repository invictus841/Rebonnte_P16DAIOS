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
    static let primaryBackground = Color.primary
    static let secondaryBackground = Color.secondary
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

struct CircularButtonStyle: ButtonStyle {
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(size: CGFloat = 44, backgroundColor: Color = .primaryAccent, foregroundColor: Color = .white) {
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundColor(foregroundColor)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(configuration.isPressed ? backgroundColor.opacity(0.8) : backgroundColor)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
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

struct IconButton: View {
    let systemName: String
    let action: () -> Void
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let accessibilityLabel: String
    
    init(
        systemName: String,
        size: CGFloat = 44,
        backgroundColor: Color = .accentColor,
        foregroundColor: Color = .white,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.action = action
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.accessibilityLabel = accessibilityLabel
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
        }
        .buttonStyle(CircularButtonStyle(
            size: size,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        ))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to activate")
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
                IconButton(
                    systemName: "minus",
                    size: 36,
                    backgroundColor: .red.opacity(0.8),
                    foregroundColor: .white,
                    accessibilityLabel: "Decrease \(title)"
                ) {
                    let newValue = max(range.lowerBound, value - step)
                    if newValue != value {
                        value = newValue
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
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
                
                IconButton(
                    systemName: "plus",
                    size: 36,
                    backgroundColor: .green.opacity(0.8),
                    foregroundColor: .white,
                    accessibilityLabel: "Increase \(title)"
                ) {
                    let newValue = min(range.upperBound, value + step)
                    if newValue != value {
                        value = newValue
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
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

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading, \(message)")
    }
}

// MARK: - Error View

struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    init(
        title: String = "Something went wrong",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let retryAction = retryAction {
                SecondaryButton("Try Again", action: retryAction)
                    .frame(maxWidth: 200)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(title). \(message)")
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

// MARK: - Preview

#Preview("UIComponents Showcase") {
    @Previewable @State var name = "Aspirin"
    @Previewable @State var email = "user@example.com"
    @Previewable @State var password = ""
    @Previewable @State var aisle = "Aisle 1"
    @Previewable @State var stock = 25
    @Previewable @State var lowStock = 3
    @Previewable @State var highStock = 999
    @Previewable @State var medicineName = ""
    @Previewable @State var formAisle = ""
    @Previewable @State var formStock = 0
    @Previewable @State var isLoading = false
    
    return NavigationView {
        ScrollView {
            LazyVStack(spacing: 30) {
                // MARK: - Header
                VStack(spacing: 8) {
                    Text("UIComponents Showcase")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Custom SwiftUI components for MediStock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // MARK: - Primary Buttons
                GroupBox("Primary Buttons") {
                    VStack(spacing: 16) {
                        PrimaryButton("Save Medicine") { }
                        PrimaryButton("Loading...", isLoading: true) { }
                        PrimaryButton("Disabled") { }
                            .disabled(true)
                    }
                    .padding()
                }
                
                // MARK: - Secondary Buttons
                GroupBox("Secondary Buttons") {
                    VStack(spacing: 16) {
                        SecondaryButton("Cancel") { }
                        SecondaryButton("Loading...", isLoading: true) { }
                        SecondaryButton("Disabled") { }
                            .disabled(true)
                    }
                    .padding()
                }
                
                // MARK: - Icon Buttons
                GroupBox("Icon Buttons") {
                    VStack(spacing: 16) {
                        Text("Stock Management")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            IconButton(
                                systemName: "plus",
                                backgroundColor: .green,
                                accessibilityLabel: "Add"
                            ) { }
                            
                            IconButton(
                                systemName: "minus",
                                backgroundColor: .red,
                                accessibilityLabel: "Remove"
                            ) { }
                            
                            IconButton(
                                systemName: "pencil",
                                backgroundColor: .primaryAccent,
                                accessibilityLabel: "Edit"
                            ) { }
                            
                            IconButton(
                                systemName: "trash",
                                backgroundColor: .orange,
                                accessibilityLabel: "Delete"
                            ) { }
                        }
                    }
                    .padding()
                }
                
                // MARK: - Text Fields
                GroupBox("Text Fields") {
                    VStack(spacing: 16) {
                        CustomTextField("Medicine Name", text: $name)
                        
                        CustomTextField("Email", text: $email, keyboardType: .emailAddress)
                        
                        CustomTextField("Password", text: $password, isSecure: true)
                        
                        CustomTextField("Aisle", text: $aisle, placeholder: "Enter aisle location")
                    }
                    .padding()
                }
                
                // MARK: - Number Fields
                GroupBox("Number Fields") {
                    VStack(spacing: 16) {
                        NumberField("Stock Quantity", value: $stock, in: 0...9999)
                        
                        NumberField("Low Stock Alert", value: $lowStock, in: 0...50, step: 1)
                        
                        NumberField("Bulk Stock", value: $highStock, in: 0...9999, step: 10)
                    }
                    .padding()
                }
                
                // MARK: - App States
                GroupBox("App States") {
                    VStack(spacing: 20) {
                        LoadingView("Fetching medicines...")
                            .frame(height: 80)
                        
                        Divider()
                        
                        ErrorView(
                            title: "Network Error",
                            message: "Unable to connect to the server. Please check your internet connection.",
                            retryAction: { }
                        )
                        .frame(height: 120)
                        
                        Divider()
                        
                        EmptyStateView(
                            systemName: "pills",
                            title: "No Medicines Found",
                            message: "Get started by adding your first medicine to the inventory.",
                            actionTitle: "Add Medicine",
                            action: { }
                        )
                        .frame(height: 160)
                    }
                    .padding()
                }
                
                // MARK: - Real Form Example
                GroupBox("Medicine Creation Form") {
                    VStack(spacing: 16) {
                        Text("Practical Example")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        CustomTextField("Medicine Name", text: $medicineName, placeholder: "Enter medicine name")
                        
                        CustomTextField("Aisle Location", text: $formAisle, placeholder: "e.g., Aisle 1")
                        
                        NumberField("Initial Stock", value: $formStock, in: 0...9999)
                        
                        VStack(spacing: 12) {
                            PrimaryButton("Add Medicine", isLoading: isLoading) {
                                isLoading = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    isLoading = false
                                    // Reset form
                                    medicineName = ""
                                    formAisle = ""
                                    formStock = 0
                                }
                            }
                            
                            SecondaryButton("Cancel") {
                                // Reset form
                                medicineName = ""
                                formAisle = ""
                                formStock = 0
                            }
                        }
                    }
                    .padding()
                }
                
                // MARK: - Dark Mode Preview
                GroupBox("Dark Mode Preview") {
                    VStack(spacing: 16) {
                        Text("Components in Dark Mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        CustomTextField("Medicine Name", text: .constant("Paracetamol"))
                        
                        NumberField("Stock", value: .constant(15))
                        
                        HStack(spacing: 12) {
                            PrimaryButton("Save") { }
                            SecondaryButton("Cancel") { }
                        }
                        
                        HStack(spacing: 16) {
                            IconButton(
                                systemName: "plus",
                                backgroundColor: .green,
                                accessibilityLabel: "Add"
                            ) { }
                            
                            IconButton(
                                systemName: "minus",
                                backgroundColor: .red,
                                accessibilityLabel: "Remove"
                            ) { }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(12)
                    .preferredColorScheme(.dark)
                }
            }
            .padding()
        }
        .navigationTitle("Components")
        .navigationBarTitleDisplayMode(.inline)
    }
}
