import SwiftUI

struct ProgressGrid: View {
    @Environment(\.colorScheme) private var colorScheme
    let totalBlocks: Int
    let filledBlocks: Int
    let logEntries: [LogEntry]
    
    // Layout constants
    private let columns = 10
    private let spacing: CGFloat = 3
    private let maxGridWidth: CGFloat = 600
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
    
    private var rows: Int {
        (totalBlocks + columns - 1) / columns
    }
    
    // Get sorted entries by date
    private var sortedEntries: [LogEntry] {
        logEntries.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(min(geometry.size.width, maxGridWidth), 1)
            let blockSize = max((availableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns), 1)
            
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(blockSize), spacing: spacing), count: columns),
                    spacing: spacing
                ) {
                    ForEach(0..<totalBlocks, id: \.self) { index in
                        GridBlock(
                            isFilled: index < filledBlocks,
                            entry: index < sortedEntries.count ? sortedEntries[index] : nil,
                            size: blockSize,
                            dateFormatter: dateFormatter,
                            colorScheme: colorScheme
                        )
                    }
                }
            }
        }
        .frame(height: calculateGridHeight())
    }
    
    private func calculateGridHeight() -> CGFloat {
        let blockSize: CGFloat = 35 // Approximate block size
        return CGFloat(rows) * (blockSize + spacing)
    }
}

struct GridBlock: View {
    let isFilled: Bool
    let entry: LogEntry?
    let size: CGFloat
    let dateFormatter: DateFormatter
    let colorScheme: ColorScheme
    
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    isFilled
                        ? AppColors.accentGradient
                        : LinearGradient(
                            colors: [AppColors.emptyBlock(colorScheme), AppColors.emptyBlock(colorScheme)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                )
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(AppColors.cardBackground(colorScheme), lineWidth: 1)
                )
                .shadow(color: isFilled ? AppColors.accent.opacity(0.3) : .clear, radius: 3, x: 0, y: 2)
            
            // Show date if filled
            if let entry = entry, size > 25 {
                Text(dateFormatter.string(from: entry.date))
                    .font(.system(size: max(size / 5, 8)))
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .minimumScaleFactor(0.5)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

#Preview {
    ZStack {
        AppColors.background(.dark).ignoresSafeArea()
        
        ProgressGrid(
            totalBlocks: 100,
            filledBlocks: 35,
            logEntries: []
        )
        .padding()
    }
}
