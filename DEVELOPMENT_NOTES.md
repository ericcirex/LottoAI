# LottoAI 开发笔记

> 最后更新: 2026-02-02

---

## 项目状态概览

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| 基础 UI | ✅ 完成 | SwiftUI, iOS 16+ |
| API 后端 | ✅ 完成 | GitHub Pages 静态 JSON |
| GitHub Actions | ✅ 完成 | 每4小时自动更新数据 |
| Apple Sign-In | ✅ 完成 | 本地存储模式 |
| Firebase | ⏸️ 暂停 | 包链接问题，待修复 |
| 彩票扫描 | ✅ 完成 | Vision OCR |
| Widget | ✅ 完成 | iOS Widget Extension |

---

## Firebase 配置信息 (重要 - 后期恢复用)

### Firebase 项目信息
- **项目名称**: LottoAI
- **项目 ID**: `lottoai-48008`
- **控制台**: https://console.firebase.google.com/project/lottoai-48008

### iOS App 配置
- **Bundle ID**: `com.ericcirex.lottoai`
- **Google App ID**: `1:490484527413:ios:3457a5c914a6d4493f5c7c`
- **API Key**: `AIzaSyA9qCdzcUkeFAuwC7DsbsqBKP8ousVasf0`
- **GCM Sender ID**: `490484527413`
- **Storage Bucket**: `lottoai-48008.firebasestorage.app`

### GoogleService-Info.plist
文件位置: `LottoAI/Resources/GoogleService-Info.plist` (已添加)

### 需要启用的 Firebase 服务
1. **Authentication** - Apple Sign-In
   - 控制台: https://console.firebase.google.com/project/lottoai-48008/authentication/providers
   - 需要启用 Apple 提供商

2. **Firestore Database**
   - 用于存储用户数据、扫描记录、预测历史

---

## 恢复 Firebase 的步骤

### 1. 在 Xcode 中添加 Firebase SDK
```
File → Add Package Dependencies...
URL: https://github.com/firebase/firebase-ios-sdk
选择产品:
  ✅ FirebaseAuth
  ✅ FirebaseCore
  ✅ FirebaseFirestore
```

### 2. 取消注释代码

**LottoAIApp.swift** (第7-8行):
```swift
// 取消注释:
import FirebaseCore
import FirebaseAuth

// 取消注释 (第45行):
FirebaseApp.configure()
```

**AuthenticationManager.swift** (第6-7行):
```swift
// 取消注释:
import FirebaseAuth
import FirebaseFirestore
```

**FirestoreService.swift** (第2-3行):
```swift
// 取消注释:
import FirebaseFirestore
import FirebaseAuth
```

### 3. 恢复 Firebase 功能代码
需要恢复的文件和功能:
- `AuthenticationManager.swift` - Firebase Auth 登录逻辑
- `FirestoreService.swift` - Firestore 数据库操作

### 4. 在 Firebase Console 启用 Apple Sign-In
1. 打开 https://console.firebase.google.com/project/lottoai-48008/authentication/providers
2. 点击 "Apple"
3. 启用
4. 保存

---

## GitHub 部署信息

### 仓库
- **URL**: https://github.com/ericcirex/LottoAI
- **可见性**: Public

### GitHub Pages (API 后端)
- **基础 URL**: https://ericcirex.github.io/LottoAI
- **数据更新**: 每4小时自动 (GitHub Actions)

### API 端点
| 端点 | 描述 |
|------|------|
| `/manifest.json` | API 清单 |
| `/powerball/latest_results.json` | Powerball 最新开奖 |
| `/powerball/ai_predictions.json` | Powerball AI 预测 |
| `/powerball/hot_cold_numbers.json` | Powerball 冷热号 |
| `/megamillions/latest_results.json` | Mega Millions 最新开奖 |
| `/megamillions/ai_predictions.json` | Mega Millions AI 预测 |
| `/megamillions/hot_cold_numbers.json` | Mega Millions 冷热号 |
| `/daily_quotes.json` | 每日金句 |

### GitHub Actions 工作流
- **文件**: `.github/workflows/update-lottery-data.yml`
- **触发**:
  - 定时: 每4小时 (`0 */4 * * *`)
  - 手动: workflow_dispatch
  - Push: main 分支 backend 目录变更

---

## 当前问题记录

### Firebase SDK 链接问题 (2026-02-02)
**问题描述**:
- 通过 SPM 添加 Firebase SDK 后，Xcode 无法找到模块
- 错误: `Unable to find module dependency: 'FirebaseAuth'`

**尝试过的解决方案**:
1. ❌ File → Packages → Reset Package Caches
2. ❌ File → Packages → Resolve Package Versions
3. ❌ 清理 DerivedData
4. ❌ 手动编辑 project.pbxproj 添加依赖

**临时解决方案**:
- 禁用 Firebase，使用 UserDefaults 本地存储
- 用户认证使用纯 Apple Sign-In (本地模式)

**后续行动**:
- [ ] 尝试在全新 Xcode 项目中添加 Firebase
- [ ] 检查 Xcode 版本兼容性
- [ ] 考虑使用 CocoaPods 替代 SPM

---

## 文件结构

```
LottoAI/
├── LottoAI/
│   ├── App/
│   │   ├── LottoAIApp.swift       # 主入口 (Firebase 初始化已注释)
│   │   ├── ContentView.swift
│   │   └── SplashView.swift
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── AppUser.swift
│   │   │   ├── DrawResult.swift
│   │   │   ├── LotteryType.swift
│   │   │   ├── Prediction.swift
│   │   │   └── Quote.swift
│   │   ├── Services/
│   │   │   ├── APIService.swift        # GitHub Pages API
│   │   │   ├── AuthenticationManager.swift  # Apple Sign-In (本地模式)
│   │   │   └── FirestoreService.swift  # 本地存储 (Firebase 已禁用)
│   │   └── Utilities/
│   ├── Features/
│   │   ├── Auth/
│   │   ├── Home/
│   │   ├── Prediction/
│   │   ├── History/
│   │   ├── Scanner/
│   │   ├── Profile/
│   │   └── Paywall/
│   ├── DesignSystem/
│   └── Resources/
│       ├── Assets.xcassets
│       ├── GoogleService-Info.plist  # Firebase 配置文件
│       ├── Info.plist
│       └── LottoAI.entitlements
├── LottoAIWidget/
├── backend/
│   ├── lottery_service.py    # 数据抓取脚本
│   └── public/               # 生成的 JSON 文件
└── .github/
    └── workflows/
        └── update-lottery-data.yml
```

---

## 联系与资源

- **GitHub 仓库**: https://github.com/ericcirex/LottoAI
- **Firebase Console**: https://console.firebase.google.com/project/lottoai-48008
- **API 文档**: https://ericcirex.github.io/LottoAI/manifest.json

---

## 更新日志

### 2026-02-02 (下午更新)
- ✅ 添加奖金爬虫功能 (JackpotScraper)
- ✅ 新增 `/jackpot.json` API 端点
- ✅ 从官方 API 获取当前奖金金额
- ✅ 添加 lottery.net 作为备用数据源
- ✅ 数据验证完成 - 号码与官方一致

### 2026-02-02
- ✅ 创建 Firebase 项目 (lottoai-48008)
- ✅ 添加 iOS App 到 Firebase
- ✅ 下载并添加 GoogleService-Info.plist
- ⏸️ Firebase SDK 链接失败，暂时禁用
- ✅ 改用本地存储模式
- ✅ GitHub Actions + Pages 部署成功
- ✅ API 数据自动更新配置完成
