#!/bin/bash
# Ollamaを使ったローカルLLMのcurlサンプルスクリプト

echo "=== OllamaローカルLLM curlサンプル ==="
echo ""

# API URLの設定
API_URL="http://localhost:11434/api"

# 1. シンプルな質問例（ストリーミングなし）
echo "1. シンプルな質問例"
echo "質問: 日本の首都は？"
echo "回答:"
curl -s "${API_URL}/generate" -d '{
  "model": "gemma2:2b",
  "prompt": "日本の首都は？簡潔に答えてください。",
  "stream": false
}' | jq -r '.response'
echo ""
echo ""

# 2. チャット形式の例
echo "2. チャット形式の例"
echo "質問: Pythonとは何ですか？"
echo "回答:"
curl -s "${API_URL}/chat" -d '{
  "model": "gemma2:2b",
  "messages": [
    {
      "role": "user",
      "content": "Pythonとは何ですか？簡潔に説明してください。"
    }
  ],
  "stream": false
}' | jq -r '.message.content'
echo ""
echo ""

# 3. インストール済みモデルの一覧
echo "3. インストール済みモデル一覧"
curl -s "${API_URL}/tags" | jq -r '.models[] | "  - \(.name) (サイズ: \(.size / 1024 / 1024 / 1024 | round)GB)"'
echo ""
echo ""

# 4. ストリーミング例（オプション）
echo "4. ストリーミングレスポンス例"
echo "質問: AIとは何ですか？"
echo "回答:"
curl -s "${API_URL}/generate" -d '{
  "model": "gemma2:2b",
  "prompt": "AIとは何ですか？1行で答えてください。",
  "stream": true
}' | while IFS= read -r line; do
  echo "$line" | jq -r '.response // empty' | tr -d '\n'
done
echo ""
echo ""

echo "すべてのサンプルが完了しました！"
