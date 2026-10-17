import SwiftUI

func categoryColor(_ c: String) -> Color {
    switch c {
    case "グルメ": return .orange
    case "イベント": return .pink
    case "相談": return .green
    default: return .cyan
    }
}

struct AquariumView: View {
    @EnvironmentObject var store: RoomStore
    @State private var showNew = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    LinearGradient(colors: [Color(red: 0.0, green: 0.25, blue: 0.45), Color(red: 0.0, green: 0.05, blue: 0.2)],
                                   startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                    if store.threads.isEmpty {
                        Text("まだ誰もいません 🫧\n右上の＋で魚を放とう")
                            .multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.7))
                    }
                    ForEach(store.threads) { t in
                        // UUIDの先頭バイトから位置を決める（端末間で近い配置になる）
                        let u = t.id.uuid
                        NavigationLink(value: t) {
                            FishView(thread: t, count: max(store.participants(t.id).count, 1))
                        }
                        .buttonStyle(.plain)
                        .position(x: 60 + (geo.size.width - 120) * Double(u.0) / 255,
                                  y: 60 + (geo.size.height - 160) * Double(u.1) / 255)
                    }
                }
            }
            .navigationTitle("近くの水槽 (\(store.peerCount)人)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ThreadInfo.self) { ThreadView(threadID: $0.id) }
            .toolbar { Button { showNew = true } label: { Image(systemName: "plus.circle.fill") } }
            .sheet(isPresented: $showNew) { NewThreadSheet() }
        }
    }
}

struct FishView: View {
    let thread: ThreadInfo
    let count: Int
    @State private var wander = false

    var body: some View {
        let remaining = thread.expiresAt.timeIntervalSinceNow
        VStack(spacing: 2) {
            Text("🐟").font(.system(size: 30 + CGFloat(min(count, 10)) * 5)).scaleEffect(x: -1)
            Text(thread.title).font(.caption2).lineLimit(1).frame(maxWidth: 90)
            Text("\(thread.category)・\(count)人").font(.system(size: 9)).opacity(0.7)
        }
        .padding(6)
        .background(categoryColor(thread.category).opacity(0.25), in: Capsule())
        .opacity(max(0.4, min(1, remaining / 180))) // 消滅が近いほど薄くなる
        .offset(x: wander ? 10 : -10, y: wander ? -6 : 6)
        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: wander)
        .onAppear { wander = true }
    }
}

struct NewThreadSheet: View {
    @EnvironmentObject var store: RoomStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var category = categories[0]

    var body: some View {
        NavigationStack {
            Form {
                TextField("話題（例：あの駅、もう見た？）", text: $title)
                Picker("カテゴリ", selection: $category) { ForEach(categories, id: \.self) { Text($0) } }
                Text("スレッドは15分で自動的に消えます。").font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("魚を放つ")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        store.createThread(title: String(title.prefix(40)), category: category); dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
