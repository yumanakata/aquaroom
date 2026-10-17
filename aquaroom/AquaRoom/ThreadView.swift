import SwiftUI

struct ThreadView: View {
    @EnvironmentObject var store: RoomStore
    let threadID: UUID
    @State private var text = ""

    var body: some View {
        if let t = store.threads.first(where: { $0.id == threadID }) {
            VStack(spacing: 0) {
                header(t)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(store.messages[threadID] ?? []) { bubble($0).id($0.id) }
                        }.padding()
                    }
                    .onChange(of: store.messages[threadID]?.count) { _ in
                        if let last = store.messages[threadID]?.last { proxy.scrollTo(last.id) }
                    }
                }
                inputBar
            }
            .navigationTitle(t.title)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            Text("このスレッドは消えました 🫧").foregroundStyle(.secondary)
        }
    }

    private func header(_ t: ThreadInfo) -> some View {
        let r = max(0, Int(t.expiresAt.timeIntervalSinceNow))
        return HStack {
            Text(String(format: "消滅まで %d:%02d", r / 60, r % 60)).monospacedDigit()
            Spacer()
            Button("⏳ 延長に投票 \(store.voteCount(threadID))/\(store.needVotes(threadID))") {
                store.voteExtend(threadID)
            }.buttonStyle(.bordered)
        }
        .font(.footnote).padding(.horizontal).padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func bubble(_ m: Message) -> some View {
        let mine = m.senderID == store.myID
        return VStack(alignment: mine ? .trailing : .leading, spacing: 2) {
            Text(m.senderName).font(.caption2).foregroundStyle(.secondary)
            Text(m.text).padding(10)
                .background(mine ? Color.cyan.opacity(0.6) : Color.gray.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }

    private var inputBar: some View {
        HStack {
            TextField("メッセージ", text: $text).textFieldStyle(.roundedBorder)
            Button {
                let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !s.isEmpty else { return }
                store.post(s, in: threadID); text = ""
            } label: { Image(systemName: "paperplane.fill") }
        }.padding()
    }
}
