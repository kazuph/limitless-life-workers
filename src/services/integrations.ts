export type IntegrationSuggestion = {
  id: string
  title: string
  description: string
  action: string
  target: string
}

export const getIntegrationSuggestions = (): IntegrationSuggestion[] => [
  {
    id: 'google-calendar',
    title: 'Google カレンダー',
    description: 'ミーティングや移動時間のライフログから、次の打ち合わせ候補を自動で登録します。',
    action: 'lifelog entry → カレンダーイベントを生成',
    target: 'https://calendar.google.com'
  },
  {
    id: 'gmail-reply',
    title: 'Gmail 返信ドラフト',
    description: '会話ログから抽出した要点を元に返信案と添付チェックリストを生成します。',
    action: 'lifelog transcript → Gmail draft API',
    target: 'https://mail.google.com'
  },
  {
    id: 'slack-reply',
    title: 'Slack スレッド返信',
    description: 'Slack での保留タスクや依頼を lifelog で検知し、自動ドラフトを Slack API に送ります。',
    action: 'lifelog highlight → Slack chat.postMessage',
    target: 'https://api.slack.com'
  },
  {
    id: 'github-pr',
    title: 'GitHub PR 作成',
    description: 'デイリーノート内の開発トピックをサマリー化して PR テンプレートに差し込みます。',
    action: 'lifelog action items → GitHub createPullRequest',
    target: 'https://github.com'
  },
  {
    id: 'obsidian-note',
    title: 'Obsidian ノート連携',
    description: 'Workers から Obsidian Vault の `03_文献ノート` に Markdown を push します。',
    action: 'lifelog summary → iCloud Obsidian sync',
    target: 'obsidian://open'
  },
  {
    id: 'zenn-post',
    title: 'Zenn 投稿種',
    description: '週次トピックと AI 考察をまとめて Zenn CLI 用の下書きを生成します。',
    action: 'lifelog analysis JSON → zenn-cli new:article',
    target: 'https://zenn.dev'
  }
]
