import Foundation

struct ThreadInfo: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var category: String
    let createdAt: Date
    var expiresAt: Date
}

struct Message: Codable, Identifiable, Hashable {
    let id: UUID
    let threadID: UUID
    let senderID: UUID
    let senderName: String
    let text: String
    let date: Date
}

struct Ad: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let body: String
    let expiresAt: Date
}

enum Packet: Codable {
    case thread(ThreadInfo)
    case message(Message)
    case vote(threadID: UUID, voterID: UUID)
    case ad(Ad)
    case sync(threads: [ThreadInfo], messages: [Message], ads: [Ad])
}

let categories = ["雑談", "グルメ", "イベント", "相談"]
