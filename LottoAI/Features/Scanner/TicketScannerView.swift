import SwiftUI
import AVFoundation
import Vision

struct TicketScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TicketScannerViewModel()
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // 说明
                    if viewModel.scanState == .idle {
                        InstructionCard()
                    }

                    // 扫描区域/结果
                    switch viewModel.scanState {
                    case .idle:
                        ScanOptionsView(
                            onCamera: { showCamera = true },
                            onGallery: { showImagePicker = true }
                        )

                    case .scanning:
                        ScanningView()

                    case .confirming(let numbers, let specialBall):
                        ConfirmNumbersView(
                            numbers: numbers,
                            specialBall: specialBall,
                            lotteryType: viewModel.selectedLottery,
                            onConfirm: { confirmedNumbers, confirmedSpecial in
                                viewModel.confirmNumbers(confirmedNumbers, special: confirmedSpecial)
                            },
                            onRescan: {
                                viewModel.reset()
                            }
                        )

                    case .checking:
                        CheckingResultView()

                    case .result(let ticket):
                        TicketResultView(
                            ticket: ticket,
                            onScanAnother: {
                                viewModel.reset()
                            },
                            onDone: {
                                dismiss()
                            }
                        )

                    case .error(let message):
                        ErrorView(
                            message: message,
                            onRetry: { viewModel.reset() }
                        )
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Scan Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    // 彩票类型选择
                    Menu {
                        ForEach(LotteryType.allCases) { lottery in
                            Button {
                                viewModel.selectedLottery = lottery
                            } label: {
                                HStack {
                                    Text(lottery.displayName)
                                    if viewModel.selectedLottery == lottery {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedLottery.shortName)
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(viewModel.selectedLottery.themeColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedLottery.themeColor.opacity(0.2))
                        )
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    viewModel.scanImage(image)
                }
            }
        }
    }
}

// MARK: - Instruction Card
struct InstructionCard: View {
    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.techCyan)

                    Text("How to Scan")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    InstructionRow(number: "1", text: "Take a clear photo of your lottery ticket")
                    InstructionRow(number: "2", text: "Make sure all numbers are visible")
                    InstructionRow(number: "3", text: "Confirm the recognized numbers")
                    InstructionRow(number: "4", text: "We'll check against the latest draw!")
                }
            }
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppColors.deepBlack)
                .frame(width: 20, height: 20)
                .background(Circle().fill(AppColors.gold))

            Text(text)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)

            Spacer()
        }
    }
}

// MARK: - Scan Options
struct ScanOptionsView: View {
    let onCamera: () -> Void
    let onGallery: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // 相机按钮
            Button(action: onCamera) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppColors.gold.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.gold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Take Photo")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Use camera to scan ticket")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.spaceBlue.opacity(0.8))
                )
            }

            // 相册按钮
            Button(action: onGallery) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppColors.techCyan.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: "photo.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.techCyan)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose from Gallery")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Select existing photo")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.spaceBlue.opacity(0.8))
                )
            }
        }
    }
}

// MARK: - Scanning View
struct ScanningView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(AppColors.gold.opacity(0.3), lineWidth: 4)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(AppColors.gold, lineWidth: 4)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(rotation))

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.gold)
            }
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }

            Text("Scanning ticket...")
                .font(.headline)
                .foregroundColor(.white)

            Text("Looking for numbers")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(40)
    }
}

// MARK: - Confirm Numbers View
struct ConfirmNumbersView: View {
    let numbers: [Int]
    let specialBall: Int
    let lotteryType: LotteryType
    let onConfirm: ([Int], Int) -> Void
    let onRescan: () -> Void

    @State private var editableNumbers: [Int]
    @State private var editableSpecial: Int
    @State private var editingIndex: Int?

    init(numbers: [Int], specialBall: Int, lotteryType: LotteryType, onConfirm: @escaping ([Int], Int) -> Void, onRescan: @escaping () -> Void) {
        self.numbers = numbers
        self.specialBall = specialBall
        self.lotteryType = lotteryType
        self.onConfirm = onConfirm
        self.onRescan = onRescan
        self._editableNumbers = State(initialValue: numbers)
        self._editableSpecial = State(initialValue: specialBall)
    }

