import SwiftUI

/// 扫描历史视图
struct ScannedTicketsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var tickets: [ScannedTicket] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.gold))
            } else if tickets.isEmpty {
                EmptyTicketsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tickets) { ticket in
                            ScannedTicketCard(ticket: ticket)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Scanned Tickets")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadTickets()
        }
    }

    private func loadTickets() async {
        guard let userId = authManager.currentUser?.id else {
            isLoading = false
            return
        }

        tickets = await FirestoreService.shared.getScannedTickets(userId: userId)
        isLoading = false
    }
}

// MARK: - Empty View
struct EmptyTicketsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "ticket")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)

            Text("No Scanned Tickets")
                .font(.headline)
                .foregroundColor(.white)

            Text("Scan your lottery tickets to check for wins and track your history")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Scanned Ticket Card
struct ScannedTicketCard: View {
    let ticket: ScannedTicket

    private var lotteryType: LotteryType {
        LotteryType(rawValue: ticket.lotteryType) ?? .powerball
    }

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: lotteryType.iconName)
                            .foregroundColor(lotteryType.themeColor)
                        Text(lotteryType.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Win/Loss indicator
                    if ticket.isWinner {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                            Text("Winner!")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.gold.opacity(0.2))
                        .cornerRadius(8)
                    }
                }

                // Numbers
                LottoBallRow(
                    mainNumbers: ticket.numbers,
                    specialNumber: ticket.specialBall,
                    lotteryType: lotteryType,
                    ballSize: 36
                )

                // Details
                HStack {
                    // Scan date
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scanned")
                            .font(.caption2)
                            .foregroundColor(AppColors.textTertiary)
                        Text(formatDate(ticket.scannedAt))
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    // Prize info
                    if ticket.isWinner, let tier = ticket.prizeTier {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(tier)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.gold)

                            if let amount = ticket.prizeAmount, amount > 0 {
                                Text(formatCurrency(amount))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.techCyan)
                            }
                        }
                    } else if let drawDate = ticket.drawDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Draw Date")
                                .font(.caption2)
                                .foregroundColor(AppColors.textTertiary)
                            Text(drawDate)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}

#Preview {
    NavigationStack {
        ScannedTicketsView()
    }
    .preferredColorScheme(.dark)
}
