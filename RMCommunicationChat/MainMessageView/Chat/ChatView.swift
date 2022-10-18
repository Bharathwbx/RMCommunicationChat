import SwiftUI
import SDWebImageSwiftUI

struct ChatView: View {
    @ObservedObject var vm: ChatViewModel
    @State var shouldShowLogOutOptions = false
    
    var body: some View {
        VStack{
            customNavBar
            messagesView
            chatBottomBar
        }
//        .navigationTitle(vm.chatUser?.name ?? "")
//        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.firestoreListener?.remove()
        }
        .navigationBarBackButtonHidden(vm.chatUser?.uid == FirebaseConstant.rmManagerUID )
    }
    
    private var customNavBar: some View {
        VStack(spacing: 8) {
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipped()
                .cornerRadius(.infinity)
                .shadow(color: .gray, radius: 4, x: 0.0, y: 2)
            
            Text(vm.chatUser?.name ?? "")
                .font(.system(size: 24, weight: .bold))
            if vm.chatUser?.uid == FirebaseConstant.rmManagerUID {
                Text("Relationship Manager")
                    .font(.system(size: 20, weight: .bold))
                
                Button {
                    vm.openMaps()
                } label: {
                    Text("777 Flower St, Los Angeles")
                }
                Text("818-766-5124")
                    .foregroundColor(.blue)
                
                Button {
                    shouldShowLogOutOptions.toggle()
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(.white))
                }
                .actionSheet(isPresented: $shouldShowLogOutOptions) {
                    .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                        .destructive(Text("Sign Out"), action: {
                            vm.handleSignOut()
                        }), .cancel()])
                }
            }
        }
    }
    
    static let emptyScrollString = "Empty"
    
    private var messagesView: some View {
        ScrollView {
            ScrollViewReader { scrollViewProxy in
                VStack {
                    ForEach(vm.chatMessages) { message in
                        MessageView(message: message)
                    }
                    HStack { Spacer() }
                        .id(Self.emptyScrollString)
                }
                .onReceive(vm.$count) { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        scrollViewProxy.scrollTo(Self.emptyScrollString, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.init(gray: 0.95, alpha: 1)))
        .padding(.top, 1)
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            if #available(iOS 16.0, *) {
                TextField("Description", text: $vm.chatText, axis: .vertical)
            } else {
                // Fallback on earlier versions
                TextField("Description", text: $vm.chatText)
            }
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(Color.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct MessageView: View {
    let message: ChatMessage
    var body: some View {
        VStack {
            if FirebaseManager.shared.auth.currentUser?.uid == message.fromId {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(vm: ChatViewModel(chatUser: .init(data: ["uid":"nQGOjonOWLazHE6tWQJGyyHahzE3", "email": "testuser11@cnb.com"])))
    }
}
