# Firebase 配置指南

## 步骤 1: 创建 Firebase 项目

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 点击 "Add project" 创建新项目
3. 项目名称: `LottoAI` (或自定义名称)
4. 可以禁用 Google Analytics (可选)

## 步骤 2: 添加 iOS App

1. 在 Firebase 控制台点击 iOS 图标添加应用
2. iOS Bundle ID: `com.ericcirex.lottoai` (与 Xcode 中一致)
3. App nickname: `LottoAI`
4. 点击 "Register app"

## 步骤 3: 下载配置文件

1. 下载 `GoogleService-Info.plist`
2. 将文件拖入 Xcode 项目的 `LottoAI/Resources/` 文件夹
3. 确保勾选 "Copy items if needed" 和 "LottoAI" target

## 步骤 4: 添加 Firebase SDK

在 Xcode 中:
1. File → Add Package Dependencies
2. 输入: `https://github.com/firebase/firebase-ios-sdk`
3. 点击 "Add Package"
4. 选择以下库:
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
5. 点击 "Add Package"

## 步骤 5: 启用 Apple Sign-In

### 在 Firebase Console:
1. Authentication → Sign-in method
2. 点击 "Apple" → 启用
3. 保存

### 在 Apple Developer Console:
1. 前往 [Apple Developer](https://developer.apple.com/)
2. Certificates, IDs & Profiles → Identifiers
3. 找到你的 App ID → 编辑
4. 启用 "Sign in with Apple"
5. Configure → 添加 Domain 和 Return URL (Firebase 会提供)

## 步骤 6: 取消代码注释

在 `LottoAIApp.swift` 中取消注释:
```swift
import FirebaseCore
import FirebaseAuth

// 在 didFinishLaunchingWithOptions 中:
FirebaseApp.configure()
```

在 `AuthenticationManager.swift` 中取消注释 Firebase 相关代码。

## 步骤 7: 配置 Firestore 规则

在 Firebase Console → Firestore Database → Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能读写自己的数据
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // 扫描记录只能被创建者访问
    match /scanned_tickets/{ticketId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.user_id;
      allow create: if request.auth != null;
    }
  }
}
```

## 验证配置

1. 运行 App
2. 点击 "Sign in with Apple"
3. 登录成功后应该看到用户信息
4. 在 Firebase Console → Authentication → Users 应该能看到新用户

## 步骤 8: 取消代码注释 (添加 SDK 后)

### LottoAIApp.swift
```swift
import FirebaseCore
import FirebaseAuth

// 在 didFinishLaunchingWithOptions 中:
FirebaseApp.configure()
```

### AuthenticationManager.swift
取消注释以下内容:
- `import FirebaseAuth`
- `import FirebaseFirestore`
- Firebase credential 验证代码
- Firestore 保存用户代码

### FirestoreService.swift
取消注释以下内容:
- `import FirebaseFirestore`
- `import FirebaseAuth`
- `private let db = Firestore.firestore()`
- 所有 Firestore 操作代码

## 功能清单

已实现的功能:

| 功能 | 状态 | 说明 |
|------|------|------|
| Apple Sign-In | ✅ | 完整的登录流程 |
| 用户资料管理 | ✅ | AppUser 模型 |
| 扫描历史 | ✅ | ScannedTicketsView |
| 预测统计 | ✅ | 自动追踪生成次数 |
| 数据同步 | ⏳ | 需添加 Firebase SDK |

## 数据结构

### users/{userId}
```json
{
  "id": "apple_user_id",
  "email": "user@example.com",
  "display_name": "User Name",
  "created_at": "2026-02-02T00:00:00Z",
  "is_premium": false,
  "stats": {
    "total_predictions": 10,
    "tickets_scanned": 5,
    "total_winnings": 100.0
  }
}
```

### scanned_tickets/{ticketId}
```json
{
  "user_id": "apple_user_id",
  "lottery_type": "powerball",
  "numbers": [7, 14, 21, 35, 62],
  "special_ball": 19,
  "scanned_at": "2026-02-02T00:00:00Z",
  "is_winner": true,
  "prize_tier": "Match 3"
}
```
