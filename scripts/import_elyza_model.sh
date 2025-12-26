#!/bin/bash
# Llama-3-ELYZA-JP-8B モデルをOllamaにインポートするスクリプト

set -e

echo "=========================================="
echo "ELYZA Llama-3-JP-8B Ollama インポート"
echo "=========================================="

# 必要なツールの確認
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 が必要です"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Error: git が必要です"; exit 1; }

# 作業ディレクトリ作成
WORK_DIR="${HOME}/.ollama/models/elyza-llama3-jp-8b"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo ""
echo "ステップ1: Hugging Face Hub のインストール"
pip3 install -q huggingface-hub

echo ""
echo "ステップ2: GGUF形式のモデルをダウンロード"
echo "注意: 約4.9GB のダウンロードが必要です"

# 公式GGUF形式のモデル
GGUF_REPO="elyza/Llama-3-ELYZA-JP-8B-GGUF"
GGUF_FILE="Llama-3-ELYZA-JP-8B-q4_k_m.gguf"

echo "リポジトリ: $GGUF_REPO"
echo "ファイル: $GGUF_FILE (Q4_K_M 量子化版)"

export GGUF_REPO GGUF_FILE

python3 << 'PYTHON_SCRIPT'
from huggingface_hub import hf_hub_download
import os

repo_id = os.environ.get('GGUF_REPO', 'elyza/Llama-3-ELYZA-JP-8B-GGUF')
filename = os.environ.get('GGUF_FILE', 'Llama-3-ELYZA-JP-8B-q4_k_m.gguf')

try:
    print(f"ダウンロード開始: {repo_id}/{filename}")
    model_path = hf_hub_download(
        repo_id=repo_id,
        filename=filename,
        cache_dir=os.getcwd()
    )
    print(f"ダウンロード完了: {model_path}")

    # シンボリックリンクを作成
    import shutil
    target = os.path.join(os.getcwd(), filename)
    if os.path.exists(target):
        os.remove(target)
    shutil.copy(model_path, target)
    print(f"モデルファイル準備完了: {target}")

except Exception as e:
    print(f"エラー: {e}")
    print("\n代替方法:")
    print("1. https://huggingface.co/mmnga/Llama-3-ELYZA-JP-8B-gguf にアクセス")
    print("2. GGUF ファイル（q4_k_m 推奨）をダウンロード")
    print(f"3. {os.getcwd()} に配置")
    exit(1)
PYTHON_SCRIPT

echo ""
echo "ステップ3: Modelfile を作成"

cat > Modelfile << 'MODELFILE'
FROM ./Llama-3-ELYZA-JP-8B-q4_k_m.gguf

TEMPLATE """{{ if .System }}<|begin_of_text|><|start_header_id|>system<|end_header_id|>

{{ .System }}<|eot_id|>{{ end }}{{ if .Prompt }}<|start_header_id|>user<|end_header_id|>

{{ .Prompt }}<|eot_id|>{{ end }}<|start_header_id|>assistant<|end_header_id|>

{{ .Response }}<|eot_id|>"""

SYSTEM """あなたは誠実で優秀な日本人のアシスタントです。特に指示が無い場合は、常に日本語で回答してください。"""

PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER num_ctx 4096
PARAMETER stop "<|eot_id|>"
PARAMETER stop "<|end_of_text|>"
MODELFILE

echo "Modelfile 作成完了"

echo ""
echo "ステップ4: Ollama にモデルをインポート"

if command -v ollama >/dev/null 2>&1; then
    ollama create elyza-jp-8b -f Modelfile
    echo ""
    echo "=========================================="
    echo "✅ インポート完了！"
    echo "=========================================="
    echo ""
    echo "使用方法:"
    echo "  ollama run elyza-jp-8b"
    echo ""
    echo "または、Webインターフェースで 'elyza-jp-8b' を選択"
else
    echo "警告: ollama コマンドが見つかりません"
    echo "Dockerコンテナ内で実行する場合:"
    echo "  docker exec -it ollama-local-llm bash"
    echo "  cd $WORK_DIR"
    echo "  ollama create elyza-jp-8b -f Modelfile"
fi

echo ""
echo "モデルファイルの場所: $WORK_DIR"
