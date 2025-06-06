import SwiftUI
import Firebase
import GoogleSignIn

@main
struct YD_AppApp: App {
    // MARK: - Properties
    @StateObject private var authStateManager = AuthStateManager.shared
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var cartViewModel = CartViewModel()
    @StateObject private var eventViewModel: EventViewModel
    @StateObject private var homeViewModel: HomeViewModel

    // MARK: - Constants
    private let eventId = "8avevXHoe4aXoMQEDOic"

    // MARK: - Initialization
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.black

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // 1) Configurar Firebase
        FirebaseApp.configure()

        // 2) Rompemos la captura de `self` pasando eventId a una constante local
        let id = eventId

        // 3) Asignamos a los backing‐storages, no redeclaramos @StateObject
        _eventViewModel = StateObject(wrappedValue: EventViewModel(eventId: id))
        _homeViewModel  = StateObject(wrappedValue: HomeViewModel(eventId: id))
    }

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authStateManager)
                .environmentObject(appCoordinator)
                .environmentObject(cartViewModel)
                .environmentObject(eventViewModel)
                .environmentObject(homeViewModel)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    setupAppearance()
                }
        }
    }

    // MARK: - Appearance
    private func setupAppearance() {
        UINavigationBar.appearance().tintColor = UIColor(named: "PrimaryColor")
        UITabBar.appearance().tintColor      = UIColor(named: "PrimaryColor")
    }
}

// MARK: - RootView y LoadingView
struct RootView: View {
    @EnvironmentObject var authStateManager: AuthStateManager
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                switch authStateManager.authState {
                case .unknown:
                    LoadingView().transition(.opacity)
                case .authenticated:
                    MainView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal:   .move(edge: .leading)
                        ))
                case .unauthenticated:
                    LoginView { print("✅ Login exitoso") }
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal:   .move(edge: .trailing)
                        ))
                }
                
            }
        }
        .animation(.easeInOut(duration: 0.3),
                       value: authStateManager.authState)
    }
}

struct LoadingView: View {
    var body: some View {
        BackgroundGeneralView {
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(
                      CircularProgressViewStyle(tint: Color("PrimaryColor"))
                    )
                    .scaleEffect(1.5)
                Text("Verificando sesión...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}
