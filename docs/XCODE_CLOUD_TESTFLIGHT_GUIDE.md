# Windows だけで Xcode Cloud → TestFlight → iPhone で動かす手順

このリポジトリ（スケジュール15）を、Mac を持たずに **Xcode Cloud でアーカイブ → TestFlight で iPhone にインストール** するまでの手順です。
ブラウザ（App Store Connect / Apple Developer / GitHub）と iPhone だけで進められるように書いています。

> 画面の名前は Apple が予告なく変えることがあります。見つからない場合は似た名前のボタンを探してください。

---

## 全体の流れ

```
[Windows] コードを編集して GitHub に push
      ↓（自動）
[Xcode Cloud] ビルド → アーカイブ → 署名 → App Store Connect にアップロード
      ↓（自動）
[TestFlight] 内部テスターに配信
      ↓
[iPhone] TestFlight アプリからインストール・更新
```

| 必要なもの | 状態 |
| --- | --- |
| Apple Developer Program | 登録済み |
| GitHub リポジトリ `iwatch-pomi/15minits_schedule` | このリポジトリ |
| iPhone（iOS 17 以上）と TestFlight アプリ | App Store から無料で入手 |
| Mac | **原則不要**（ただし ⚠ ステップ 5 の注意を参照） |

---

## ステップ 1. Team ID を調べる

1. <https://developer.apple.com/account> にサインイン
2. 「メンバーシップの詳細（Membership details）」を開く
3. **チーム ID（Team ID）**（英数字 10 文字、例 `AB12CD34EF`）をメモする

## ステップ 2. Bundle ID を決めて登録する

Bundle ID はアプリの世界で一意な ID です。逆ドメイン形式で付けます（例：`com.あなたの名前.schedule15`）。
このリポジトリには仮で `com.iwatch.schedule15` が入っています。

1. <https://developer.apple.com/account/resources/identifiers/list> を開く
2. 「＋」→「App IDs」→「App」→ 続ける
3. Description：`Schedule15`、Bundle ID：「Explicit」を選んで決めた ID（例 `com.iwatch.schedule15`）を入力
4. Capabilities は何もチェックせず「Continue」→「Register」

> 既に他人が使っている ID は登録できません。その場合は末尾を変えてください。

## ステップ 3. プロジェクトに Team ID と Bundle ID を書き込む（GitHub の Web 上で OK）

1. GitHub で `Schedule15.xcodeproj/project.pbxproj` を開き、右上の鉛筆アイコン（Edit）をクリック
2. 次の 2 種類の行を **それぞれ 2 か所（Debug / Release）** 書き換える

   ```
   DEVELOPMENT_TEAM = "";                         →  DEVELOPMENT_TEAM = AB12CD34EF;
   PRODUCT_BUNDLE_IDENTIFIER = com.iwatch.schedule15;  →  （ステップ2で登録したID。同じなら変更不要）
   ```

   `Ctrl + F` で `DEVELOPMENT_TEAM` を検索すると見つけやすいです。
3. 「Commit changes」でコミット

> Claude に「Team ID は AB12CD34EF、Bundle ID は ○○ に変えて」と頼んでも書き換えられます。

## ステップ 4. App Store Connect にアプリを作る

1. <https://appstoreconnect.apple.com> →「アプリ」→ 左上の「＋」→「新規アプリ」
2. 入力内容
   - プラットフォーム：**iOS**
   - 名前：例「スケジュール15」（App Store 全体で一意。使われていたら「スケジュール15 - 15分管理」などに）
   - プライマリ言語：日本語
   - バンドル ID：ステップ 2 で登録したものを選択
   - SKU：自分用の管理番号（例 `schedule15-001`）
   - ユーザアクセス：フルアクセス
3. 「作成」

## ステップ 5. Xcode Cloud を開始し GitHub と連携する

### ⚠ 重要な注意：最初の 1 回だけ Mac が必要な場合がある

Apple の公式ドキュメントでは、Xcode Cloud の **初回セットアップ（Get Started / 最初のワークフロー作成）は Xcode で行う** ことになっていて、
**最初のビルドが終わった後は** ワークフローの作成・編集・ビルド開始・結果確認がすべて App Store Connect（ブラウザ）でできる、と説明されています。

そのため、次の順で試してください。

**A. まずブラウザで試す**

1. App Store Connect → 作ったアプリ → 上部タブの **「Xcode Cloud」**
2. 「はじめる（Get Started）」や「ワークフローを管理」が表示されれば、そのまま
   - リポジトリの接続 →「GitHub」→ GitHub の画面で **Xcode Cloud（Apple）の GitHub App** に `iwatch-pomi/15minits_schedule` へのアクセスを許可
   - プロジェクト：`Schedule15.xcodeproj`、スキーム：`Schedule15`
   と進めてステップ 6 へ。

**B. ブラウザで初回セットアップができない場合（Mac を一度だけ借りる）**

初回の Get Started だけ Mac が必要です。以下のどれかで 1 回だけ作業し、以後は Windows だけで運用できます。

- 友人・学校・研究室の Mac を 30 分借りる
- 時間課金のクラウド Mac（MacinCloud、AWS EC2 Mac など）を使う

Mac での作業内容（15〜30 分）：

1. Xcode（App Store から無料）をインストールし、Apple ID（開発者アカウント）でサインイン（Xcode → Settings → Accounts）
2. ターミナルで `git clone https://github.com/iwatch-pomi/15minits_schedule.git` し、`Schedule15.xcodeproj` を開く
3. 左のナビゲータで「Report Navigator（⌘9）」→「Cloud」タブ →「Get Started」
4. 製品に `Schedule15` を選び、ワークフローは既定のまま、Grant Access で GitHub 連携
5. 最初のビルドが始まったら Mac での作業は終了（以後はブラウザで管理）

