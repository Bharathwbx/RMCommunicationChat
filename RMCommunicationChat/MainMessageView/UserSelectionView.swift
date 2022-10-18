import SwiftUI
import Firebase
import SDWebImageSwiftUI

struct UserSelectionView: View {
    @ObservedObject private var vm = UserSelectionViewModel()
    @State var shouldShowLogOutOptions = false
    @State var shouldNavigateToChatView = false
    @State var selectedChatUser: ChatUser?
    
    @State var chatUser: ChatUser?

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                customNavBar
                allClientsView
                chattedClientsView
                NavigationLink("", isActive: $shouldNavigateToChatView) {
                    ChatView(vm: ChatViewModel(chatUser: selectedChatUser))
                }
            }
        }
    }
    
    private var customNavBar: some View {
        HStack {
//            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
//                .resizable()
//                .scaledToFill()
//                .frame(width: 64, height: 64)
//                .clipped()
//                .cornerRadius(.infinity)
//                .shadow(color: .gray, radius: 4, x: 0.0, y: 2)

//            VStack(alignment: .leading, spacing: 4) {
//                Text(vm.chatUser?.name ?? "")
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
            Spacer()
            
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(Color(.white))
            }
        }
//        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    vm.handleSignOut()
                }), .cancel()])
        }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                vm.isUserCurrentlyLoggedOut = false
                vm.fetchCurrentUser()
                vm.fetchAllUsers()
                vm.fetchRecentMessages()
                if FirebaseManager.shared.auth.currentUser?.uid != FirebaseConstant.rmManagerUID {
                    selectedChatUser = ChatUser(data: [FirebaseConstant.uid: FirebaseConstant.rmManagerUID, FirebaseConstant.profileImageURL: "https://firebasestorage.googleapis.com:443/v0/b/client-rm-chat.appspot.com/o/itzIT5LQomdKNrBGgGAlw1fNsys1?alt=media&token=da60f405-a0b0-4457-a1a0-63bd9cd57afe", FirebaseConstant.email: "mob5test5@cnb.com"])
                    shouldNavigateToChatView.toggle()
                }
            })
        }
    }
    
    private var allClientsView: some View {
        VStack {
            HStack {
                Text("My Clients")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }.padding(.horizontal)
            
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(vm.users) { user in
                        Button {
                            print("Clicked on \(user.name)")
                            self.selectedChatUser = user
                            shouldNavigateToChatView.toggle()
                        } label: {
                            VStack(spacing: 8) {
                                WebImage(url: URL(string: user.profileImageUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipped()
                                    .cornerRadius(.infinity)
                                    .shadow(color: .gray, radius: 3, x: 0.0, y: 2)
                                Text(user.name)
                                    .foregroundColor(Color(.label))
                                    .font(.system(size: 12, weight: .semibold))
                            }
                        }
                    }
                }.padding(.horizontal)
            }
        }
    }
    
    private var chattedClientsView: some View {
        VStack {
            HStack {
                Text("Recent Messages")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }.padding(.horizontal)
            
            ScrollView {
                ForEach(vm.recentMessages) { recentMessage in
                    VStack {
                        Button {
                            let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
                            self.chatUser = .init(data:
                                                    [FirebaseConstant.email: recentMessage.email,
                                                     FirebaseConstant.profileImageURL: recentMessage.profileImageURL,
                                                     FirebaseConstant.uid: uid])
                            //                        vm.chatUser = chatUser
                            selectedChatUser = chatUser
                            shouldNavigateToChatView.toggle()
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
                                    Text(recentMessage.name)
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
    }
}

struct UserSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        UserSelectionView()
    }
}
