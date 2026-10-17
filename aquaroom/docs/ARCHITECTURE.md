# アーキテクチャ

- iOS 16+ / Swift / SwiftUI
- 通信: **MultipeerConnectivity**（Bluetooth + Wi-Fi、約10m、サーバー不要、暗号化 required）
- プロジェクト生成: XcodeGen（`project.yml`）

| ファイル | 役割 |
|---|---|
| `MeshService.swift` | 近くの端末の探索・接続・パケット送受信 |
| `RoomStore.swift` | スレッド/メッセージ/投票/広告の状態管理、15分での自動削除、参加時の同期 |
| `Models.swift` | `ThreadInfo` `Message` `Ad` `Packet`（JSON） |
| `AquariumView.swift` | 水槽UI。スレッド=魚（大きさ=参加人数、色=カテゴリ、消滅間近は薄く） |
| `ThreadView.swift` | チャット、消滅カウントダウン、延長投票 |
| `AdsView.swift` | ユーザー広告（1時間掲載） |

## 仕様
- データは**メモリ上のみ**。アプリを閉じる/15分経過で消える
- 匿名: 起動ごとにランダムな名前とIDを生成
- 延長: 参加者の過半数が投票すると +15分
- 新しい端末が接続すると、既存のスレッド・メッセージ・広告を同期

## 既知の制限
- 実機での検証が必須（シミュレータでは近距離通信が動かない）
- 通報・ブロック・不適切投稿フィルタは未実装（公開前に必須）
- メッシュ中継なし: 直接接続できる範囲のみ
