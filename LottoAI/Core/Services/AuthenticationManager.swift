import Foundation
import AuthenticationServices
import CryptoKit
import SwiftUI
import UIKit
// Firebase SDK (暂时禁用)
// import FirebaseAuth
// import FirebaseFirestore

/// 用户认证管理器 (本地模式 - Firebase 暂时禁用)
@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()

    // MARK: - Published Properties
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Apple Sign-In
    private var currentNonce: String?
    private var signInContinuation: CheckedContinuation<AppUser, Error>?

    // MARK: - Init
    private override init() {
        super.init()
        checkExistingSession()
    }

    // MARK: - Check Existing Session
    private func checkExistingSession() {
        // 从 UserDefaults 读取缓存的用户
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(AppUser.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    // MARK: - Apple Sign In
    func signInWithApple() async throws -> AppUser {
        return try await withCheckedThrowingContinuation { continuation in
            self.signInContinuation = continuation

            let nonce = randomNonceString()
            currentNonce = nonce

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Sign Out
    func signOut() {
        // Firebase sign out (暂时禁用)
        // do {
        //     try Auth.auth().signOut()
        // } catch {
        //     print("Firebase sign out error: \(error)")
        // }

        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }

    // MARK: - Delete Account
    func deleteAccount() async throws {
        // Firebase 删除 (暂时禁用)
        // guard let user = currentUser else { return }
        // try await Firestore.firestore().collection("users").document(user.id).delete()
        // try await Auth.auth().currentUser?.delete()

        signOut()
    }

    // MARK: - Save User Locally
    private func saveUserLocally(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUser")
        }
    }

    // MARK: - Update User Stats
    func updateUserStats(predictionsGenerated: Int = 0, ticketsScanned: Int = 0) async {
        guard var user = currentUser else { return }

        user.stats.totalPredictions += predictionsGenerated
        user.stats.ticketsScanned += ticketsScanned
        user.stats.lastActiveAt = Date()

        currentUser = user
        saveUserLocally(user)
    }

    // MARK: - Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            signInContinuation?.resume(throwing: AuthError.invalidCredential)
            return
        }

        // 获取用户信息
        let userID = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName

        let displayName: String
        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            displayName = "\(givenName) \(familyName)"
        } else if let givenName = fullName?.givenName {
            displayName = givenName
        } else {
            displayName = "Lottery Fan"
        }

        // 创建本地用户 (Firebase 暂时禁用)
        let user = AppUser(
            id: userID,
            email: email,
            displayName: displayName,
            createdAt: Date(),
            stats: UserStats()
        )

        saveUserLocally(user)
        self.currentUser = user
        self.isAuthenticated = true
        signInContinuation?.resume(returning: user)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                signInContinuation?.resume(throwing: AuthError.cancelled)
            case .failed:
                signInContinuation?.resume(throwing: AuthError.failed)
            case .invalidResponse:
                signInContinuation?.resume(throwing: AuthError.invalidResponse)
            case .notHandled:
                signInContinuation?.resume(throwing: AuthError.notHandled)
            default:
                signInContinuation?.resume(throwing: AuthError.unknown)
            }
        } else {
            signInContinuation?.resume(throwing: error)
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidCredential
    case invalidNonce
    case invalidToken
    case cancelled
    case failed
    case invalidResponse
    case notHandled
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid credential"
        case .invalidNonce: return "Invalid nonce"
        case .invalidToken: return "Invalid token"
        case .cancelled: return "Sign in was cancelled"
        case .failed: return "Sign in failed"
        case .invalidResponse: return "Invalid response"
        case .notHandled: return "Request not handled"
        case .unknown: return "Unknown error"
        }
    }
}
