//
//  OnboardingView.swift
//  sfapp
//
//  Created by Aaron West on 11/27/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import StoreKit

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showingPaywall = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    let theme: ThemeMode
    
    private var offWhite: Color {
        ThemeMode.light.backgroundColor()
    }
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                EmptyView() // This will effectively dismiss the onboarding view
            } else {
                VStack(spacing: 24) {
            // Logo Header
            HStack(spacing: 4) {
                Image("sheepfold-logo")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 24)
                
                Text("- Flock Management App")
                    .font(.system(size: 14))
            }
            .foregroundColor(offWhite)
            .padding(.top, 24)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(offWhite.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .foregroundColor(offWhite)
                        .frame(width: geometry.size.width * CGFloat(viewModel.progress), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
            
            // Question
            Text(viewModel.questions[viewModel.currentQuestionIndex].question)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(offWhite)
            
            // Options
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.questions[viewModel.currentQuestionIndex].options, id: \.self) { option in
                        Button {
                            viewModel.selectOption(option)
                        } label: {
                            HStack {
                                Text(option)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                if viewModel.questions[viewModel.currentQuestionIndex].selectedOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .padding()
                            .background(
                                viewModel.questions[viewModel.currentQuestionIndex].selectedOption == option ?
                                offWhite :
                                offWhite.opacity(0.2)
                            )
                            .foregroundColor(viewModel.questions[viewModel.currentQuestionIndex].selectedOption == option ? .black : offWhite)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Only show Continue button and data notice on last question
            if viewModel.isLastQuestion && viewModel.canProceed {
                VStack(spacing: 16) {
                    // Data collection notice
                    Text("By continuing, you agree that your anonymous survey responses may be collected to improve the app. All member data will remain private on your device.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(offWhite.opacity(0.7))
                        .padding(.horizontal)
                    
                    Button {
                        showingPaywall = true
                    } label: {
                        Text("Continue to Setup")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(offWhite)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }
            }
                }
                .padding(.vertical, 24)
                .background(.black)
        .fullScreenCover(isPresented: $showingPaywall, onDismiss: {
            // If onboarding was completed, don't show the continue button again
            if hasCompletedOnboarding {
                showingPaywall = false
            }
        }) {
            PaywallView(theme: theme, responses: viewModel.getResponses()) {
                hasCompletedOnboarding = true
            }
        }
            }
        }
    }
}

struct PaywallView: View {
    let theme: ThemeMode
    let responses: [(String, String)]
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isInitialLoad = true
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var showingCodeEntry = false
    @State private var verificationCode = ""
    
    // Detect if we're on iPad
    private var isIPad: Bool {
        return horizontalSizeClass == .regular
    }
    
    private let validCode = "SF4P-9X2M-QW7Z-8Y3N-RT6K-LP5J-HG1V"
    
    private var offWhite: Color {
        ThemeMode.light.backgroundColor()
    }
    
    enum SubscriptionPlan {
        case monthly
        case annual
    }
    
    private func handleCompletion(skipFirebase: Bool = false) {
        if !skipFirebase {
            print("PaywallView: Saving responses to Firebase...")
            print("Responses:")
            for (question, answer) in responses {
                print("\(question): \(answer)")
            }
            
            // Save to Firebase
            FirebaseManager.shared.saveOnboardingResponses(responses)
        }
        
        // Set subscription as active for testers/reviewers
        if skipFirebase {
            Task {
                await subscriptionManager.setSubscriptionActive(true)
            }
        }
        
        // Complete onboarding and dismiss
        onComplete()
        dismiss()
    }
    
    private func verifyCode() {
        if verificationCode.trimmingCharacters(in: .whitespacesAndNewlines) == validCode {
            // Skip Firebase save for testers/reviewers and complete onboarding
            handleCompletion(skipFirebase: true)
        } else {
            errorMessage = "Invalid verification code"
            showError = true
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    // Center content for iPad
                    HStack {
                        if isIPad { Spacer() }
                        
                        // Main content container
                        VStack(spacing: 24) {
                            // Logo Header
                            HStack(spacing: 4) {
                                Image("sheepfold-logo")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 24)
                                
                                Text("- Flock Management App")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(offWhite)
                            .padding(.top, 24)
                        
                            // Icon
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 60))
                                .foregroundColor(offWhite)
                                .padding(.top, 24)
                        
                                // Title and Special Offer
                                VStack(spacing: 8) {
                                    Text("Free Trial")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(offWhite)

                                    Text("First Month Only")
                                        .font(.title2)
                                        .foregroundColor(offWhite.opacity(0.7))

                                    Text("FREE")
                                        .font(.system(size: 60, weight: .bold))
                                        .foregroundColor(offWhite)

                                    Text(selectedPlan == .monthly ? "then $14.99/month" : "then $149/year")
                                        .font(.subheadline)
                                        .foregroundColor(offWhite.opacity(0.7))
                                }
                        
                            // Plan Selection
                            VStack(spacing: 12) {
                                Button {
                                    selectedPlan = .monthly
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Monthly Plan")
                                                .font(.headline)
                                            Text("$14.99 per month")
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                        if selectedPlan == .monthly {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(selectedPlan == .monthly ? offWhite : offWhite.opacity(0.1))
                                    .foregroundColor(selectedPlan == .monthly ? .black : offWhite)
                                    .cornerRadius(12)
                                }
                                
                                Button {
                                    selectedPlan = .annual
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Annual Plan")
                                                .font(.headline)
                                            Text("$149 per year (Save $30)")
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                        if selectedPlan == .annual {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(selectedPlan == .annual ? offWhite : offWhite.opacity(0.1))
                                    .foregroundColor(selectedPlan == .annual ? .black : offWhite)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        
                            // Features
                            VStack(alignment: .leading, spacing: 16) {
                                Group {
                                    FeatureRow(icon: "person.3.fill", text: "Unlimited Member Profiles", theme: theme)
                                    FeatureRow(icon: "tag.fill", text: "Custom Member Attributes", theme: theme)
                                    FeatureRow(icon: "note.text", text: "Member Timeline & Notes", theme: theme)
                                    FeatureRow(icon: "phone.fill", text: "Quick Contact Actions", theme: theme)
                                    FeatureRow(icon: "birthday.cake.fill", text: "Birthday Tracking", theme: theme)
                                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Member Health Tracking", theme: theme)
                                }
                                
                                Divider()
                                    .background(offWhite.opacity(0.3))
                                    .padding(.vertical, 8)
                                
                                Group {
                                    FeatureRow(icon: "wifi.slash", text: "Works Offline - No Internet Needed", theme: theme)
                                    FeatureRow(icon: "lock.fill", text: "Private Local Storage", theme: theme)
                                    FeatureRow(icon: "bolt.fill", text: "Fast Native Performance", theme: theme)
                                }
                            }
                            .padding()
                            .background(offWhite.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        
                            // Price Button
                            Button {
                                print("PaywallView: Purchase button tapped for \(selectedPlan == .monthly ? "monthly" : "annual") plan")
                                Task {
                                    do {
                                        // Attempt to purchase the subscription
                                        try await subscriptionManager.purchaseSubscription(isAnnual: selectedPlan == .annual)
                                        
                                        // Verify subscription status after purchase
                                        await subscriptionManager.checkSubscriptionStatus()
                                        
                                        if subscriptionManager.isSubscriptionActive {
                                            print("PaywallView: Purchase completed successfully - subscription is active")
                                            handleCompletion(skipFirebase: false)
                                        } else {
                                            print("PaywallView: Purchase completed but subscription is not active - retrying verification")
                                            // Try one more time with a delay
                                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                            await subscriptionManager.checkSubscriptionStatus()
                                            
                                            if subscriptionManager.isSubscriptionActive {
                                                print("PaywallView: Subscription activated after retry")
                                                handleCompletion(skipFirebase: false)
                                            } else {
                                                print("PaywallView: Subscription still not active after retry")
                                                errorMessage = "Your purchase was processed, but we couldn't verify your subscription. Please try restoring purchases."
                                                showError = true
                                            }
                                        }
                                    } catch {
                                        print("PaywallView: Purchase failed - \(error.localizedDescription)")
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    if subscriptionManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text("Start Your Free Trial")
                                            .font(.headline)
                                        Text("No payment required")
                                            .font(.subheadline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(offWhite)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                            .disabled(subscriptionManager.isLoading)
                            .padding(.horizontal)
                        
                            // Terms and Subscription Details
                            VStack(spacing: 8) {
                                // Subscription details
                                VStack(spacing: 4) {
                                    Text("Cancel anytime before the trial ends.")
                                        .font(.caption)
                                        .foregroundColor(offWhite.opacity(0.7))
                                    Text(selectedPlan == .monthly ? "Regular price $14.99/month after trial." : "Regular price $149/year after trial.")
                                        .font(.caption)
                                        .foregroundColor(offWhite.opacity(0.7))
                                    Text(selectedPlan == .monthly ? "Subscription length: 1 month (auto-renewing)" : "Subscription length: 1 year (auto-renewing)")
                                        .font(.caption)
                                        .foregroundColor(offWhite.opacity(0.7))
                                }
                                
                                // Links to Terms and Privacy Policy
                                HStack(spacing: 16) {
                                    Link("Terms of Use", destination: URL(string: "https://zygur.com/labs/sheepfold")!)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Link("Privacy Policy", destination: URL(string: "https://zygur.com/labs/sheepfold")!)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 4)
                            }
                        
                            // Restore Button
                            Button {
                                print("PaywallView: Restore purchases button tapped")
                                Task {
                                    do {
                                        // Attempt to restore purchases
                                        try await subscriptionManager.restorePurchases()
                                        
                                        // Check if subscription is active after restore
                                        if subscriptionManager.isSubscriptionActive {
                                            print("PaywallView: Restore successful - subscription is active")
                                            handleCompletion(skipFirebase: false)
                                        } else {
                                            print("PaywallView: Restore completed but no active subscription found - retrying verification")
                                            // Try one more time with a delay
                                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                            await subscriptionManager.checkSubscriptionStatus()
                                            
                                            if subscriptionManager.isSubscriptionActive {
                                                print("PaywallView: Subscription activated after restore retry")
                                                handleCompletion(skipFirebase: false)
                                            } else {
                                                print("PaywallView: No active subscription found after restore")
                                                errorMessage = "No active subscription was found. If you believe this is an error, please contact support."
                                                showError = true
                                            }
                                        }
                                    } catch {
                                        print("PaywallView: Restore failed - \(error.localizedDescription)")
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                }
                            } label: {
                                Text("Restore Purchases")
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 8)
                        
                            // Tester/Reviewer Access
                            Button {
                                showingCodeEntry = true
                            } label: {
                                Text("I'm a tester / reviewer")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .padding(.top, 4)
                            .padding(.bottom, 24)
                        }
                        .frame(width: isIPad ? 500 : nil)
                        .padding(.horizontal, isIPad ? 0 : 16)
                        
                        if isIPad { Spacer() }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Enter Verification Code", isPresented: $showingCodeEntry) {
                TextField("Code", text: $verificationCode)
                    .textInputAutocapitalization(.characters)
                Button("Verify", action: verifyCode)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enter your verification code")
            }
            .task {
                if isInitialLoad {
                    print("PaywallView: Initial load, fetching products")
                    await subscriptionManager.loadProducts()
                    isInitialLoad = false
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(theme: .dark)
    }
}