## ステップ 6. TestFlight に配信するワークフローを作る

App Store Connect → アプリ →「Xcode Cloud」→「ワークフローを管理（Manage Workflows）」→「＋」（または既定ワークフローを編集）

| 項目 | 設定値 |
| --- | --- |
| 名前 | `TestFlight 配信` など |
| 環境（Environment） | Xcode：最新リリース（Latest Release）、macOS：最新 |
| 開始条件（Start Conditions） | 「ブランチの変更（Branch Changes）」→ 開発に使うブランチ（例 `main`）。「自動キャンセル」はオン推奨 |
| アクション（Actions） | 「＋」→ **アーカイブ（Archive）** → プラットフォーム **iOS**、スキーム **Schedule15** |
| 配信の準備（Distribution Preparation） | **TestFlight（内部テストのみ）** ※外部テスターにも配るなら「TestFlight と App Store」 |
| ポストアクション（Post-Actions） | 「＋」→ **TestFlight 内部テスト（TestFlight Internal Testing）** → 配信先グループを選択（ステップ 7 で作るグループ） |

保存したら「ビルドを開始（Start Build）」で手動実行できます。以後は開始条件のブランチに push するたびに自動でビルドされます。

> Claude が作業するブランチ（`claude/...`）で直接ビルドしたい場合は、開始条件のブランチにそのブランチ名を追加するか、
> GitHub 上でプルリクエストを作って `main` にマージしてください。

### ビルド番号について
Xcode Cloud は毎回ビルド番号を自動で増やすので、`CURRENT_PROJECT_VERSION` を手で変える必要はありません。
アプリのバージョン（1.0 など）を上げたいときは `project.pbxproj` の `MARKETING_VERSION` を変更します。

## ステップ 7. TestFlight の内部テスターを設定する

1. App Store Connect →「ユーザとアクセス」で、テストに使う Apple ID がチームメンバーになっていることを確認（自分自身なら OK）
2. アプリ →「TestFlight」タブ → 左の「内部テスト」の「＋」→ グループ名（例「自分」）を作成
3. グループにテスター（自分の Apple ID）を追加
4. ステップ 6 のポストアクションでこのグループを選ぶ

## ステップ 8. iPhone にインストールする

1. iPhone に **TestFlight** アプリ（App Store で無料）をインストールし、開発者アカウントと同じ Apple ID でサインイン
2. ビルドが完了すると（目安 10〜20 分）、メールまたは TestFlight アプリに招待が届く
3. TestFlight アプリで「スケジュール15」→「インストール」
4. 設定 →「データ」→「今日のサンプルタスクを追加」で画面の動作をすぐ確認できます

以後は push するたびに新しいビルドが TestFlight に届き、「アップデート」で更新できます。
（TestFlight のビルドは 90 日で期限切れになります。）

---

## 開発サイクル（Windows のみ）

1. Claude（またはエディタ）でコードを修正し、GitHub に push
2. Xcode Cloud が自動でビルド → App Store Connect →「Xcode Cloud」→「ビルド」で進行状況を確認
3. 失敗したら、ビルドの詳細 →「ログ」または「Issues」のエラーメッセージをコピーして Claude に貼り付ける → 修正して再 push
4. 成功したら iPhone の TestFlight で更新

> **無料枠**：Apple Developer Program には Xcode Cloud の計算時間が **月 25 時間** 含まれます。
> このアプリの 1 回のアーカイブは数分〜10 分程度なので、通常は十分です。

---

## よくあるエラーと対処

| 症状 | 原因と対処 |
| --- | --- |
| スキームが見つからない / `Schedule15` が選べない | 共有スキーム `Schedule15.xcodeproj/xcshareddata/xcschemes/Schedule15.xcscheme` が必要（このリポジトリには入っています）。消していないか確認 |
| `Signing for "Schedule15" requires a development team` | ステップ 3 の `DEVELOPMENT_TEAM` が空のまま。Team ID を入れて push |
| `No profiles for 'com.xxx' were found` / Bundle ID 不一致 | `PRODUCT_BUNDLE_IDENTIFIER` と、ステップ 2・4 で登録した Bundle ID が一致しているか確認 |
| `Missing required icon file` | `Schedule15/Assets.xcassets/AppIcon.appiconset/AppIcon.png`（1024×1024・透過なし）が必要。差し替える場合も同じ条件で |
| TestFlight で「輸出コンプライアンス情報がありません」 | `Config/Info.plist` の `ITSAppUsesNonExemptEncryption = NO` で自動回答済み。消していないか確認 |
| ビルドは成功したのに TestFlight に出ない | 処理中（Processing）に 5〜30 分かかることがあります。ポストアクションで内部テストグループを選んでいるかも確認 |
| Swift のコンパイルエラー | ログのエラー行（ファイル名・行番号・メッセージ）を Claude に貼り付けて修正を依頼 |

---

## プロジェクト構成メモ（編集する人向け）

- `Schedule15/` フォルダは Xcode 16 の「フォルダ同期」方式です。**このフォルダに `.swift` ファイルを追加するだけで自動的にビルド対象になります**（`project.pbxproj` の編集は不要）。
- 最低対応 iOS：17.0（SwiftData・Swift Charts を使用）
- 署名：Automatic（Xcode Cloud が証明書とプロファイルを自動管理）

## 参考リンク

- [Get started with Xcode Cloud（Apple）](https://developer.apple.com/xcode-cloud/get-started/)
- [Configuring your first Xcode Cloud workflow（Apple）](https://developer.apple.com/documentation/Xcode/Configuring-Your-First-Xcode-Cloud-Workflow)
- [App Store Connect ヘルプ](https://developer.apple.com/help/app-store-connect/)
