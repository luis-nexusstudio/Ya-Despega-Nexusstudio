//
//  RegisterViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 24/04/25.
//

import FirebaseAuth
import FirebaseFirestore
import Firebase
import SwiftUI

class RegisterViewModel: ObservableObject {
    @Published var errorMessage: String?

    func registerUser(email: String, password: String, userData: UserModel, completion: @escaping (Bool) -> Void) {
        let auth = Auth.auth()
        
        // Verifica si el email ya está en uso (con cualquier proveedor)
        auth.fetchSignInMethods(forEmail: email) { methods, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }

            // Si ya tiene método registrado, no permitimos continuar
            if let methods = methods, !methods.isEmpty {
                self.errorMessage = "El correo ya está registrado con otro método de acceso."
                completion(false)
                return
            }

            // Crear usuario en Firebase Auth
            auth.createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                guard let uid = result?.user.uid else {
                    self.errorMessage = "No se pudo obtener el UID."
                    completion(false)
                    return
                }

                // Guardar información extra en Firestore
                let db = Firestore.firestore()
                let userDict: [String: Any] = [
                    "nombres": userData.nombres,
                    "apellido_paterno": userData.apellidoPaterno,
                    "apellido_materno": userData.apellidoMaterno,
                    "numero_celular": userData.numeroCelular,
                    "rol_id": userData.rolId,
                    "fecha_registro": Timestamp(date: userData.fechaRegistro),
                    "email": email
                ]

                db.collection("usuarios").document(uid).setData(userDict) { error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        completion(false)
                        return
                    }

                    completion(true)
                }
            }
        }
    }
}
