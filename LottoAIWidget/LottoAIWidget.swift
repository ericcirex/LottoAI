import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct LottoEntry: TimelineEntry {
    let date: Date
    let lottery: WidgetLotteryType
    let nextDrawDate: Date
    let jackpot: String
    let lastNumbers: [Int]
    let lastSpecial: Int
}

// MARK: - Widget Lottery Type
enum WidgetLotteryType: String {
    case powerball = "powerball"
    case megaMillions = "mega_millions"

    var displayName: String {
        switch self {
        case .powerball: return "Powerball"
        case .megaMillions: return "Mega Millions"
        }
    }

    var themeColor: Color {
        switch self {
        case .powerball: return Color(red: 0.9, green: 0.22, blue: 0.27)
        case .megaMillions: return Color(red: 1.0, green: 0.84, blue: 0)
        }
    }

    var iconName: String {
        switch self {
        case .powerball: return "circle.fill"
        case .megaMillions: return "star.circle.fill"
        }
    }
}

// MARK: - Timeline Provider
struct LottoTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> LottoEntry {
        LottoEntry(
            date: Date(),
            lottery: .powerball,
            nextDrawDate: Date().addingTimeInterval(86400),
            jackpot: "$500M",
            lastNumbers: [12, 24, 36, 48, 52],
            lastSpecial: 10
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LottoEntry) -> Void) {
        let entry = LottoEntry(
            date: Date(),
            lottery: .powerball,
            nextDrawDate: calculateNextDraw(for: .powerball),
            jackpot: "$550M",
            lastNumbers: [7, 14, 28, 35, 62],
            lastSpecial: 15
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LottoEntry>) -> Void) {
        let currentDate = Date()
        let lottery: WidgetLotteryType = .powerball

        let entry = LottoEntry(
            date: currentDate,
            lottery: lottery,
            nextDrawDate: calculateNextDraw(for: lottery),
            jackpot: "$550M",
            lastNumbers: [7, 14, 28, 35, 62],
            lastSpecial: 15
        )

        // 每小时更新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func calculateNextDraw(for lottery: WidgetLotteryType) -> Date {
        let calendar = Calendar.current
        let now = Date()

        // Powerball: Mon(2), Wed(4), Sat(7) at 22:59 ET
        // Mega Millions: Tue(3), Fri(6) at 23:00 ET
        let drawDays = lottery == .powerball ? [2, 4, 7] : [3, 6]
        let drawHour = lottery == .powerball ? 22 : 23
        let drawMinute = lottery == .powerball ? 59 : 0

        let etTimeZone = TimeZone(identifier: "America/New_York")!
        let components = calendar.dateComponents(in: etTimeZone, from: now)

        for dayOffset in 0...7 {
            var futureComponents = components
            futureComponents.day = (components.day ?? 1) + dayOffset
            futureComponents.hour = drawHour
            futureComponents.minute = drawMinute
            futureComponents.second = 0

            if let futureDate = calendar.date(from: futureComponents) {
                let weekday = calendar.component(.weekday, from: futureDate)
                if drawDays.contains(weekday) && futureDate > now {
                    return futureDate
                }
            }
        }

        return now.addingTimeInterval(86400 * 2)
    }
}

// MARK: - Widget Views

// Small Widget
struct SmallWidgetView: View {
    let entry: LottoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: entry.lottery.iconName)
                    .foregroundColor(entry.lottery.themeColor)
                Text(entry.lottery.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Spacer()

            // Countdown
            VStack(alignment: .leading, spacing: 2) {
                Text("Next Draw")
                    .font(.caption2)
                    .foregroundColor(.gray)

                Text(entry.nextDrawDate, style: .relative)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(entry.lottery.themeColor)
            }

            // Jackpot
            Text(entry.jackpot)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// Medium Widget
struct MediumWidgetView: View {
    let entry: LottoEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Countdown
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: entry.lottery.iconName)
                        .foregroundColor(entry.lottery.themeColor)
                    Text(entry.lottery.displayName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Draw")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(entry.nextDrawDate, style: .relative)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(entry.lottery.themeColor)
                }

                Text(entry.jackpot)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Divider()
                .background(Color.gray.opacity(0.3))

            // Right: Last Numbers
            VStack(alignment: .leading, spacing: 8) {
                Text("Last Draw")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 4) {
                    ForEach(entry.lastNumbers, id: \.self) { num in
                        Text("\(num)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color(red: 0.1, green: 0.1, blue: 0.18)))
                    }

                    Text("\(entry.lastSpecial)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(entry.lottery.themeColor))
                }

                Spacer()

                // CTA
                HStack {
                    Image(systemName: "sparkles")
                    Text("Get Numbers")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(entry.lottery.themeColor.opacity(0.8))
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Main Widget
struct LottoAIWidget: Widget {
    let kind: String = "LottoAIWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LottoTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                WidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Lotto AI")
        .description("See upcoming draws and jackpots at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LottoEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle
@main
struct LottoAIWidgetBundle: WidgetBundle {
    var body: some Widget {
        LottoAIWidget()
    }
}

// MARK: - Previews
struct LottoAIWidget_Previews: PreviewProvider {
    static var previews: some View {
        SmallWidgetView(entry: LottoEntry(
            date: Date(),
            lottery: .powerball,
            nextDrawDate: Date().addingTimeInterval(86400),
            jackpot: "$550M",
            lastNumbers: [7, 14, 28, 35, 62],
            lastSpecial: 15
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))

        MediumWidgetView(entry: LottoEntry(
            date: Date(),
            lottery: .megaMillions,
            nextDrawDate: Date().addingTimeInterval(172800),
            jackpot: "$380M",
            lastNumbers: [3, 17, 42, 55, 68],
            lastSpecial: 22
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
