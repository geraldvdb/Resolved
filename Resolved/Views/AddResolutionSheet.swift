//
//  AddResolutionSheet.swift
//  Resolved
//
//  Multi-step sheet for creating a new resolution with optional rewards.
//  Step 1: Enter resolution details (name, description, target count)
//  Step 2: Configure optional rewards at various milestones
//

import SwiftUI
import SwiftData

/// Sheet view for creating a new resolution
struct AddResolutionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Step tracking
    @State private var currentStep = 0
    
    // Resolution fields
    @State private var name = ""
    @State private var descriptionText = ""
    @State private var targetCount = 100
    
    // Rewards
    @State private var rewards: [TempReward] = []
    @State private var showingAddReward = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, description, count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        resolutionDetailsStep.tag(0)
                        rewardsStep.tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                    
                    // Navigation buttons
                    navigationButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle(currentStep == 0 ? "New Resolution" : "Set Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbarBackground(AppColors.background(colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showingAddReward) {
                AddRewardSheet(rewards: $rewards, targetCount: targetCount)
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 12) {
            ForEach(0..<2, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? AppColors.accent : AppColors.secondaryText(colorScheme).opacity(0.3))
                    .frame(width: step == currentStep ? 12 : 8, height: step == currentStep ? 12 : 8)
                    .animation(.spring(response: 0.3), value: currentStep)
                
                if step < 1 {
                    Rectangle()
                        .fill(step < currentStep ? AppColors.accent : AppColors.secondaryText(colorScheme).opacity(0.3))
                        .frame(width: 40, height: 2)
                }
            }
        }
    }
    
    // MARK: - Step 1: Resolution Details
    
    private var resolutionDetailsStep: some View {
        ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Resolution Name")
                                .font(.custom("Avenir Next", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.secondaryText(colorScheme))
                            
                            TextField("", text: $name, prompt: Text("e.g. Go to the Gym").foregroundColor(AppColors.secondaryText(colorScheme).opacity(0.6)))
                                .font(.custom("Avenir Next", size: 18))
                                .foregroundColor(AppColors.primaryText(colorScheme))
                                .padding()
                                .background(AppColors.inputBackground(colorScheme))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.accent.opacity(focusedField == .name ? 1 : 0), lineWidth: 2)
                                )
                                .focused($focusedField, equals: .name)
                            .submitLabel(.done)
                            .onSubmit { focusedField = nil }
                            .id("nameField")
                        }
                        
                        // Description field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (optional)")
                                .font(.custom("Avenir Next", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.secondaryText(colorScheme))
                            
                        TextField("", text: $descriptionText, prompt: Text("Add any details about this resolution").foregroundColor(AppColors.secondaryText(colorScheme).opacity(0.6)))
                                .font(.custom("Avenir Next", size: 16))
                                .foregroundColor(AppColors.primaryText(colorScheme))
                                .padding()
                                .background(AppColors.inputBackground(colorScheme))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.accent.opacity(focusedField == .description ? 1 : 0), lineWidth: 2)
                                )
                                .focused($focusedField, equals: .description)
                            .submitLabel(.done)
                            .onSubmit { focusedField = nil }
                            .id("descriptionField")
                        }
                        
                        // Target count
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Count")
                                .font(.custom("Avenir Next", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.secondaryText(colorScheme))
                            
                            HStack {
                                Button(action: { if targetCount > 1 { targetCount -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(AppColors.accent)
                                }
                                
                                TextField("", value: $targetCount, format: .number)
                                    .font(.custom("Avenir Next", size: 32))
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.primaryText(colorScheme))
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .frame(width: 100)
                                    .focused($focusedField, equals: .count)
                                
                                Button(action: { targetCount += 1 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(AppColors.accent)
                                }
                            }
                            .padding()
                            .background(AppColors.inputBackground(colorScheme))
                            .cornerRadius(12)
                        .id("countField")
                    }
                    
                    // Extra padding for keyboard
                    Spacer()
                        .frame(height: 200)
                }
                .padding(24)
            }
            .onChange(of: focusedField) { _, field in
                if let field = field {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            switch field {
                            case .name:
                                proxy.scrollTo("nameField", anchor: UnitPoint(x: 0.5, y: 0.7))
                            case .description:
                                proxy.scrollTo("descriptionField", anchor: UnitPoint(x: 0.5, y: 0.7))
                            case .count:
                                proxy.scrollTo("countField", anchor: UnitPoint(x: 0.5, y: 0.7))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Rewards
    
    private var rewardsStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.gold(colorScheme), AppColors.goldLight(colorScheme)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Motivate yourself with rewards!")
                        .font(.custom("Avenir Next", size: 16))
                        .foregroundColor(AppColors.secondaryText(colorScheme))
                }
                .padding(.bottom, 8)
                
                // Rewards list
                VStack(spacing: 12) {
                    ForEach(rewards) { reward in
                        RewardRow(reward: reward) {
                            rewards.removeAll { $0.id == reward.id }
                        }
                    }
                    
                    // Add reward button
                    Button(action: { showingAddReward = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Reward")
                        }
                        .font(.custom("Avenir Next", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.success(colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.inputBackground(colorScheme))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.success(colorScheme).opacity(AppColors.borderOpacity(colorScheme)), lineWidth: 1)
                        )
                    }
                }
                
                // Skip hint
                if rewards.isEmpty {
                    Text("You can skip this step and add rewards later")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundColor(AppColors.secondaryText(colorScheme).opacity(0.6))
                        .padding(.top, 8)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button(action: { currentStep -= 1 }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.custom("Avenir Next", size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryText(colorScheme))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppColors.inputBackground(colorScheme))
                    .cornerRadius(16)
                }
            }
            
            Button(action: handleNextAction) {
                HStack {
                    Text(currentStep == 1 ? "Create Resolution" : "Next")
                    Image(systemName: currentStep == 1 ? "checkmark.circle.fill" : "chevron.right")
                }
                .font(.custom("Avenir Next", size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                .frame(height: 54)
                                .background(
                                    LinearGradient(
                        colors: (currentStep == 0 && name.isEmpty) ? [.gray, .gray] : [AppColors.accent, AppColors.accentLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                .shadow(color: (currentStep == 0 && name.isEmpty) ? .clear : AppColors.accent.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .disabled(currentStep == 0 && name.isEmpty)
        }
    }
    
    // MARK: - Actions
    
    private func handleNextAction() {
        if currentStep == 0 {
            currentStep = 1
        } else {
            saveResolution()
        }
    }
    
    private func saveResolution() {
        let resolution = Resolution(
            name: name,
            descriptionText: descriptionText,
            targetCount: max(1, targetCount)
        )
        modelContext.insert(resolution)
        
        // Add rewards
        for tempReward in rewards {
            let reward = Reward(
                descriptionText: tempReward.descriptionText,
                triggerType: tempReward.triggerType,
                triggerValue: tempReward.triggerValue
            )
            resolution.addReward(reward)
            modelContext.insert(reward)
        }
        
        dismiss()
    }
}

// MARK: - Temporary Reward Model (for UI before saving)

struct TempReward: Identifiable {
    let id = UUID()
    var descriptionText: String
    var triggerType: String
    var triggerValue: Int
    
    var displayName: String {
        switch triggerType {
        case "segment":
            return "Every \(triggerValue)"
        case "milestone":
            return "At #\(triggerValue)"
        case "completion":
            return "Full Completion"
        default:
            return triggerType
        }
    }
    
    var icon: String {
        switch triggerType {
        case "segment":
            return "repeat.circle.fill"
        case "milestone":
            return "flag.fill"
        case "completion":
            return "trophy.fill"
        default:
            return "gift.fill"
        }
    }
}

// MARK: - Reward Row

struct RewardRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let reward: TempReward
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: reward.icon)
                .foregroundColor(AppColors.gold(colorScheme))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.descriptionText)
                    .font(.custom("Avenir Next", size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryText(colorScheme))
                Text(reward.displayName)
                    .font(.custom("Avenir Next", size: 12))
                    .foregroundColor(AppColors.secondaryText(colorScheme))
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.secondaryText(colorScheme))
            }
        }
        .padding()
        .background(AppColors.inputBackground(colorScheme))
        .cornerRadius(12)
    }
}

