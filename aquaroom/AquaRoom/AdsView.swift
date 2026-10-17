import SwiftUI

struct AdsView: View {
    @EnvironmentObject var store: RoomStore
    @State private var showNew = false

    var body: some View {
        NavigationStack {
            List {
                if store.ads.isEmpty { Text("近くに広告はありません").foregroundStyle(.secondary) }
                ForEach(store.ads) { ad in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ad.title).font(.headline)
                        Text(ad.body).font(.subheadline)
                        Text("掲載終了まで あと\(max(0, Int(ad.expiresAt.timeIntervalSinceNow / 60)))分")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("スポンサー広告")
            .toolbar { Button { showNew = true } label: { Image(systemName: "plus.circle.fill") } }
            .sheet(isPresented: $showNew) { NewAdSheet() }
        }
    }
}

struct NewAdSheet: View {
    @EnvironmentObject var store: RoomStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var body_ = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("タイトル（例：カフェオープン！）", text: $title)
                TextField("内容", text: $body_, axis: .vertical).lineLimit(3...6)
                Text("広告は1時間、近くの端末に表示されます。").font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("広告を配信")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("配信") { store.postAd(title: String(title.prefix(40)), body: String(body_.prefix(200))); dismiss() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }
}
