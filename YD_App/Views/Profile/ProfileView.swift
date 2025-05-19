import SwiftUI

struct ProfileView: View {
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Formulario de información del usuario
                    UserInfoFormSection()
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Opciones adicionales
                    VStack(spacing: 0) {
                        // Cambio de contraseña (centrado, igual que cerrar sesión)
                        NavigationLink(destination: PasswordChangeView()) {
                            HStack {
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.blue)
                                Text("Cambio de contraseña")
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Cerrar sesión (centrado)
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Cerrar sesión")
                                    .foregroundColor(.red)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Tu Perfil")
        }
        .alert("Cerrar sesión", isPresented: $showingLogoutAlert) {
            Button("Cerrar sesión", role: .destructive) {
                // Aquí se realizaría la acción de cerrar sesión
                print("Sesión cerrada")
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("¿Estás seguro que deseas cerrar la sesión?")
        }
    }
}

// Componente separado para el formulario de información de usuario
struct UserInfoFormSection: View {
    // Estructura de datos para la información del usuario
    @State private var userInfo = UserInfo(
        nombres: "Juan Carlos",
        apellidoPaterno: "López",
        apellidoMaterno: "Martínez",
        numeroCelular: "55 1234 5678"
    )
    
    @State private var isEditing = false
    @State private var editedInfo: UserInfo?
    @State private var showingSaveAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Cabecera
            HStack {
                Text("Información Personal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !isEditing {
                    HStack(spacing: 12) {
                        NavigationLink(destination: HelpView()) {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            // Comenzar edición
                            editedInfo = userInfo
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Button(action: {
                            // Guardar cambios - activar alerta
                            print("Intentando mostrar alerta...")
                            showingSaveAlert = true
                        }) {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            // Cancelar edición
                            isEditing = false
                            editedInfo = nil
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            
            // Formulario
            VStack(spacing: 20) {
                // Nombres
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nombres")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isEditing {
                        TextField("Ingrese sus nombres", text: Binding(
                            get: { self.editedInfo?.nombres ?? "" },
                            set: { self.editedInfo?.nombres = $0 }
                        ))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.words)
                    } else {
                        Text(userInfo.nombres)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Apellido Paterno
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apellido Paterno")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isEditing {
                        TextField("Ingrese su apellido paterno", text: Binding(
                            get: { self.editedInfo?.apellidoPaterno ?? "" },
                            set: { self.editedInfo?.apellidoPaterno = $0 }
                        ))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.words)
                    } else {
                        Text(userInfo.apellidoPaterno)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Apellido Materno
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apellido Materno")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isEditing {
                        TextField("Ingrese su apellido materno", text: Binding(
                            get: { self.editedInfo?.apellidoMaterno ?? "" },
                            set: { self.editedInfo?.apellidoMaterno = $0 }
                        ))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.words)
                    } else {
                        Text(userInfo.apellidoMaterno)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Número de Celular
                VStack(alignment: .leading, spacing: 8) {
                    Text("Número de Celular")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isEditing {
                        TextField("Ingrese su número de celular", text: Binding(
                            get: { self.editedInfo?.numeroCelular ?? "" },
                            set: { self.editedInfo?.numeroCelular = $0 }
                        ))
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    } else {
                        Text(userInfo.numeroCelular)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal)
        .alert("Guardar cambios", isPresented: $showingSaveAlert) {
            Button("Confirmar") {
                // Guardar cambios cuando el usuario confirma
                if let editedInfo = editedInfo {
                    userInfo = editedInfo
                    print("Información guardada exitosamente: \(userInfo)")
                }
                isEditing = false
                editedInfo = nil
            }
            Button("Cancelar", role: .cancel) {
                // Si cancela la alerta, no hacer nada
                print("Guardado cancelado")
            }
        } message: {
            Text("¿Estás seguro que deseas guardar los cambios?")
        }
    }
}


// Este componente ya no es necesario, ya que los botones se estilizan directamente
/*
struct MenuButton: View {
    var title: String
    var iconName: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(10)
    }
}
*/

// Estructura de datos para la información del usuario
struct UserInfo {
    var nombres: String
    var apellidoPaterno: String
    var apellidoMaterno: String
    var numeroCelular: String
}

// Vista para mostrar y editar la información del usuario
struct UserInfoView: View {
    var body: some View {
        UserInfoFormSection()
            .navigationTitle("Tu información")
    }
}

struct PasswordChangeView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 20) {
            SecureField("Contraseña actual", text: $currentPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Nueva contraseña", text: $newPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Confirmar contraseña", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Cambiar contraseña") {
                // Aquí se implementaría la lógica para cambiar la contraseña
                print("Cambio de contraseña solicitado")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .navigationTitle("Cambio de contraseña")
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section(header: Text("Preguntas frecuentes")) {
                HelpItem(question: "¿Cómo actualizo mi información?", answer: "Puedes actualizar tu información personal en la sección 'Ver tu información'.")
                HelpItem(question: "¿Olvidé mi contraseña?", answer: "Si olvidaste tu contraseña, puedes usar la opción 'Recuperar contraseña' en la pantalla de inicio de sesión.")
                HelpItem(question: "¿Cómo puedo contactar soporte?", answer: "Puedes contactar a nuestro equipo de soporte al correo soporte@ejemplo.com o llamando al 123-456-7890.")
            }
        }
        .navigationTitle("Ayuda")
    }
}

struct HelpItem: View {
    var question: String
    var answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.headline)
            Text(answer)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
