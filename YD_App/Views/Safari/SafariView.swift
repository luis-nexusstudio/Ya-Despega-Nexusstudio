// SafariView.swift
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false

        let vc = SFSafariViewController(url: url, configuration: config)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: SafariView

        init(_ parent: SafariView) {
            self.parent = parent
        }

        // iOS 11+ recibe aquí las redirecciones HTTP 3xx
        func safariViewController(_ controller: SFSafariViewController,
                                  initialLoadDidRedirectTo targetURL: URL) {
            print("SafariViewController redirected to -> scheme: \(targetURL.scheme ?? "nil"), host: \(targetURL.host ?? "nil"), url: \(targetURL.absoluteString)")
            guard targetURL.scheme == "ydapp" else { return }
            // 1) Lanza el esquema (va al AppDelegate)
            UIApplication.shared.open(targetURL, options: [:]) { success in
                print("UIApplication.shared.open returned success: \(success)")
            }
            // 2) Cierra automáticamente el SafariViewController
            controller.dismiss(animated: true) {
                print("SafariViewController dismissed after redirect")
            }
        }

        // También podemos detectar cuándo el usuario toca 'Done'
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            print("SafariViewController did finish (user tapped Done)")
        }
    }
}

