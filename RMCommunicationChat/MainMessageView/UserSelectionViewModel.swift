import Foundation
import Firebase
import FirebaseFirestoreSwift

struct RecentMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let email, text: String
    let toId, fromId: String
    let profileImageURL: String
    let timeStamp: Date
    
    var userName: String {
        email.components(separatedBy: "@").first ?? email
    }
    
    var name: String {
        email.replacingOccurrences(of: "@cnb.com", with: "").capitalized
    }

    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timeStamp, relativeTo: Date())
    }
}

class UserSelectionViewModel: ObservableObject {
    @Published var isUserCurrentlyLoggedOut = false
    @Published var errorMessage = ""
    @Published var users: [ChatUser] = []
    @Published var chatUser: ChatUser?
    @Published var recentMessages: [RecentMessage] = []
    
    private var fireStoreListner: ListenerRegistration?

    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
        fetchAllUsers()
        fetchRecentMessages()
    }
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
    
    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            errorMessage = "Unable to find firebase uid"
            return
        }
        
        FirebaseManager.shared.fireStore.collection("users").document(uid).getDocument { [weak self] snapshot, err in
            if let err = err {
                self?.errorMessage = "Unable to get snapshotdata : \(err)"
                return
            }
            
            guard let data = snapshot?.data() else {
                self?.errorMessage = "Unable to get snapshotdata"
                return
            }
            self?.chatUser = ChatUser(data: data)
        }
    }
    
    func fetchAllUsers() {
        users.removeAll()
        FirebaseManager.shared.fireStore.collection("users").getDocuments { [weak self] dataSnapshot, error in
            if let error = error {
                self?.errorMessage = "Unable to fetch users \(error)"
                return
            }
            var chatusers: [ChatUser] = []
            dataSnapshot?.documents.forEach({ snapshot in
                let data = snapshot.data()
                let user = ChatUser(data: data)
                if user.uid != FirebaseManager.shared.auth.currentUser?.uid {
                    chatusers.append(.init(data: data))
                }
            })
            self?.users = chatusers.sorted { $0.name < $1.name }
            print("Data Fetched successfully...")
        }
    }
    
    func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        fireStoreListner?.remove()
        recentMessages.removeAll()
        
        fireStoreListner = FirebaseManager.shared.fireStore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: FirebaseConstant.timeStamp)
            .addSnapshotListener { querySnapShot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for recent messages: \(error)"
                    print(self.errorMessage)
                    return
                }
                querySnapShot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    if let index = self.recentMessages.firstIndex(where: { $0.id == docId }) {
                        self.recentMessages.remove(at: index)
                    }

                    do {
                        let rm = try change.document.data(as: RecentMessage.self)
                        self.recentMessages.insert(rm, at: 0)
                    } catch {
                        print(error)
                    }
                })
            }
    }
}
