import SwiftUI

struct ContentView: View {
    // We'll now  store dates instead of just boolean selection states
    // The dictionary will map block indices to their selection dates
    @State private var selectedDates: [Int: Date] = [:]
    
    // Layout constants
    private let columns = 10
    private let rows = 10
    private let spacing: CGFloat = 2
    private let maxGridSize: CGFloat = 600
    private let screenPadding: CGFloat = 20
    
    // Date formatter to show dates in a readable format
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd\nHH:mm"
        return formatter
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let availableWidth = min(geometry.size.width - (screenPadding * 2), maxGridSize)
                let availableHeight = min(geometry.size.height - (screenPadding * 2), maxGridSize)
                let gridSize = min(availableWidth, availableHeight)
                let blockSize = (gridSize - spacing * CGFloat(columns - 1)) / CGFloat(columns)
                
                VStack {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.fixed(blockSize), spacing: spacing), count: columns),
                        spacing: spacing
                    ) {
                        ForEach(0..<rows * columns, id: \.self) { index in
                            Block(
                                isSelected: selectedDates[index] != nil,
                                date: selectedDates[index],
                                size: blockSize,
                                dateFormatter: dateFormatter
                            )
                            .onTapGesture {
                                toggleBlock(index)
                            }
                        }
                    }
                    .frame(width: gridSize, height: gridSize)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
                .padding(screenPadding)
            }
            .background(Color.white)
        }
    }
    
    private func toggleBlock(_ index: Int) {
        // If the block is already selected, remove its date
        // Otherwise, set its date to the current time
        if selectedDates[index] != nil {
            selectedDates.removeValue(forKey: index)
        } else {
            selectedDates[index] = Date()
        }
    }
}

struct Block: View {
    let isSelected: Bool
    let date: Date?
    let size: CGFloat
    let dateFormatter: DateFormatter
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: size, height: size)
                .shadow(radius: isSelected ? 3 : 1)
            
            // Show the formatted date if the block is selected
            if let date = date {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: size / 6)) // Adjust font size based on block size
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
