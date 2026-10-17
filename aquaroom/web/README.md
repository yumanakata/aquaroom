# AquaRoom Web版

ブラウザで動く AquaRoom。インストール不要で、iPhone / Android / PC のどれでも使えます。

## 起動

```bash
cd web
node server.js        # Node 18 以上。npm install は不要
# → http://localhost:3000
```

同じ Wi-Fi の別端末から試すときは `http://<PCのIP>:3000`（位置情報は https か localhost でのみ使えるため、その場合は「合言葉」で入ってください）。

## 公開（デプロイ）

Node が動くサービスならどこでも動きます（例: Render / Fly.io / Railway）。

- Render の場合: New → Web Service → このリポジトリを選択
  - Root Directory: `web` / Build Command: （空） / Start Command: `node server.js`
- 位置情報を使うには **https** が必須です（上記サービスは自動で https になります）。

## 仕組み

- 受信: Server-Sent Events（`GET /events`）、送信: `POST /send`
- 「近く」= ブラウザが位置情報を約100m単位に丸めたエリア、または合言葉。同じエリアの人だけが同じ水槽を共有
- スレッドは15分で削除、過半数の投票で+15分。データはサーバーのメモリのみ（再起動で全消去）

## iOS版との違い

| | iOS版 | Web版 |
|---|---|---|
| 通信 | Bluetooth / Wi-Fi 直接（サーバー不要） | **サーバー経由（インターネット必要）** |
| 範囲 | 約10m | 約100m単位の区画 or 合言葉 |
| 災害時のオフライン利用 | 可 | 不可 |
| 距離の厳密さ | 物理的に近い人だけ | 位置情報の自己申告（偽装可能） |

## 既知の制限
- 通報・ブロック・不適切投稿の対策は未実装
- 区画の境界付近では、隣り合う人が別の水槽になることがある
- 送信者IDはクライアントの自己申告（なりすまし対策なし）
