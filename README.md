# スケジュール15

**15分で、もっと前に進む。** — 15分単位でスケジュールを管理できる、シンプルな iPhone 向け ToDo・カレンダーアプリです。

## 機能

| 画面 | 内容 |
| --- | --- |
| ホーム | 週の切り替え（月〜日）と、15分刻みのタイムライン。空いている枠をタップするとその時刻でタスクを作成 |
| タスク | すべて / 今日 / 未完了 / 完了 のフィルタ、チェックで完了、スワイプで削除 |
| カレンダー | 月表示（予定の量をドットで表示）と、選んだ日のタスク一覧 |
| 新規タスク | タイトル、日付、開始・終了時刻（15分単位）、所要時間のワンタップ指定、カテゴリ、アイコン、メモ |
| 時間の使い方 | ホーム左上のグラフボタンから。総作業時間、完了率、カテゴリ別の時間、時間帯ごとの分布グラフ |
| 設定 | 表示設定（タイムラインの時間帯）、タスクの初期設定、テーマ（ライト / ダーク / 端末に合わせる）、サンプルデータ追加 |

カテゴリ：勉強・作業 / 実験・研究 / ミーティング / 移動 / その他

## 技術構成

- SwiftUI / SwiftData / Swift Charts（外部ライブラリなし）
- iOS 17.0 以上、iPhone 専用（縦向き）
- Xcode 16 以降のプロジェクト形式（`Schedule15/` フォルダ内のファイルは自動でビルド対象）

```
Schedule15.xcodeproj/        Xcode プロジェクト（共有スキーム入り）
Config/Info.plist            輸出コンプライアンス設定など
Schedule15/
  Schedule15App.swift        エントリポイント
  Models/                    TaskItem（SwiftData）, TaskCategory
  Utilities/                 15分計算・日付表示・設定キー・サンプルデータ
  Views/                     Home / Tasks / Calendar / Editor / Stats / Settings / Components
  Assets.xcassets/           アプリアイコン・アクセントカラー
docs/XCODE_CLOUD_TESTFLIGHT_GUIDE.md   Windows だけで TestFlight まで行く手順
```

## ビルド・配信（Mac なし）

Xcode Cloud でアーカイブし、TestFlight で iPhone にインストールします。
詳しい手順は **[docs/XCODE_CLOUD_TESTFLIGHT_GUIDE.md](docs/XCODE_CLOUD_TESTFLIGHT_GUIDE.md)** を参照してください。

最初に必要な変更（GitHub の Web 上で編集可）：

- `Schedule15.xcodeproj/project.pbxproj` の `DEVELOPMENT_TEAM = "";` に自分の Team ID を入れる（2 か所）
- 必要なら `PRODUCT_BUNDLE_IDENTIFIER = com.iwatch.schedule15;` を自分の Bundle ID に変える（2 か所）
