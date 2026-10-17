# AquaRoom 🐟

> **近距離 × 匿名 × その場限り** — ここにしかない一期一会な出会い

AquaRoom は、Bluetooth と Wi-Fi のローカルネットワークだけで、**約10m以内にいる人と匿名でチャットできる** iOS アプリです。インターネットもサーバーも不要です。

## 動機

さまざまなコミュニケーション手段がある一方で、身近にいるのに交流のない人と関わる手段はほとんどありません。特に日本では、電車や図書館など話しかけづらい場面が多いため、近距離かつ匿名で繋がれるツールとして AquaRoom を開発しました。

- コミュニティ単位での交流
- 身近な他人との関係構築
- 近距離 × 匿名 × その場限りのやり取り

## 主な機能

| 機能 | 内容 |
|---|---|
| ローカル通信 | Bluetooth と Wi-Fi のローカルネットワーク（範囲 約10m）。インターネット・サーバー不要 |
| 匿名チャット | 完全匿名。スレッドは **15分で自動削除** され、保存・時間延長の投票にも対応 |
| 水槽 UI | スレッドを「魚」として表示。カテゴリ / 参加人数 / 活発度を視覚的に表現 |
| 広告 | ユーザー自身が広告を配信でき、店・イベントなど身近な発見を増やせる |

## スクリーンショット

`screenshots/` に画像を置き、下記のコメントを外してください。

<!--
<p>
  <img src="screenshots/chat.png" width="200">
  <img src="screenshots/friends.png" width="200">
  <img src="screenshots/ad-detail.png" width="200">
  <img src="screenshots/sponsor-ads.png" width="200">
</p>
-->

## ユースケース

- **SNS 疲れを感じている若者**: いいねやフォローが無く、気楽に話せる場に
- **通勤・通学中のバスや電車内**: 公共の場でも気にせず話せる
- **旅行先での地元民との交流**: 話しかけづらい他人にも声をかけやすい
- **災害時の通信手段**: オフラインで使え、通信範囲が狭いため情報が錯綜しにくい

## 動作環境

- iOS 16 以上
- Xcode（最新の安定版推奨）
- 実機推奨（Bluetooth / ローカルネットワークはシミュレータでは動作しません）

## ビルド方法

```bash
git clone https://github.com/<your-name>/AquaRoom.git
cd AquaRoom
brew install xcodegen
xcodegen generate        # project.yml から AquaRoom.xcodeproj を生成
open AquaRoom.xcodeproj
```

1. Xcode で Signing & Capabilities の Team を自分のものに変更
2. **実機を2台以上** 接続して Run（同じアプリを両方に入れると、お互いの水槽に魚が現れます）

## Web版（ブラウザで動作）

`web/` に、インストール不要のWeb版があります。`cd web && node server.js` で起動できます（詳細は [web/README.md](web/README.md)）。
Web版はサーバー経由のため、「インターネット不要・約10m」というiOS版の特長は再現できません。

## ドキュメント

- [アーキテクチャ](docs/ARCHITECTURE.md)
- [公開手順（TestFlight / App Store）](docs/RELEASE_GUIDE.md)
- [プライバシーポリシー](docs/PRIVACY_POLICY.md)
- [ロードマップ](docs/ROADMAP.md)
- [コントリビュート](CONTRIBUTING.md)

## ロードマップ（抜粋）

- UI の改善
- 違法行為への対策（匿名環境下での安全な利用環境の構築）
- Android への展開

## ライセンス

[MIT License](LICENSE)