    var body: some View {
        VStack(spacing: 24) {
            // 标题
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.techCyan)

                Text("Numbers Detected!")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Tap any number to edit if needed")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            // 号码球
            HStack(spacing: 8) {
                ForEach(Array(editableNumbers.enumerated()), id: \.offset) { index, number in
                    EditableBall(
                        number: number,
                        type: .white,
                        isEditing: editingIndex == index,
                        maxValue: lotteryType.mainNumberRange.upperBound
                    ) { newValue in
                        editableNumbers[index] = newValue
                    }
                }

                Rectangle()
                    .fill(AppColors.textTertiary)
                    .frame(width: 1, height: 30)
                    .padding(.horizontal, 4)

                EditableBall(
                    number: editableSpecial,
                    type: lotteryType == .powerball ? .powerball : .megaball,
                    isEditing: editingIndex == 99,
                    maxValue: lotteryType.specialNumberRange.upperBound
                ) { newValue in
                    editableSpecial = newValue
                }
            }

            // 按钮
            HStack(spacing: 16) {
                Button(action: onRescan) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Rescan")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.spaceBlue)
                    )
                }

                Button {
                    onConfirm(editableNumbers, editableSpecial)
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Confirm & Check")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.gold, Color(hex: "FFA500")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
            }
        }
        .padding()
    }
}

// MARK: - Editable Ball
struct EditableBall: View {
    let number: Int
    let type: BallType
    let isEditing: Bool
    let maxValue: Int
    let onChange: (Int) -> Void

    @State private var textValue: String = ""

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: type.gradientColors,
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 25
                    )
                )
                .frame(width: 48, height: 48)
                .shadow(color: type.shadowColor, radius: 4, y: 2)

            if isEditing {
                TextField("", text: $textValue)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(type.textColor)
                    .frame(width: 40)
                    .onSubmit {
                        if let value = Int(textValue), value >= 1, value <= maxValue {
                            onChange(value)
                        }
                    }
            } else {
                Text("\(number)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(type.textColor)
            }
        }
        .onAppear {
            textValue = "\(number)"
        }
    }
}

// MARK: - Checking Result View
struct CheckingResultView: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(AppColors.spaceBlue, lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.gold, AppColors.techCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.gold)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2)) {
                    progress = 1
                }
            }

            Text("Checking Results...")
                .font(.headline)
                .foregroundColor(.white)

            Text("Comparing with latest draw")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(40)
    }
}

// MARK: - Ticket Result View
struct TicketResultView: View {
    let ticket: ScannedTicket
    let onScanAnother: () -> Void
    let onDone: () -> Void

    @State private var showCelebration = false

    var prizeTier: PrizeTier {
        PrizeTier(rawValue: ticket.prizeTier ?? "No Prize") ?? .none
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 结果图标
                ZStack {
                    if ticket.isWinner {
                        // 中奖动画
                        ForEach(0..<12) { i in
                            Circle()
                                .fill(AppColors.gold)
                                .frame(width: 8, height: 8)
                                .offset(y: showCelebration ? -80 : 0)
                                .rotationEffect(.degrees(Double(i) * 30))
                                .opacity(showCelebration ? 0 : 1)
                        }
                    }

                    Circle()
                        .fill(
                            ticket.isWinner
                                ? LinearGradient(colors: [AppColors.gold, Color(hex: "FFA500")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [AppColors.spaceBlue, AppColors.starBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: ticket.isWinner ? "star.fill" : "xmark")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .onAppear {
                    if ticket.isWinner {
                        withAnimation(.easeOut(duration: 1).delay(0.3)) {
                            showCelebration = true
                        }
                        HapticManager.success()
                    }
                }

                // 结果文字
                VStack(spacing: 12) {
                    Text(ticket.isWinner ? "You Won!" : "Not This Time")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(ticket.isWinner ? AppColors.gold : .white)

                    Text(prizeTier.celebrationMessage)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if let amount = ticket.prizeAmount, amount > 0 {
                        Text("$\(Int(amount))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.gold, Color(hex: "FFA500")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }

                // 你的号码
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Numbers")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)

                        HStack(spacing: 6) {
                            ForEach(ticket.numbers, id: \.self) { number in
                                Text("\(number)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(AppColors.spaceBlue))
                            }

                            Rectangle()
                                .fill(AppColors.textTertiary)
                                .frame(width: 1, height: 20)

                            Text("\(ticket.specialBall)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle().fill(
                                        ticket.lotteryType == "powerball"
                                            ? AppColors.luckyRed
                                            : AppColors.gold
                                    )
                                )
                        }
                    }
                }

                // 按钮
                VStack(spacing: 12) {
                    Button(action: onScanAnother) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Scan Another Ticket")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.gold, Color(hex: "FFA500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }

                    Button(action: onDone) {
                        Text("Done")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.luckyRed)

            Text("Scan Failed")
                .font(.headline)
                .foregroundColor(.white)

            Text(message)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.luckyRed)
                )
            }
        }
        .padding()
    }
}

#Preview {
    TicketScannerView()
        .preferredColorScheme(.dark)
}
