import SwiftUI

struct ChatView: View {
    @ObservedObject var vm: ChatViewModel
    
    var body: some View {
        VStack{
            messagesView
            chatBottomBar
        }
        .navigationTitle(vm.chatUser?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.firestoreListener?.remove()
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
