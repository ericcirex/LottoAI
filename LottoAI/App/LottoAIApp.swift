import SwiftUI
import UserNotifications
// MARK: - Firebase SDK
// 添加方法: Xcode → File → Add Package Dependencies
// URL: https://github.com/firebase/firebase-ios-sdk
// 选择: FirebaseAuth, FirebaseFirestore
import FirebaseCore
import FirebaseAuth

@main
struct LottoAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var authManager = AuthenticationManager.shared

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.dark)
                .onReceive(NotificationCenter.default.publisher(for: .newDrawResult)) { notification in
                    // 处理新开奖结果通知
                    if let lottery = notification.userInfo?["lottery"] as? String {
                        if lottery == "powerball" {
                            appState.selectedLottery = .powerball
                        } else if lottery == "mega_millions" {
                            appState.selectedLottery = .megaMillions
                        }
                    }
                }
        }
    }
}

// MARK: - App Delegate (推送通知处理)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 初始化 Firebase
        FirebaseApp.configure()

        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self

        // 请求推送权限
        requestNotificationPermission()

        // 注册远程推送
        application.registerForRemoteNotifications()

        return true
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                print("✅ Push notification permission granted")
            }
            if let error = error {
                print("❌ Notification permission error: \(error)")
            }
        }
    }

    // 获取 Device Token (用于 APNs)
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Device Token: \(token)")

        // TODO: 如果使用 OneSignal，在这里设置 device token
        // OneSignal.setDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error)")
    }

    // 前台收到通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 前台也显示通知横幅
        completionHandler([.banner, .badge, .sound])
    }

    // 用户点击通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // 处理通知点击
        handleNotification(userInfo)

        completionHandler()
    }

    private func handleNotification(_ userInfo: [AnyHashable: Any]) {
        if let type = userInfo["type"] as? String {
            switch type {
            case "draw_result":
                // 新开奖结果通知
                NotificationCenter.default.post(
                    name: .newDrawResult,
                    object: nil,
                    userInfo: userInfo as? [String: Any]
                )
            default:
                break
            }
        }
    }
}

// MARK: - 通知名称
extension Notification.Name {
    static let newDrawResult = Notification.Name("newDrawResult")
}

/// 全局应用状态
@MainActor
class AppState: ObservableObject {
    @Published var selectedLottery: LotteryType = .powerball
    @Published var isLoading: Bool = false
    @Published var todayPredictionCount: Int = 0
    @Published var savedPredictions: [SavedPrediction] = []

    private let savedPredictionsKey = Constants.CacheKeys.savedPredictions

    init() {
        loadSavedPredictions()
    }

    // MARK: - 保存预测

    func savePrediction(_ prediction: Prediction, lottery: LotteryType) {
        let saved = SavedPrediction(
            id: UUID(),
            prediction: prediction,
            lottery: lottery,
            savedAt: Date()
        )
        savedPredictions.insert(saved, at: 0)
        persistSavedPredictions()
    }

    func deletePrediction(_ saved: SavedPrediction) {
        savedPredictions.removeAll { $0.id == saved.id }
        persistSavedPredictions()
    }

    private func loadSavedPredictions() {
        if let data = UserDefaults.standard.data(forKey: savedPredictionsKey),
           let decoded = try? JSONDecoder().decode([SavedPrediction].self, from: data) {
            savedPredictions = decoded
        }
    }

    private func persistSavedPredictions() {
        if let encoded = try? JSONEncoder().encode(savedPredictions) {
            UserDefaults.standard.set(encoded, forKey: savedPredictionsKey)
        }
    }

    // MARK: - 免费版限制检查

    func canMakePrediction(isPremium: Bool) -> Bool {
        if isPremium { return true }
        return todayPredictionCount < Constants.FreeLimit.dailyPredictions
    }

    func incrementPredictionCount() {
        todayPredictionCount += 1
    }
}

/// 保存的预测
struct SavedPrediction: Identifiable, Codable {
    let id: UUID
    let prediction: Prediction
    let lottery: LotteryType
    let savedAt: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: savedAt)
    }
}
