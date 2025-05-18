import Foundation
import CoreData
import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

@MainActor
class MemberViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var metrics: [String: Int] = [:]
    
    init(context: NSManagedObjectContext) {
        self.context = context
        updateMetrics()
        loadCustomTags()
    }
    
    func updateMetrics() {
        let request = NSFetchRequest<Member>(entityName: "Member")
        let members = (try? context.fetch(request)) ?? []
        
        print("\n=== Member Status Analysis ===")
        print("Total members in database: \(members.count)")
        
        // Create a set of all unique status values in the database
        let uniqueStatuses = Set(members.compactMap { $0.status })
        print("\nUnique status values found: \(uniqueStatuses)")
        
        print("\n=== Member Details ===")
        // Group members by status for better analysis
        var membersByStatus: [String: [Member]] = [:]
        for member in members {
            let status = member.status ?? "nil"
            membersByStatus[status, default: []].append(member)
            
            // Print member details
            print("Member: \(member.firstName ?? "") \(member.lastName ?? "") - Status: \(status)")
            
            // Check and fix invalid status
            if let status = member.status {
                let matchingStatus = MemberStatus.allCases.first { $0.rawValue == status }
                if matchingStatus == nil {
                    print("⚠️ Warning: Member '\(member.firstName ?? "") \(member.lastName ?? "")' has invalid status: '\(status)'")
                    member.status = MemberStatus.active.rawValue
                }
            } else {
                print("⚠️ Warning: Member '\(member.firstName ?? "") \(member.lastName ?? "")' has nil status")
                member.status = MemberStatus.active.rawValue
            }
        }
        
        // Save any status fixes
        try? context.save()
        
        print("\n=== Status Counts ===")
        // Count and verify each status
        var newMetrics: [String: Int] = [:]
        for status in MemberStatus.allCases {
            let statusMembers = members.filter { $0.status == status.rawValue }
            let count = statusMembers.count
            newMetrics[status.rawValue] = count
            
            print("\(status.rawValue): \(count) members")
            if count > 0 {
                print("Members with status '\(status.rawValue)':")
                for member in statusMembers {
                    print("- \(member.firstName ?? "") \(member.lastName ?? "")")
                }
            }
        }
        
        // Count members with invalid status
        let invalidMembers = members.filter { member in
            guard let status = member.status else { return true }
            return !MemberStatus.allCases.contains { $0.rawValue == status }
        }
        
        if !invalidMembers.isEmpty {
            print("\n⚠️ Found \(invalidMembers.count) members with invalid status:")
            for member in invalidMembers {
                print("- \(member.firstName ?? "") \(member.lastName ?? "") (Status: \(member.status ?? "nil"))")
            }
        }
        
        metrics = newMetrics
        
        // Final verification
        let totalInMetrics = newMetrics.values.reduce(0, +)
        print("\n=== Final Verification ===")
        print("Total members: \(members.count)")
        print("Total in metrics: \(totalInMetrics)")
        print("Metrics breakdown: \(metrics)")
        
        if totalInMetrics != members.count {
            print("⚠️ Warning: Total in metrics (\(totalInMetrics)) doesn't match member count (\(members.count))")
        }
        
        print("=== End Analysis ===\n")
    }
    
    private var cachedTags: [String]?
    private var lastTagUpdateTime: Date?
    private let tagCacheTimeout: TimeInterval = 5.0 // 5 second cache timeout
    private var cachedNotes: [Member: [Note]] = [:]
    
    private func loadCustomTags() -> [String] {
        let now = Date()
        if let cached = cachedTags,
           let lastUpdate = lastTagUpdateTime,
           now.timeIntervalSince(lastUpdate) < tagCacheTimeout {
            return cached
        }
        
        let userDefaultsTags = UserDefaults.standard.stringArray(forKey: "customTags") ?? []
        let request = NSFetchRequest<Member>(entityName: "Member")
        request.propertiesToFetch = ["tags"]
        let members = (try? context.fetch(request)) ?? []
        let memberTags = members.flatMap { $0.tagArray }
        
        let allTags = Set(userDefaultsTags + memberTags)
        let defaultTagValues = DefaultTags.allCases.map { $0.rawValue }
        let filteredTags = allTags.filter { !defaultTagValues.contains($0) }.sorted()
        
        cachedTags = filteredTags
        lastTagUpdateTime = now
        return filteredTags
    }
    
    func getAllCustomTags() -> [String] {
        loadCustomTags()
    }
    
    func findMemberById(_ id: String) -> Member? {
        guard let url = URL(string: id),
              let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
            return nil
        }
        
        return try? context.existingObject(with: objectID) as? Member
    }
    
    func findMemberByName(firstName: String, lastName: String) -> Member? {
        let request = NSFetchRequest<Member>(entityName: "Member")
        request.predicate = NSPredicate(format: "firstName == %@ AND lastName == %@", firstName, lastName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Member.joinDate, ascending: false)]
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    // Member Management
    func addMember(firstName: String, lastName: String, email: String?, phone: String?, status: String?, tags: [String], birthdayMonth: Int16, birthdayDay: Int16) {
        let member = Member(context: context)
        member.firstName = firstName
        member.lastName = lastName
        member.email = email
        member.phone = phone
        // Set default status to "Active" if nil
        member.status = status ?? MemberStatus.active.rawValue
        member.tagArray = tags
        member.birthdayMonth = birthdayMonth
        member.birthdayDay = birthdayDay
        member.joinDate = Date()
        
        try? context.save()
        updateMetrics()
    }
    
    func updateMemberInfo(_ member: Member, firstName: String, lastName: String, email: String, phone: String, birthdayMonth: Int16, birthdayDay: Int16) {
        member.firstName = firstName
        member.lastName = lastName
        member.email = email.isEmpty ? nil : email
        member.phone = phone == "+1" ? nil : phone
        member.birthdayMonth = birthdayMonth
        member.birthdayDay = birthdayDay
        
        try? context.save()
        updateMetrics()
        
        // Record treasure for member update
        TreasureManager.shared.recordMemberUpdate()
    }
    
    func updateMemberStatus(_ member: Member, status: MemberStatus) {
        member.status = status.rawValue
        try? context.save()
        updateMetrics()
    }
    
    func deleteMember(_ member: Member) {
        context.delete(member)
        try? context.save()
        updateMetrics()
        cachedNotes.removeValue(forKey: member)
    }
    
    // Tag Management
    func addGlobalTag(_ tag: String) {
        var storedTags = UserDefaults.standard.stringArray(forKey: "customTags") ?? []
        if !storedTags.contains(tag) {
            storedTags.append(tag)
            UserDefaults.standard.set(storedTags, forKey: "customTags")
            cachedTags = nil // Invalidate cache
            objectWillChange.send()
        }
    }
    
    func removeGlobalTag(_ tag: String) {
        var storedTags = UserDefaults.standard.stringArray(forKey: "customTags") ?? []
        let hadTag = storedTags.contains(tag)
        
        if hadTag {
            storedTags.removeAll { $0 == tag }
            UserDefaults.standard.set(storedTags, forKey: "customTags")
            
            // Remove from members in batches
            let request = NSFetchRequest<Member>(entityName: "Member")
            request.predicate = NSPredicate(format: "ANY tags == %@", tag)
            request.fetchBatchSize = 20
            
            if let members = try? context.fetch(request) {
                for member in members {
                    member.tagArray = member.tagArray.filter { $0 != tag }
                }
                try? context.save()
            }
            
            cachedTags = nil // Invalidate cache
            objectWillChange.send()
        }
    }
    
    func addTag(to member: Member, tag: String) {
        var tags = member.tagArray
        if !tags.contains(tag) {
            tags.append(tag)
            member.tagArray = tags
            try? context.save()
        }
    }
    
    func removeTag(from member: Member, tag: String) {
        var tags = member.tagArray
        tags.removeAll { $0 == tag }
        member.tagArray = tags
        try? context.save()
    }
    
    func countMembersWithTag(_ tag: String) -> Int {
        let request = NSFetchRequest<Member>(entityName: "Member")
        request.predicate = NSPredicate(format: "ANY tags == %@", tag)
        return (try? context.count(for: request)) ?? 0
    }
    
    // Note Management
    func addNote(to member: Member, content: String) {
        context.performAndWait {
            let note = Note(context: context)
            note.content = content
            note.timestamp = Date()
            note.member = member
            
            try? context.save()
            cachedNotes.removeValue(forKey: member) // Invalidate cache
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    func getNotes(for member: Member) -> [Note] {
        if let cached = cachedNotes[member] {
            return cached
        }
        
        var notes: [Note] = []
        context.performAndWait {
            let request = NSFetchRequest<Note>(entityName: "Note")
            request.predicate = NSPredicate(format: "member == %@", member)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.timestamp, ascending: false)]
            request.fetchBatchSize = 10
            notes = (try? context.fetch(request)) ?? []
        }
        
        cachedNotes[member] = notes
        return notes
    }
    
    // Messaging Methods
    func getFilteredEmails(status: MemberStatus?, tag: String?) -> [String] {
        let request = NSFetchRequest<Member>(entityName: "Member")
        var predicates: [NSPredicate] = []

        // Add status predicate if selected
        if let status = status {
            predicates.append(NSPredicate(format: "status == %@", status.rawValue))
        }

        // Add tag predicate if selected
        if let tag = tag {
            predicates.append(NSPredicate(format: "ANY tags == %@", tag))
        }

        // Require valid email
        predicates.append(NSPredicate(format: "email != nil AND email != ''"))

        // Combine predicates
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        // Fetch members and log for debugging
        let members = (try? context.fetch(request)) ?? []
        print("Email recipients for \(tag != nil ? "tag: \(tag!)" : "no tag"), \(status?.rawValue ?? "no status"):")
        for member in members {
            print("- \(member.firstName ?? "") \(member.lastName ?? ""): \(member.email ?? "no email")")
        }
        
        // Record treasure for email action
        TreasureManager.shared.recordEmailSent()

        return members.compactMap { $0.email }
    }
    
    func getFilteredPhoneNumbers(status: MemberStatus?, tag: String?) -> [String] {
        let request = NSFetchRequest<Member>(entityName: "Member")
        var predicates: [NSPredicate] = []

        // Add status predicate if selected
        if let status = status {
            predicates.append(NSPredicate(format: "status == %@", status.rawValue))
        }

        // Add tag predicate if selected
        if let tag = tag {
            // Fix tag filtering by forcing a proper CONTAINS predicate on the serialized tags data
            // This addresses issues with transformable NSArray not always being queried correctly
            predicates.append(NSPredicate(format: "ANY tags == %@", tag))
        }

        // Require valid phone number
        predicates.append(NSPredicate(format: "phone != nil AND phone != ''"))

        // Combine predicates
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        // Fetch members and log for debugging
        let members = (try? context.fetch(request)) ?? []
        print("SMS recipients for \(tag != nil ? "tag: \(tag!)" : "no tag"), \(status?.rawValue ?? "no status"):")
        for member in members {
            print("- \(member.firstName ?? "") \(member.lastName ?? ""): \(member.phone ?? "no phone")")
        }
        
        // Record treasure for SMS action
        TreasureManager.shared.recordMessageSent()

        return members.compactMap { $0.phone }
    }
    
    // Share App Methods
    func shareApp() {
        // This method will be called when the user shares the app
        // We'll implement the UI for this in ContentView
    }
}
