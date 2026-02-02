import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 彩票切换
                    LotteryPicker(selection: $appState.selectedLottery)
                        .padding(.horizontal)

                    // 冷热号图表
                    if let hotCold = viewModel.hotColdData {
                        HotColdChartCard(data: hotCold, lottery: appState.selectedLottery)
                            .padding(.horizontal)
                    }

                    // 历史记录标题
                    HStack {
                        Text("Draw History")
                            .font(.headline)
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(viewModel.results.count) results")
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.horizontal)

                    // 历史记录列表
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.results) { result in
                            HistoryResultRow(result: result, lottery: appState.selectedLottery)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .background(AppColors.backgroundGradient.ignoresSafeArea())
        }
        .task {
            await viewModel.loadData(for: appState.selectedLottery)
        }
        .onChange(of: appState.selectedLottery) { newValue in
            Task {
                await viewModel.loadData(for: newValue)
            }
        }
    }
}

// MARK: - 冷热号图表卡片
struct HotColdChartCard: View {
    let data: HotColdResponse
    let lottery: LotteryType

    @State private var showHot = true

    // 将数字数组和频率转换为图表数据
    private var chartData: [(number: Int, count: Int)] {
        let numbers = showHot ? data.hotNumbers.main : data.coldNumbers.main
        let frequency = data.frequency.main

        return numbers.prefix(10).map { num in
            let count = frequency[String(num)] ?? 0
            return (number: num, count: count)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // 主图表卡片
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题和切换
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: showHot ? "flame.fill" : "snowflake")
                                .foregroundColor(showHot ? lottery.themeColor : AppColors.techCyan)

                            Text(showHot ? "Hot Numbers" : "Cold Numbers")
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Hot/Cold 切换
                        HStack(spacing: 0) {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    showHot = true
                                }
                                HapticManager.selection()
                            } label: {
                                Image(systemName: "flame.fill")
                                    .font(.subheadline)
                                    .foregroundColor(showHot ? .white : AppColors.textTertiary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(showHot ? lottery.themeColor : Color.clear)
                                    )
                            }

                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    showHot = false
                                }
                                HapticManager.selection()
                            } label: {
                                Image(systemName: "snowflake")
                                    .font(.subheadline)
                                    .foregroundColor(!showHot ? .white : AppColors.textTertiary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(!showHot ? AppColors.techCyan : Color.clear)
                                    )
                            }
                        }
                        .background(
                            Capsule()
                                .fill(AppColors.deepBlack.opacity(0.5))
                        )
                    }

                    // 图表
                    if !chartData.isEmpty {
                        Chart(chartData, id: \.number) { item in
                            BarMark(
                                x: .value("Number", "\(item.number)"),
                                y: .value("Count", item.count)
                            )
                            .foregroundStyle(showHot ? lottery.themeColor : AppColors.techCyan)
                            .cornerRadius(4)
                        }
                        .frame(height: 160)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel()
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisGridLine()
                                    .foregroundStyle(AppColors.textTertiary.opacity(0.3))
                                AxisValueLabel()
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }

                    // 说明
                    HStack {
                        Text(showHot ? "Most frequent numbers" : "Least frequent - due for a hit?")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        Text(data.analysisPeriod)
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }

            // 号码球展示
            NumberBallsRow(
                numbers: showHot ? data.hotNumbers.main : data.coldNumbers.main,
                frequency: data.frequency.main,
                isHot: showHot,
                lottery: lottery
            )
        }
    }
}

// MARK: - 号码球行
struct NumberBallsRow: View {
    let numbers: [Int]
    let frequency: [String: Int]
    let isHot: Bool
    let lottery: LotteryType

    var body: some View {
        GlassCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Top \(min(5, numbers.count)) \(isHot ? "Hot" : "Cold") Numbers")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: 8) {
                    ForEach(Array(numbers.prefix(5)), id: \.self) { num in
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: isHot
                                                ? [lottery.themeColor, lottery.themeColor.opacity(0.7)]
                                                : [AppColors.techCyan, AppColors.techCyan.opacity(0.7)],
                                            center: .topLeading,
                                            startRadius: 0,
                                            endRadius: 20
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                    .shadow(color: (isHot ? lottery.themeColor : AppColors.techCyan).opacity(0.4), radius: 4, y: 2)

                                Text("\(num)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            let count = frequency[String(num)] ?? 0
                            Text("\(count)x")
                                .font(.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }

                    Spacer()
                }
            }
        }
    }
}

// MARK: - 历史记录行
struct HistoryResultRow: View {
    let result: DrawResult
    let lottery: LotteryType

    @State private var isExpanded = false

    var body: some View {
        GlassCard(padding: 12) {
            VStack(spacing: 12) {
                // 主要信息
                HStack {
                    Text(result.formattedDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    Spacer()

                    // 缩略号码
                    HStack(spacing: 4) {
                        ForEach(result.numbers, id: \.self) { num in
                            Text("\(num)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(AppColors.spaceBlue))
                        }

                        Text("\(result.specialBall)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(lottery.themeColor))
                    }
                }

                // 展开详情
                if isExpanded {
                    Divider()
                        .background(AppColors.textTertiary)

                    LottoBallRow(
                        mainNumbers: result.numbers,
                        specialNumber: result.specialBall,
                        lotteryType: lottery,
                        ballSize: 40
                    )

                    if let multiplier = result.multiplier {
                        HStack {
                            Text("Multiplier")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Text("\(multiplier)x")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.gold)
                        }
                    }
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
            HapticManager.selection()
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
