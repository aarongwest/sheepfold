import SwiftUI

struct MemberRowView: View {
    let member: Member
    let theme: ThemeMode
    
    private var status: MemberStatus {
        if let statusString = member.status,
           !statusString.isEmpty,
           let status = MemberStatus(rawValue: statusString) {
            return status
        }
        return .inactive
    }
    
    private var fullName: String {
        let first = member.firstName ?? ""
        let last = member.lastName ?? ""
        if first.isEmpty && last.isEmpty {
            return "Unknown"
        }
        return [first, last].filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Status Icon
            Image(systemName: status.icon)
                .foregroundColor(theme.color(for: status))
                .font(.system(size: 14))
            
            // Name and Status
            VStack(alignment: .leading, spacing: 2) {
                Text(fullName)
                    .font(.system(size: 14))
                    .foregroundColor(theme.foregroundColor())
                
                Text(member.status ?? "Unknown")
                    .font(.system(size: 10))
                    .foregroundColor(theme.foregroundColor())
            }
            
            // Tags (right-aligned)
            HStack(spacing: 6) {
                Spacer() // Push tags to the right
                
                // First show custom tags, then default tags
                // Split tags into custom and default
                let defaultTagValues = DefaultTags.allCases.map { $0.rawValue }
                let customTags = member.tagArray.filter { !defaultTagValues.contains($0) }
                let defaultTags = member.tagArray.filter { defaultTagValues.contains($0) }
                
                // Show custom tags first
                ForEach(customTags, id: \.self) { tag in
                    Image(systemName: tag.tagIcon)
                        .foregroundColor(theme.foregroundColor())
                        .font(.system(size: 10))
                }
                
                // Then show default tags
                ForEach(defaultTags, id: \.self) { tag in
                    Image(systemName: tag.tagIcon)
                        .foregroundColor(theme.foregroundColor())
                        .font(.system(size: 10))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 28)
    }
}

struct MemberRowPreview: View {
    let theme: ThemeMode = .light
    
    var body: some View {
        let context = PersistenceController.preview.container.viewContext
        let member = Member(context: context)
        member.firstName = "John"
        member.lastName = "Smith"
        member.status = MemberStatus.active.rawValue
        member.tagArray = [
            DefaultTags.prayerWarrior.rawValue,
            DefaultTags.leader.rawValue,
            "Custom Tag"
        ]
        
        return MemberRowView(member: member, theme: theme)
            .padding(.horizontal, 16)
            .frame(width: 375, height: 44)
            .background(theme.backgroundColor(elevated: true))
    }
}

#Preview {
    MemberRowPreview()
}
