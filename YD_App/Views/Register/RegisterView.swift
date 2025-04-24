//
//  RegisterView.swift
//  YD_App
//
//  Created by Luis Melendez on 24/04/25.
//

import SwiftUI

struct RegisterView: View {
    @StateObject var viewModel = RegisterViewModel()
    var onRegisterSuccess: () -> Void = {}  // Por defecto, hace nada

    @State private var nombres = ""
    @State private var apellidoPaterno = ""
    @State private var apellidoMaterno = ""
    @State private var numeroCelular = ""
    @State private var email = ""
    @State private var password = ""

    @State private var isLoading = false
    @State private var registrationSuccess = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
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

                        if isLoading {
                            ProgressView().padding(.top, 6)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }

                        if registrationSuccess {
                            Text("¡Registro exitoso!")
                                .foregroundColor(.green)
                                .font(.footnote)
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
        }
    }

    func register() {
        isLoading = true
        registrationSuccess = false
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
            isLoading = false
            registrationSuccess = success
            if success {
                onRegisterSuccess()
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

// MARK: Vista previa con un ViewModel inyectado
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
        .previewDevice("iPhone 15 Pro")
    }
}