// MARK: - Add Reward Sheet

struct AddRewardSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var rewards: [TempReward]
    let targetCount: Int
    
    @State private var description = ""
    @State private var triggerType = 0 // 0: segment, 1: milestone, 2: completion
    @State private var segmentValue = 10
    @State private var milestoneValue = 25
    
    @FocusState private var isDescriptionFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Description input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reward Description")
                                .font(.custom("Avenir Next", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.secondaryText(colorScheme))
                            
                            TextField("", text: $description, prompt: Text("e.g., Treat yourself to coffee!").foregroundColor(AppColors.secondaryText(colorScheme).opacity(0.6)))
                                .font(.custom("Avenir Next", size: 16))
                                .foregroundColor(AppColors.primaryText(colorScheme))
                                .padding()
                                .background(AppColors.inputBackground(colorScheme))
                                .cornerRadius(12)
                                .focused($isDescriptionFocused)
                                .submitLabel(.done)
                                .onSubmit { isDescriptionFocused = false }
                        }
                        
                        // Trigger type picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When to Unlock")
                                .font(.custom("Avenir Next", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.secondaryText(colorScheme))
                            
                            Picker("Trigger Type", selection: $triggerType) {
                                Text("Every N").tag(0)
                                Text("At #").tag(1)
                                Text("Completion").tag(2)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Value input based on type
                        if triggerType == 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Every how many?")
                                    .font(.custom("Avenir Next", size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.secondaryText(colorScheme))
                                
                                HStack(spacing: 12) {
                                    ForEach([5, 10, 20, 25], id: \.self) { value in
                                        Button(action: { segmentValue = value }) {
                                            Text("\(value)")
                                                .font(.custom("Avenir Next", size: 16))
                                                .fontWeight(.bold)
                                                .foregroundColor(segmentValue == value ? .white : AppColors.secondaryText(colorScheme))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(segmentValue == value ? AppColors.accent : AppColors.inputBackground(colorScheme))
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                        } else if triggerType == 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("At which number?")
                                    .font(.custom("Avenir Next", size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.secondaryText(colorScheme))
                                
                                HStack {
                                    Slider(value: Binding(
                                        get: { Double(milestoneValue) },
                                        set: { milestoneValue = Int($0) }
                                    ), in: 1...Double(max(targetCount, 2)), step: 1)
                                    .tint(AppColors.accent)
                                    
                                    Text("#\(milestoneValue)")
                                        .font(.custom("Avenir Next", size: 18))
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.gold(colorScheme))
                                        .frame(width: 60)
                                }
                                .padding()
                                .background(AppColors.inputBackground(colorScheme))
                                .cornerRadius(12)
                            }
                        } else {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(AppColors.gold(colorScheme))
                                Text("Unlocks when all \(targetCount) are completed!")
                                    .font(.custom("Avenir Next", size: 14))
                                    .foregroundColor(AppColors.secondaryText(colorScheme))
                            }
                            .padding()
                            .background(AppColors.inputBackground(colorScheme))
                            .cornerRadius(12)
                        }
                        
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Add Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbarBackground(AppColors.background(colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.secondaryText(colorScheme))
                    }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addReward() }
                    .foregroundColor(AppColors.accent)
                        .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private func addReward() {
        let type: String
        let value: Int
        
        switch triggerType {
        case 0:
            type = "segment"
            value = segmentValue
        case 1:
            type = "milestone"
            value = milestoneValue
        default:
            type = "completion"
            value = 0
        }
        
        let reward = TempReward(
            descriptionText: description,
            triggerType: type,
            triggerValue: value
        )
        rewards.append(reward)
        dismiss()
    }
}

#Preview {
    AddResolutionSheet()
        .modelContainer(for: [Resolution.self, LogEntry.self, Reward.self], inMemory: true)
}
