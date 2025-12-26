#!/bin/bash
set -e

echo "Ollamaサーバーを起動中..."

# Ollamaサーバーをバックグラウンドで起動
ollama serve &

# Ollamaサーバーが起動するまで待機
echo "Ollamaサーバーの起動を待機中..."
for i in {1..30}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "Ollamaサーバーが起動しました"
        break
    fi
    echo "待機中... ($i/30)"
    sleep 1
done

# モデルが存在するか確認し、なければダウンロード
echo "モデルの確認中..."

# ダウンロードするモデルのリスト（軽量モデルを中心に）
MODELS=(
    "gemma2:2b"      # Google Gemma 2B - 軽量で高性能
    "llama3.2:3b"    # Meta Llama 3.2 3B - 汎用性が高い
    "qwen2.5:3b"     # Qwen 2.5 3B - 多言語・日本語に強い
    "elyza:jp8b"     # ELYZA 8B - 日本語特化モデル
)

# 環境変数で追加モデルを指定可能
# 例: EXTRA_MODELS="codellama:7b mistral:7b"
if [ -n "$EXTRA_MODELS" ]; then
    IFS=' ' read -ra EXTRA <<< "$EXTRA_MODELS"
    MODELS+=("${EXTRA[@]}")
fi

# 各モデルをチェックしてダウンロード
for model in "${MODELS[@]}"; do
    if ! ollama list | grep -q "$model"; then
        echo "📥 ${model}モデルをダウンロード中..."
        ollama pull "$model"
    else
        echo "✓ ${model}モデルは既に存在します"
    fi
done

echo "利用可能なモデル:"
ollama list

echo "Flaskアプリケーションを起動中..."
cd /app
exec python3 app.py
