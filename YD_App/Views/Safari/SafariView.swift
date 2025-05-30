import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var onFinished: () -> Void = {}  // 👈 Callback que se ejecuta al cerrar Safari

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.delegate = context.coordinator
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onFinished: () -> Void

        init(onFinished: @escaping () -> Void) {
            self.onFinished = onFinished
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            print("✅ SafariView: usuario presionó 'Listo' o cerró Safari")
            onFinished()
        }
    }
}
