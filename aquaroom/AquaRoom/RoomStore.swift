import Foundation
import SwiftUI

/// スレッド・メッセージ・広告の状態管理。すべてメモリ上のみ（保存しない＝一期一会）。
final class RoomStore: ObservableObject {
    @Published var threads: [ThreadInfo] = []
    @Published var messages: [UUID: [Message]] = [:]
    @Published var votes: [UUID: Set<UUID>] = [:]
    @Published var ads: [Ad] = []
    @Published var peerCount = 0

    let myID = UUID()
    let myName = ["ウミガメ", "クラゲ", "イルカ", "ペンギン", "タコ", "ラッコ"].randomElement()! + String(Int.random(in: 100...999))
    static let lifetime: TimeInterval = 15 * 60

    private let mesh = MeshService()
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        mesh.onPacket = { [weak self] in self?.receive($0) }
        mesh.onPeersChanged = { [weak self] in self?.peerCount = $0 }
        mesh.onPeerJoined = { [weak self] in self?.sendSnapshot() }
        mesh.start()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    // MARK: 操作
    func createThread(title: String, category: String) {
        let now = Date()
        let t = ThreadInfo(id: UUID(), title: title, category: category, createdAt: now,
                           expiresAt: now.addingTimeInterval(Self.lifetime))
        apply(.thread(t)); mesh.send(.thread(t))
    }

    func post(_ text: String, in threadID: UUID) {
        let m = Message(id: UUID(), threadID: threadID, senderID: myID, senderName: myName,
                        text: String(text.prefix(500)), date: Date())
        apply(.message(m)); mesh.send(.message(m))
    }

    func voteExtend(_ threadID: UUID) {
        let p = Packet.vote(threadID: threadID, voterID: myID)
        apply(p); mesh.send(p)
    }

    func postAd(title: String, body: String) {
        let ad = Ad(id: UUID(), title: title, body: body, expiresAt: Date().addingTimeInterval(3600))
        apply(.ad(ad)); mesh.send(.ad(ad))
    }

    // MARK: 参照
    func participants(_ id: UUID) -> Set<UUID> {
        Set((messages[id] ?? []).map(\.senderID)).union(votes[id] ?? [])
    }
    func needVotes(_ id: UUID) -> Int { max(participants(id).count, 1) / 2 + 1 }
    func voteCount(_ id: UUID) -> Int { votes[id]?.count ?? 0 }

    // MARK: 内部
    private func receive(_ p: Packet) { apply(p) }

    private func apply(_ p: Packet) {
        switch p {
        case .thread(let t):
            if let i = threads.firstIndex(where: { $0.id == t.id }) {
                threads[i].expiresAt = max(threads[i].expiresAt, t.expiresAt)
            } else if t.expiresAt > Date() { threads.append(t) }
        case .message(let m):
            guard threads.contains(where: { $0.id == m.threadID }) else { return }
            var list = messages[m.threadID] ?? []
            if !list.contains(where: { $0.id == m.id }) {
                list.append(m); list.sort { $0.date < $1.date }
                messages[m.threadID] = list
            }
        case .vote(let tid, let voter):
            guard let i = threads.firstIndex(where: { $0.id == tid }) else { return }
            votes[tid, default: []].insert(voter)
            if voteCount(tid) >= needVotes(tid) {
                threads[i].expiresAt = threads[i].expiresAt.addingTimeInterval(Self.lifetime)
                votes[tid] = []
            }
        case .ad(let a):
            if !ads.contains(where: { $0.id == a.id }), a.expiresAt > Date() { ads.append(a) }
        case .sync(let ts, let ms, let as_):
            ts.forEach { apply(.thread($0)) }
            ms.forEach { apply(.message($0)) }
            as_.forEach { apply(.ad($0)) }
        }
    }

    private func sendSnapshot() {
        mesh.send(.sync(threads: threads, messages: messages.values.flatMap { $0 }, ads: ads))
    }

    private func tick() {
        let now = Date()
        threads.removeAll { $0.expiresAt < now }
        let alive = Set(threads.map(\.id))
        messages = messages.filter { alive.contains($0.key) }
        votes = votes.filter { alive.contains($0.key) }
        ads.removeAll { $0.expiresAt < now }
        objectWillChange.send() // カウントダウン表示の更新
    }
}
