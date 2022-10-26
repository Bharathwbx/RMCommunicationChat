import SwiftUI
import SDWebImageSwiftUI
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
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timeStamp, relativeTo: Date())
    }
}

class MainMessageViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    
    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchRecentMessages()
        fetchCurrentUser()
    }
    
    @Published var recentMessages: [RecentMessage] = []
    
    private var fireStoreListner: ListenerRegistration?
    
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
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessageView: View {
    
    @ObservedObject private var vm = MainMessageViewModel()
    @State var shouldShowLogOutOptions = false
    @State var shouldNavigateToChatLogView = false
    
    private var chatlogViewModel = ChatLogViewModel(chatUser: nil)
    
    var body: some View {
        NavigationView {
            VStack {
//                customNavBar
                messagesView
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(vm: chatlogViewModel)
                }
            }
            .overlay(newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    
//    private var customNavBar: some View {
//        HStack(spacing: 16) {
//
//            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
//                .resizable()
//                .scaledToFill()
//                .frame(width: 50, height: 50)
//                .clipped()
//                .cornerRadius(50)
//                .overlay(RoundedRectangle(cornerRadius:44).stroke(Color(.label), lineWidth: 1)
//                )
//                .shadow(radius: 5)
//
//            VStack(alignment: .leading, spacing: 4) {
//                let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
//                Text(email)
//                    .font(.system(size: 24, weight: .bold))
//                HStack {
//                    Circle()
//                        .foregroundColor(.green)
//                        .frame(width: 14, height: 14)
//                    Text("Online")
//                        .font(.system(size: 12))
//                        .foregroundColor(Color(.lightGray))
//                }
//            }
//            Spacer()
//
//            Button {
//                shouldShowLogOutOptions.toggle()
//            } label: {
//                Image(systemName: "gear")
//                    .font(.system(size: 24, weight: .bold))
//                    .foregroundColor(Color(.label))
//            }
//        }
//        .padding()
//        .actionSheet(isPresented: $shouldShowLogOutOptions) {
//            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
//                .destructive(Text("Sign Out"), action: {
//                    vm.handleSignOut()
//                }), .cancel()])
//        }
//        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
//            LoginView(didCompleteLoginProcess: {
//                vm.isUserCurrentlyLoggedOut = false
//                vm.fetchCurrentUser()
//                vm.fetchRecentMessages()
//            })
//        }
//    }
        
    private var messagesView: some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                VStack {
                    Button {
                        let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
                        self.chatUser = .init(data:
                                                [FirebaseConstant.email: recentMessage.email,
                                                 FirebaseConstant.profileImageURL: recentMessage.profileImageURL,
                                                 FirebaseConstant.uid: uid])
                        chatlogViewModel.chatUser = chatUser
                        chatlogViewModel.fetchMessages()
                        shouldNavigateToChatLogView.toggle()
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: recentMessage.profileImageURL))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(RoundedRectangle(cornerRadius: 64)
                                    .stroke(Color.black, lineWidth: 1))
                                .shadow(radius: 5)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recentMessage.userName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                    .multilineTextAlignment(.leading)
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.lightGray))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Text(recentMessage.timeAgo)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                    }
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }
    
    @State var shouldShowNewMessageScreen = false
    
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView { user in
                shouldNavigateToChatLogView.toggle()
                chatUser = user
                chatlogViewModel.chatUser = user
                chatlogViewModel.fetchMessages()
            }
        }
    }
    @State var chatUser: ChatUser?
}

struct MainMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessageView()
//            .preferredColorScheme(.dark)
    }
}
