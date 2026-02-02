import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case predict = "Predict"
        case history = "History"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .predict: return "brain.head.profile"
            case .history: return "clock.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            // 背景
            AppColors.backgroundGradient
                .ignoresSafeArea()

            // TabView
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                    }
                    .tag(Tab.home)

                PredictionView()
                    .tabItem {
                        Label(Tab.predict.rawValue, systemImage: Tab.predict.icon)
                    }
                    .tag(Tab.predict)

                HistoryView()
                    .tabItem {
                        Label(Tab.history.rawValue, systemImage: Tab.history.icon)
                    }
                    .tag(Tab.history)

                ProfileView()
                    .tabItem {
                        Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                    }
                    .tag(Tab.profile)
            }
            .tint(AppColors.gold)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionManager.shared)
}
