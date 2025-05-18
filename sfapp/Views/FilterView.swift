import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

struct FilterView: View {
    let theme: ThemeMode
    let viewModel: MemberViewModel
    @Binding var selectedStatus: MemberStatus?
    @Binding var selectedTag: String?
    @State private var showingMailComposer = false
    @State private var showingMessageComposer = false
    @State private var showingMessageTip = false
    @State private var showingEmailTip = false
    
    private func statusFilterBackground(status: MemberStatus) -> Color {
        let isSelected = selectedStatus == status
        if isSelected {
            return theme.isDark ? .white : .black
        }
        return theme.backgroundColor()
    }
    
    private func statusFilterForeground(status: MemberStatus) -> Color {
        let isSelected = selectedStatus == status
        if isSelected {
            return theme.isDark ? .black : .white
        }
        return theme.color(for: status)
    }
    
    private func tagFilterBackground(tag: String) -> Color {
        let isSelected = selectedTag == tag
        if isSelected {
            return theme.isDark ? .white : .black
        }
        return theme.backgroundColor()
    }
    
    private func tagFilterForeground(tag: String) -> Color {
        let isSelected = selectedTag == tag
        if isSelected {
            return theme.isDark ? .black : .white
        }
        return theme.tintColor()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Message Buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("MESSAGE FILTERED MEMBERS")
                    .font(.system(size: 10))
                    .foregroundColor(theme.foregroundColor())
                    .padding(.horizontal, 24)
                
                HStack(spacing: 8) {
                    Button {
                        showingEmailTip = true
                    } label: {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Email")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.backgroundColor())
                        .foregroundColor(theme.foregroundColor())
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.foregroundColor(), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .disabled(!MFMailComposeViewController.canSendMail())
                    
                    Button {
                        showingMessageTip = true
                    } label: {
                        HStack {
                            Image(systemName: "message")
                            Text("SMS")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.backgroundColor())
                        .foregroundColor(theme.foregroundColor())
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.foregroundColor(), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .disabled(!MFMessageComposeViewController.canSendText())
                }
                .padding(.horizontal, 24)
            }
            
            // Status Filters
            VStack(alignment: .leading, spacing: 8) {
                Text("FILTER BY STATUS")
                    .font(.system(size: 10))
                    .foregroundColor(theme.foregroundColor())
                    .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MemberStatus.allCases, id: \.self) { status in
                            Button {
                                withAnimation {
                                    selectedStatus = selectedStatus == status ? nil : status
                                }
                            } label: {
                                HStack {
                                    Image(systemName: status.icon)
                                    Text(status.rawValue)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(statusFilterBackground(status: status))
                                .foregroundColor(statusFilterForeground(status: status))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.foregroundColor().opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Tag Filters
            VStack(alignment: .leading, spacing: 8) {
                Text("FILTER BY TAGS")
                    .font(.system(size: 10))
                    .foregroundColor(theme.foregroundColor())
                    .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Show custom tags first (reverse of current order)
                        ForEach(viewModel.getAllCustomTags().reversed(), id: \.self) { tag in
                            Button {
                                withAnimation {
                                    selectedTag = selectedTag == tag ? nil : tag
                                }
                            } label: {
                                HStack {
                                    Image(systemName: tag.tagIcon)
                                    Text(tag)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(tagFilterBackground(tag: tag))
                                .foregroundColor(tagFilterForeground(tag: tag))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.foregroundColor().opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Then show default tags
                        ForEach(DefaultTags.sortedCases, id: \.self) { tag in
                            Button {
                                withAnimation {
                                    selectedTag = selectedTag == tag.rawValue ? nil : tag.rawValue
                                }
                            } label: {
                                HStack {
                                    Image(systemName: tag.icon)
                                    Text(tag.rawValue)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(tagFilterBackground(tag: tag.rawValue))
                                .foregroundColor(tagFilterForeground(tag: tag.rawValue))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.foregroundColor().opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .padding(.vertical, 8)
        .alert("Email Tip", isPresented: $showingEmailTip) {
            Button("Continue") {
                showingMailComposer = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You'll need to add your own email address in the To field since member emails are added as BCC for privacy.")
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposeView(
                recipients: viewModel.getFilteredEmails(status: selectedStatus, tag: selectedTag),
                subject: "",
                message: "",
                onDismiss: { showingMailComposer = false }
            )
        }
        .alert("SMS Best Practices", isPresented: $showingMessageTip) {
            Button("Continue") {
                showingMessageComposer = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please limit text messages to once per month and only send to members who know you and would want to receive your messages.")
        }
        .sheet(isPresented: $showingMessageComposer) {
            MessageComposeView(
                recipients: viewModel.getFilteredPhoneNumbers(status: selectedStatus, tag: selectedTag),
                message: "",
                onDismiss: { showingMessageComposer = false }
            )
        }
    }
}

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let message: String
    let onDismiss: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setBccRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(message, isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: () -> Void
        
        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
            onDismiss()
        }
    }
}

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let message: String
    let onDismiss: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.recipients = recipients
        vc.body = message
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onDismiss: () -> Void
        
        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
            onDismiss()
        }
    }
}
