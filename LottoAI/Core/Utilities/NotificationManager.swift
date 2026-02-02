import UserNotifications
import UIKit

/// 通知管理器
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - 权限请求

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - 开奖提醒

    /// 设置开奖前提醒 (提前1小时)
    func scheduleDrawReminder(for lottery: String, drawDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Draw Starting Soon!"
        content.body = "\(lottery) draw in 1 hour. Check your lucky numbers!"
        content.sound = .default
        content.badge = 1

        // 开奖前1小时
        let reminderDate = drawDate.addingTimeInterval(-3600)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "draw_reminder_\(lottery)_\(drawDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule draw reminder: \(error)")
            }
        }
    }

    /// 设置每周开奖日提醒
    func scheduleWeeklyReminders() {
        // Powerball: Mon, Wed, Sat at 21:59 ET (1 hour before)
        schedulePowerballReminders()

        // Mega Millions: Tue, Fri at 22:00 ET (1 hour before)
        scheduleMegaMillionsReminders()
    }

    private func schedulePowerballReminders() {
        let weekdays = [2, 4, 7] // Mon, Wed, Sat
        for weekday in weekdays {
            scheduleWeeklyNotification(
                identifier: "powerball_weekly_\(weekday)",
                title: "Powerball Tonight!",
                body: "Draw at 10:59 PM ET. Get your AI prediction now!",
                weekday: weekday,
                hour: 21,
                minute: 59
            )
        }
    }

    private func scheduleMegaMillionsReminders() {
        let weekdays = [3, 6] // Tue, Fri
        for weekday in weekdays {
            scheduleWeeklyNotification(
                identifier: "megamillions_weekly_\(weekday)",
                title: "Mega Millions Tonight!",
                body: "Draw at 11:00 PM ET. Get your AI prediction now!",
                weekday: weekday,
                hour: 22,
                minute: 0
            )
        }
    }

    private func scheduleWeeklyNotification(
        identifier: String,
        title: String,
        body: String,
        weekday: Int,
        hour: Int,
        minute: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone(identifier: "America/New_York")

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 每日财运提醒

    func scheduleDailyFortuneNotification(at hour: Int = 9, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Your Daily Fortune"
        content.body = "Check today's lucky numbers and fortune quote!"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_fortune",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 结果通知

    func scheduleResultNotification(lottery: String, numbers: [Int], special: Int) {
        let content = UNMutableNotificationContent()
        content.title = "\(lottery) Results Are In!"
        content.body = "Winning numbers: \(numbers.map { String($0) }.joined(separator: " - ")) | \(special)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "result_\(lottery)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 管理通知

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    // MARK: - 徽章管理

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    func setBadge(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
}

// MARK: - App Delegate Extension for Push
extension NotificationManager {
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")
        // TODO: 发送到服务器
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        // 处理远程推送
        print("Received remote notification: \(userInfo)")
    }
}
