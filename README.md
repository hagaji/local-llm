# ローカルLLM環境セットアップ完了

Ollamaを使用したローカルLLM環境が構築されました。

## インストール済み

- **Ollama**: v0.13.5
- **モデル**: Gemma 2B（軽量で高性能な日本語対応モデル）
- **Webインターフェース**: Flask + HTML/CSS/JavaScript
- **Docker対応**: docker-compose.ymlで簡単起動

## 使い方

### 🌐 Webインターフェース（推奨）

#### ローカル環境で起動

```bash
# 依存関係をインストール
pip3 install -r requirements.txt

# Webアプリを起動
python3 app.py
```

その後、ブラウザで http://localhost:8080 を開いてください。

#### Dockerで起動

```bash
# Docker Composeで起動
docker-compose up -d

# ログを確認
docker-compose logs -f

# 停止
docker-compose down
```

その後、ブラウザで http://localhost:8080 を開いてください。

**初回起動時の注意:**
- Dockerコンテナ内でgemma2:2bモデルをダウンロードするため、初回は5-10分かかります
- モデルデータは永続化されるため、2回目以降はすぐに起動します

### 💻 コマンドライン

#### 1. コマンドラインから直接使う

```bash
ollama run gemma2:2b
```

終了するには `/bye` と入力してください。

#### 2. REST API経由で使う

Ollamaは `http://localhost:11434` でREST APIサーバーとして動作しています。

**curlでテスト:**
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "gemma2:2b",
  "prompt": "日本の首都は？",
  "stream": false
}'
```

#### 3. Pythonから使う

まず、Ollama Pythonライブラリをインストール：
```bash
pip install ollama
```

サンプルコード：
```python
import ollama

response = ollama.chat(model='gemma2:2b', messages=[
  {
    'role': 'user',
    'content': '日本の首都は？',
  },
])
print(response['message']['content'])
```

## 利用可能なコマンド

- `ollama list` - インストール済みモデル一覧
- `ollama pull <model>` - 新しいモデルをダウンロード
- `ollama rm <model>` - モデルを削除
- `ollama serve` - APIサーバーを手動で起動（既に自動起動中）
- `brew services stop ollama` - Ollamaサービスを停止

## 利用可能なモデル

### デフォルトでインストールされるモデル

Docker起動時に自動的にダウンロードされます：

- **gemma2:2b** (約1.6GB) - 軽量、高速、汎用性が高い
- **llama3.2:3b** (約2GB) - Meta製、汎用性に優れる
- **qwen2.5:3b** (約2.2GB) - 多言語・日本語対応が強い

### 追加で試せるモデル

#### 軽量モデル（8GB RAM以下）
```bash
ollama pull llama3.2:1b        # 超軽量（700MB）
ollama pull phi3:mini          # Microsoft製（2.3GB）
```

#### 中規模モデル（16GB RAM推奨）
```bash
ollama pull qwen2.5:7b         # 日本語に強い（4.7GB）
ollama pull mistral:7b         # 高性能（4.1GB）
ollama pull codellama:7b       # コード生成特化（3.8GB）
```

### モデルの管理

```bash
# インストール済みモデル一覧
ollama list

# 新しいモデルをダウンロード
ollama pull <model-name>

# モデルを削除
ollama rm <model-name>

# モデルの詳細情報
ollama show <model-name>
```

### 追加モデルをDocker起動時にダウンロード

`docker-compose.yml`の環境変数を編集：
```yaml
environment:
  - EXTRA_MODELS=codellama:7b mistral:7b
```

その後、コンテナを再起動：
```bash
docker-compose down
docker-compose up -d
```

## サービス管理

```bash
# サービスを起動
brew services start ollama

# サービスを停止
brew services stop ollama

# サービスの状態を確認
brew services list | grep ollama
```

## プロジェクト構成

```
local-llm/
├── app.py                    # Flaskバックエンドサーバー
├── static/
│   ├── index.html           # Webインターフェース
│   ├── style.css            # スタイルシート
│   └── script.js            # フロントエンドロジック
├── docker-compose.yml       # Docker Compose設定
├── Dockerfile               # Dockerイメージ定義
├── docker-entrypoint.sh     # コンテナ起動スクリプト
├── requirements.txt         # Python依存関係
├── test_ollama.py          # Pythonサンプル
├── test_ollama.sh          # curlサンプル
└── README.md               # このファイル
```

## 機能

### Webインターフェース
- ✅ リアルタイムチャット
- ✅ ストリーミングレスポンス対応
- ✅ チャット履歴管理
- ✅ モデル切り替え機能
- ✅ レスポンシブデザイン

### API エンドポイント
- `GET /` - Webインターフェース
- `GET /api/models` - 利用可能なモデル一覧
- `POST /api/chat` - 通常チャット
- `POST /api/chat/stream` - ストリーミングチャット
- `GET /health` - ヘルスチェック

## パフォーマンス最適化

### GPU活用について

**macOS (Apple Silicon)の場合:**
- Docker Desktop for Macは直接GPU（Metal）アクセスに対応していません
- 最高のパフォーマンスを得るには、**Dockerを使わずネイティブで実行**することを推奨します

**ネイティブ実行（推奨）:**
```bash
# Homebrewでインストール済みの場合
brew services start ollama

# Webアプリをローカルで起動
python3 app.py
```
この方法なら、M2チップのGPU（Metal）が自動的に活用されます。

**Docker使用時の最適化:**
現在のdocker-compose.ymlには以下の最適化設定が含まれています：
- `OLLAMA_NUM_PARALLEL=4` - 並列リクエスト処理数
- `OLLAMA_FLASH_ATTENTION=true` - Flash Attention有効化（高速化）
- `OLLAMA_MAX_LOADED_MODELS=1` - メモリ効率化
- CPUリソース上限設定（4コア）

### パフォーマンスモニタリング

応答速度の確認：
```bash
# ヘルスチェック
curl http://localhost:8080/health

# Ollama統計情報（モデルがロード中の場合）
curl http://localhost:11434/api/ps
```

### Linux (NVIDIA GPU)の場合

NVIDIA GPU環境では、docker-compose.ymlに以下を追加：
```yaml
services:
  ollama-web:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
```

## トラブルシューティング

### Dockerでモデルのダウンロードが遅い
初回起動時はモデル（約1.6GB）をダウンロードするため時間がかかります。
ログで進捗を確認できます：
```bash
docker-compose logs -f
```

### ポート競合
デフォルトではポート8080を使用します。変更する場合：
```bash
# 環境変数で指定
PORT=9000 python3 app.py

# docker-compose.ymlを編集
ports:
  - "9000:8080"
```

### Ollamaに接続できない
Ollamaサービスが起動しているか確認：
```bash
brew services list | grep ollama
curl http://localhost:11434/api/tags
```

## サンプルスクリプト

このディレクトリにサンプルスクリプトを作成しました：
- [test_ollama.py](test_ollama.py) - Pythonから使用する例
- [test_ollama.sh](test_ollama.sh) - curlから使用する例

## 次のステップ

1. 他のモデルを試す：`ollama pull llama3.2:3b`
2. カスタムモデルを作成（Modelfile使用）
3. 複数モデルの切り替え
4. APIを使った独自アプリケーション開発
