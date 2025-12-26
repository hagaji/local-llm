# Ollamaベースイメージを使用
FROM ollama/ollama:latest

# 必要なパッケージをインストール
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリを設定
WORKDIR /app

# Pythonの依存関係をコピーしてインストール
COPY requirements.txt .
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# アプリケーションファイルをコピー
COPY app.py .
COPY static ./static

# Ollamaモデルを事前にダウンロードするためのスクリプト
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# ポートを公開
EXPOSE 8080 11434

# エントリポイント設定
ENTRYPOINT ["/docker-entrypoint.sh"]
