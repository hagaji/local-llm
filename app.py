#!/usr/bin/env python3
"""
OllamaローカルLLM Webインターフェース
Flaskバックエンドサーバー
"""

from flask import Flask, render_template, request, jsonify, Response, stream_with_context
import ollama
import os
import json

app = Flask(__name__, static_folder='static', static_url_path='/static')

# Ollamaの接続設定
OLLAMA_HOST = os.environ.get('OLLAMA_HOST', 'http://localhost:11434')


@app.route('/')
def index():
    """メインページを表示"""
    return app.send_static_file('index.html')


@app.route('/api/models', methods=['GET'])
def get_models():
    """利用可能なモデルのリストを取得"""
    try:
        models_response = ollama.list()
        models = [model.get('name', model.get('model', 'unknown')) for model in models_response.get('models', [])]
        return jsonify({'models': models})
    except Exception as e:
        app.logger.error(f"Models API error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/chat', methods=['POST'])
def chat():
    """通常のチャット（非ストリーミング）"""
    try:
        data = request.json
        model = data.get('model', 'gemma2:2b')
        message = data.get('message', '')
        history = data.get('history', [])

        if not message:
            return jsonify({'error': 'メッセージが空です'}), 400

        # 履歴を含めたメッセージを構築
        messages = []
        for hist in history[-10:]:  # 直近10件のみ
            messages.append({
                'role': hist['role'],
                'content': hist['content']
            })

        # 現在のメッセージを追加（既に履歴に含まれている場合はスキップ）
        if not messages or messages[-1]['content'] != message:
            messages.append({
                'role': 'user',
                'content': message
            })

        # Ollamaでチャット
        response = ollama.chat(
            model=model,
            messages=messages
        )

        return jsonify({
            'response': response['message']['content']
        })

    except Exception as e:
        app.logger.error(f"Chat error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/chat/stream', methods=['POST'])
def chat_stream():
    """ストリーミングチャット"""
    try:
        data = request.json
        model = data.get('model', 'gemma2:2b')
        message = data.get('message', '')
        history = data.get('history', [])

        if not message:
            return jsonify({'error': 'メッセージが空です'}), 400

        # 履歴を含めたメッセージを構築
        messages = []
        for hist in history[-10:]:
            messages.append({
                'role': hist['role'],
                'content': hist['content']
            })

        # 現在のメッセージを追加
        if not messages or messages[-1]['content'] != message:
            messages.append({
                'role': 'user',
                'content': message
            })

        def generate():
            """ストリーミングレスポンスを生成"""
            try:
                stream = ollama.chat(
                    model=model,
                    messages=messages,
                    stream=True
                )

                for chunk in stream:
                    content = chunk['message']['content']
                    # Server-Sent Events形式で送信
                    yield f"data: {json.dumps({'content': content})}\n\n"

                yield "data: [DONE]\n\n"

            except Exception as e:
                app.logger.error(f"Stream error: {str(e)}")
                yield f"data: {json.dumps({'error': str(e)})}\n\n"

        return Response(
            stream_with_context(generate()),
            mimetype='text/event-stream',
            headers={
                'Cache-Control': 'no-cache',
                'X-Accel-Buffering': 'no'
            }
        )

    except Exception as e:
        app.logger.error(f"Chat stream error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    """ヘルスチェックエンドポイント"""
    try:
        # Ollamaが動作しているか確認
        ollama.list()
        return jsonify({'status': 'healthy', 'ollama': 'connected'})
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 503


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    print("=" * 50)
    print("OllamaローカルLLM Webインターフェース起動中...")
    print("=" * 50)
    print(f"Ollama Host: {OLLAMA_HOST}")
    print(f"アクセスURL: http://localhost:{port}")
    print("=" * 50)

    app.run(
        host='0.0.0.0',
        port=port,
        debug=True
    )
