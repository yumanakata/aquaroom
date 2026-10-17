# 公開手順（iOS）

## 重要: GitHub だけでは iOS アプリは配布できません

GitHub は **ソースコードの公開・管理** の場所です。iPhone ユーザーへの配布は以下のいずれかが必要です。

| 方法 | 費用 | 対象 |
|---|---|---|
| **TestFlight** | Apple Developer Program（年額 $99） | 最大10,000人のテスター |
| **App Store** | 同上 | 一般公開 |
| ソースを公開して各自ビルド | 無料 | 開発者向け（無料署名は7日で失効） |

## App Store 公開の流れ

1. [Apple Developer Program](https://developer.apple.com/programs/) に登録
2. App Store Connect でアプリを新規作成（Bundle ID を設定）
3. Xcode: Product → Archive → Distribute App → App Store Connect
4. TestFlight で動作確認
5. 以下を用意して審査に提出
   - スクリーンショット（必須サイズ）
   - 説明文・キーワード・カテゴリ
   - **プライバシーポリシーの URL**（下記 GitHub Pages で用意可）
   - プライバシー栄養ラベルの回答
   - 年齢レーティング回答

## 審査で特に注意すること（匿名チャット）

匿名の UGC（ユーザー生成コンテンツ）アプリは、App Store 審査ガイドライン 1.2 に基づき、一般に次が求められます。

- 不適切なコンテンツのフィルタリング
- **通報機能**
- **ユーザーのブロック機能**
- 運営者の連絡先

→ ロードマップの「違法行為への対策」を、公開前に最低限実装することを強く推奨します。

## プライバシーポリシーを GitHub Pages で公開

1. リポジトリの Settings → Pages
2. Source: `Deploy from a branch` / Branch: `main` / Folder: `/docs`
3. `https://<your-name>.github.io/AquaRoom/PRIVACY_POLICY` が URL になります

## GitHub Releases

ソースのバージョンを残す用途で使います。

```bash
git tag v1.0.0
git push origin v1.0.0
```
