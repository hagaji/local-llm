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
if ! ollama list | grep -q "gemma2:2b"; then
    echo "gemma2:2bモデルをダウンロード中..."
    ollama pull gemma2:2b
else
    echo "gemma2:2bモデルは既に存在します"
fi

echo "Flaskアプリケーションを起動中..."
cd /app
exec python3 app.py
