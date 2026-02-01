import SwiftUI
import SwiftData

struct EditResolutionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @Bindable var resolution: Resolution
    
    @State private var selectedTab = 0
    @State private var showingAddReward = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, description
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab picker
                    Picker("Section", selection: $selectedTab) {
                        Text("Details").tag(0)
                        Text("Rewards").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        detailsSection.tag(0)
                        rewardsSection.tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                }
            }
            .navigationTitle("Edit Resolution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbarBackground(AppColors.background(colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showingAddReward) {
                AddRewardToResolutionSheet(resolution: resolution)
            }
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Resolution Name")
                            .font(.custom("Avenir Next", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.secondaryText(colorScheme))
                        
                        TextField("", text: $resolution.name, prompt: Text("e.g., Go to the gym").foregroundColor(AppColors.secondaryText(colorScheme).opacity(0.6)))
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
                            .id("editNameField")
                    }
                    
                    // Description field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.custom("Avenir Next", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.secondaryText(colorScheme))
                        
                        TextField("", text: $resolution.descriptionText, prompt: Text("What's this resolution about?").foregroundColor(AppColors.secondaryText(colorScheme).opacity(0.6)))
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
                            .id("editDescriptionField")
                    }
                    
                    // Target count
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Count")
                            .font(.custom("Avenir Next", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.secondaryText(colorScheme))
                        
                        HStack {
                            Button(action: { if resolution.targetCount > 1 { resolution.targetCount -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppColors.accent)
                            }
                            
                            Text("\(resolution.targetCount)")
                                .font(.custom("Avenir Next", size: 32))
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.primaryText(colorScheme))
                                .frame(width: 100)
                            
                            Button(action: { resolution.targetCount += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        .padding()
                        .background(AppColors.inputBackground(colorScheme))
                        .cornerRadius(12)
                    }
                    
                    // Warning if target is less than current progress
                    if resolution.targetCount < (resolution.logEntries ?? []).count {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Target is less than current progress (\((resolution.logEntries ?? []).count))")
                                .font(.custom("Avenir Next", size: 14))
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(12)
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
                                proxy.scrollTo("editNameField", anchor: UnitPoint(x: 0.5, y: 0.7))
                            case .description:
                                proxy.scrollTo("editDescriptionField", anchor: UnitPoint(x: 0.5, y: 0.7))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Rewards Section
    
    private var rewardsSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Manage Rewards")
                            .font(.custom("Avenir Next", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primaryText(colorScheme))
                        
                        Text("\((resolution.rewards ?? []).count) reward\((resolution.rewards ?? []).count == 1 ? "" : "s")")
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundColor(AppColors.secondaryText(colorScheme))
                    }
                    
                    Spacer()
                }
                
                // Rewards list
                if (resolution.rewards ?? []).isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "gift")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.secondaryText(colorScheme).opacity(0.5))
                        
                        Text("No rewards yet")
                            .font(.custom("Avenir Next", size: 16))
                            .foregroundColor(AppColors.secondaryText(colorScheme))
                        
                        Text("Add rewards to motivate yourself!")
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundColor(AppColors.secondaryText(colorScheme).opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 12) {
                        ForEach(resolution.rewards ?? [], id: \.id) { reward in
                            EditableRewardRow(reward: reward) {
                                deleteReward(reward)
                            }
                        }
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
                    .foregroundColor(AppColors.success)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.inputBackground(colorScheme))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.success.opacity(0.5), lineWidth: 1)
                    )
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Actions
    
    private func deleteReward(_ reward: Reward) {
        resolution.rewards?.removeAll { $0.id == reward.id }
        modelContext.delete(reward)
    }
}

// MARK: - Editable Reward Row

struct EditableRewardRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let reward: Reward
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Status indicator
            ZStack {
                Circle()
                    .fill(reward.isUnlocked ? AppColors.gold.opacity(0.2) : AppColors.inputBackground(colorScheme))
                    .frame(width: 40, height: 40)
                
                Image(systemName: reward.isUnlocked ? "checkmark.circle.fill" : reward.triggerIcon)
                    .font(.system(size: 18))
                    .foregroundColor(reward.isUnlocked ? AppColors.gold : AppColors.secondaryText(colorScheme))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.descriptionText)
                    .font(.custom("Avenir Next", size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryText(colorScheme))
                
                HStack(spacing: 8) {
                    Text(reward.triggerDisplayName)
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundColor(AppColors.secondaryText(colorScheme))
                    
                    if reward.isUnlocked {
                        Text("• Unlocked")
                            .font(.custom("Avenir Next", size: 12))
                            .foregroundColor(AppColors.success)
                    }
                }
            }
            
            Spacer()
            
            // Delete button (only for non-unlocked rewards)
            if !reward.isUnlocked {
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding()
        .background(AppColors.inputBackground(colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(reward.isUnlocked ? AppColors.gold.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Add Reward to Resolution Sheet

struct AddRewardToResolutionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let resolution: Resolution
    
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
                                    ), in: 1...Double(max(resolution.targetCount, 2)), step: 1)
                                    .tint(AppColors.accent)
                                    
                                    Text("#\(milestoneValue)")
                                        .font(.custom("Avenir Next", size: 18))
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.gold)
                                        .frame(width: 60)
                                }
                                .padding()
                                .background(AppColors.inputBackground(colorScheme))
                                .cornerRadius(12)
                            }
                        } else {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(AppColors.gold)
                                Text("Unlocks when all \(resolution.targetCount) are completed!")
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
        
        let reward = Reward(
            descriptionText: description,
            triggerType: type,
            triggerValue: value
        )
        
        resolution.addReward(reward)
        modelContext.insert(reward)
        
        dismiss()
    }
}

#Preview {
    EditResolutionSheet(resolution: Resolution(name: "Go to the gym", descriptionText: "Get fit!", targetCount: 100))
        .modelContainer(for: [Resolution.self, LogEntry.self, Reward.self], inMemory: true)
}
