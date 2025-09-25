import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case email, password
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primaryAccent)
                    
                    Text("MediStock")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(isSignUpMode ? "Create your account" : "Welcome back")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    CustomTextField(
                        "Email",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    .focused($focusedField, equals: .email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    
                    CustomTextField(
                        "Password",
                        text: $password,
                        isSecure: true
                    )
                    .focused($focusedField, equals: .password)
                }
                
                // Error Message
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    PrimaryButton(
                        isSignUpMode ? "Create Account" : "Sign In",
                        isLoading: authViewModel.isLoading
                    ) {
                        Task {
                            if isSignUpMode {
                                await authViewModel.signUp(email: email, password: password)
                            } else {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        }
                    }
                    .disabled(!isFormValid)
                    
                    SecondaryButton(
                        isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up"
                    ) {
                        isSignUpMode.toggle()
                        authViewModel.clearError()
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                if isFormValid {
                    Task {
                        if isSignUpMode {
                            await authViewModel.signUp(email: email, password: password)
                        } else {
                            await authViewModel.signIn(email: email, password: password)
                        }
                    }
                }
            case .none:
                break
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
