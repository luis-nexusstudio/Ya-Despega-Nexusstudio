/*

Abstract:
A struct for accessing generic password keychain items.
*/


import UIKit
import AuthenticationServices
import SwiftUI


class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    /// - Tag: did_finish_launching
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: KeychainItem.currentUserIdentifier) { (credentialState, error) in
            switch credentialState {
            case .authorized:
                break // The Apple ID credential is valid.
            case .revoked, .notFound:
                // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                break
            default:
                break
            }
        }
        return true
    }
}
