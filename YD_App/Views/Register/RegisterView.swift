//
//  RegisterView.swift
//  YD_App
//
//  Created by Luis Melendez on 24/04/25.
//

import SwiftUI

enum RegisterState {
    case idle
    case loading
    case success
    case error
}

struct RegisterView: View {
    @StateObject var viewModel = RegisterViewModel()
    var onRegisterSuccess: () -> Void = {}

    @State private var nombres = ""
    @State private var apellidoPaterno = ""
    @State private var apellidoMaterno = ""
    @State private var numeroCelular = ""
    @State private var email = ""
    @State private var password = ""

    @State private var registerState: RegisterState = .idle

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    Text("Crea tu cuenta")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 60)

                    VStack(spacing: 20) {
                        Group {
                            ModernField(icon: "person.text.rectangle", title: "Nombres", placeholder: "Luis Manuel", text: $nombres)
                            ModernField(icon: "person", title: "Apellido paterno", placeholder: "Melendez", text: $apellidoPaterno)
                            ModernField(icon: "person", title: "Apellido materno", placeholder: "Rocha", text: $apellidoMaterno)
                            ModernField(icon: "phone", title: "Número celular", placeholder: "4772948285", text: $numeroCelular, keyboard: .phonePad)
                            ModernField(icon: "envelope", title: "Correo electrónico", placeholder: "ejemplo@correo.com", text: $email, keyboard: .emailAddress)
                            ModernSecureField(icon: "lock", title: "Contraseña", placeholder: "Mínimo 6 caracteres", text: $password)
                        }

                        Button(action: register) {
                            Text("Registrarme")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(14)
                                .shadow(radius: 5)
                        }
                        .disabled(registerState == .loading)
                        .opacity(registerState == .loading ? 0.6 : 1.0)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }

            if registerState != .idle {
                RegisterFeedbackOverlay(state: registerState)
            }
        }
    }

    func register() {
        registerState = .loading
        viewModel.errorMessage = nil

        let newUser = UserModel(
            nombres: nombres,
            apellidoPaterno: apellidoPaterno,
            apellidoMaterno: apellidoMaterno,
            numeroCelular: numeroCelular,
            rolId: "1",
            fechaRegistro: Date()
        )

        viewModel.registerUser(email: email, password: password, userData: newUser) { success in
            if success {
                registerState = .success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onRegisterSuccess()
                    registerState = .idle
                }
            } else {
                registerState = .error
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    registerState = .idle
                }
            }
        }
    }
}

struct ModernField: View {
    var icon: String
    var title: String
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.gray)

            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }
}

struct ModernSecureField: View {
    var icon: String
    var title: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.gray)

            SecureField(placeholder, text: $text)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }
}

struct RegisterFeedbackOverlay: View {
    var state: RegisterState

    @State private var showLogo = false
    @State private var shimmerOffset: CGFloat = 250

    var body: some View {
        ZStack {
            if state == .loading {
                Color.white.opacity(0.9)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1)) {
                            showLogo = true
                        }
                    }

                VStack(spacing: 20) {
                    if showLogo {
                        ZStack {
                            Image("YaDespegaLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .opacity(0)

                            Image("YaDespegaLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.black.opacity(0.0),
                                            Color.black.opacity(1.0),
                                            Color.black.opacity(0.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .rotationEffect(.degrees(30))
                                    .offset(x: shimmerOffset)
                                )
                                .onAppear {
                                    shimmerOffset = -250
                                    withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                                        shimmerOffset = 250
                                    }
                                }
                        }

                        Text("Registrando usuario...")
                            .foregroundColor(.black)
                            .font(.headline)
                            .transition(.opacity)
                            .animation(.easeIn(duration: 1), value: showLogo)
                    }
                }
            }

            if state == .success {
                Color.white.ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.green)

                    Text("¡Registro exitoso!")
                        .foregroundColor(.black)
                        .font(.headline)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: state)
            }

            if state == .error {
                Color.white.ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "xmark.octagon.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.red)

                    Text("Ocurrió un error")
                        .foregroundColor(.black)
                        .font(.headline)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: state)
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .previewDevice("iPhone 15 Pro")
    }
}
