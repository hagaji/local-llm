#!/usr/bin/env python3
"""
Ollamaを使ったローカルLLMのPythonサンプルコード
"""

import ollama

def simple_chat():
    """シンプルなチャット例"""
    print("=== シンプルなチャット例 ===")
    response = ollama.chat(
        model='gemma2:2b',
        messages=[
            {
                'role': 'user',
                'content': '日本の首都は？簡潔に答えてください。',
            },
        ]
    )
    print(f"質問: 日本の首都は？")
    print(f"回答: {response['message']['content']}\n")


def streaming_chat():
    """ストリーミングレスポンス例"""
    print("=== ストリーミングレスポンス例 ===")
    print("質問: Pythonの特徴を3つ教えてください。")
    print("回答: ", end="", flush=True)

    stream = ollama.chat(
        model='gemma2:2b',
        messages=[
            {
                'role': 'user',
                'content': 'Pythonの特徴を3つ、簡潔に教えてください。',
            },
        ],
        stream=True,
    )

    for chunk in stream:
        print(chunk['message']['content'], end='', flush=True)
    print("\n")


def multi_turn_conversation():
    """複数ターンの会話例"""
    print("=== 複数ターンの会話例 ===")

    messages = [
        {'role': 'user', 'content': '猫について教えてください。'},
    ]

    # 1ターン目
    response = ollama.chat(model='gemma2:2b', messages=messages)
    print(f"ユーザー: {messages[0]['content']}")
    print(f"AI: {response['message']['content']}\n")

    # 会話履歴に追加
    messages.append(response['message'])
    messages.append({'role': 'user', 'content': 'では犬との違いは？'})

    # 2ターン目
    response = ollama.chat(model='gemma2:2b', messages=messages)
    print(f"ユーザー: {messages[2]['content']}")
    print(f"AI: {response['message']['content']}\n")


def main():
    """メイン関数"""
    print("OllamaローカルLLMサンプルプログラム\n")

    try:
        # 使用可能なモデルのリスト取得
        models = ollama.list()
        print(f"利用可能なモデル数: {len(models['models'])}")
        for model in models['models']:
            print(f"  - {model['name']}")
        print()

        # 各種サンプルを実行
        simple_chat()
        streaming_chat()
        multi_turn_conversation()

        print("すべてのサンプルが完了しました！")

    except Exception as e:
        print(f"エラーが発生しました: {e}")
        print("\nOllamaが起動していることを確認してください:")
        print("  brew services start ollama")


if __name__ == "__main__":
    main()
