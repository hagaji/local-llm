// チャット履歴を保存
let chatHistory = [];

// ページ読み込み時にモデルリストを取得
document.addEventListener('DOMContentLoaded', () => {
    loadModels();

    // Enterキーで送信（Shift+Enterで改行）
    // isComposingで日本語入力中（変換中）を除外
    document.getElementById('user-input').addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) {
            e.preventDefault();
            sendMessage();
        }
    });
});

// モデル名を読みやすい形式に変換
function formatModelName(modelId) {
    const modelNames = {
        'gemma2:2b': '🔹 Gemma 2B (軽量・高速)',
        'llama3.2:3b': '🦙 Llama 3.2 3B (汎用)',
        'llama3.2:1b': '🦙 Llama 3.2 1B (超軽量)',
        'qwen2.5:3b': '🌟 Qwen 2.5 3B (日本語推奨)',
        'qwen2.5:7b': '🌟 Qwen 2.5 7B (高性能)',
        'qwen2.5:14b': '🌟 Qwen 2.5 14B (日本語特化)',
        'codellama:7b': '💻 CodeLlama 7B (コード)',
        'mistral:7b': '⚡ Mistral 7B (高性能)',
        'phi3:mini': '🧠 Phi 3 Mini (効率的)',
    };
    return modelNames[modelId] || modelId;
}

// モデルリストを取得
async function loadModels() {
    try {
        const response = await fetch('/api/models');
        const data = await response.json();

        const select = document.getElementById('model-select');
        select.innerHTML = '';

        if (data.models.length === 0) {
            const option = document.createElement('option');
            option.value = '';
            option.textContent = 'モデルがありません';
            select.appendChild(option);
            return;
        }

        data.models.forEach(model => {
            const option = document.createElement('option');
            option.value = model;
            option.textContent = formatModelName(model);
            select.appendChild(option);
        });
    } catch (error) {
        console.error('モデルリストの取得に失敗:', error);
        const select = document.getElementById('model-select');
        select.innerHTML = '<option value="">エラー: モデル取得失敗</option>';
    }
}

// モデル更新ボタン
document.getElementById('refresh-models').addEventListener('click', loadModels);

// メッセージを送信
async function sendMessage() {
    const input = document.getElementById('user-input');
    const message = input.value.trim();

    if (!message) return;

    // ユーザーメッセージを表示
    addMessage('user', message);
    chatHistory.push({ role: 'user', content: message });

    // 入力欄をクリア
    input.value = '';

    // 送信ボタンを無効化
    const sendBtn = document.getElementById('send-btn');
    const sendText = document.getElementById('send-text');
    const spinner = document.getElementById('loading-spinner');
    sendBtn.disabled = true;
    sendText.style.display = 'none';
    spinner.style.display = 'inline';

    // モデルとストリーミング設定を取得
    const model = document.getElementById('model-select').value;
    const streaming = document.getElementById('stream-toggle').checked;

    try {
        if (streaming) {
            await sendStreamingMessage(model, message);
        } else {
            await sendNormalMessage(model, message);
        }
    } catch (error) {
        showError('エラーが発生しました: ' + error.message);
    } finally {
        // 送信ボタンを再有効化
        sendBtn.disabled = false;
        sendText.style.display = 'inline';
        spinner.style.display = 'none';
    }
}

// 通常のメッセージ送信
async function sendNormalMessage(model, message) {
    const response = await fetch('/api/chat', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            model: model,
            message: message,
            history: chatHistory.slice(-10) // 直近10件の履歴のみ送信
        })
    });

    if (!response.ok) {
        throw new Error('サーバーエラー');
    }

    const data = await response.json();
    addMessage('assistant', data.response);
    chatHistory.push({ role: 'assistant', content: data.response });
}

// ストリーミングメッセージ送信
async function sendStreamingMessage(model, message) {
    const response = await fetch('/api/chat/stream', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            model: model,
            message: message,
            history: chatHistory.slice(-10)
        })
    });

    if (!response.ok) {
        throw new Error('サーバーエラー');
    }

    // ストリーミングレスポンスを処理
    const reader = response.body.getReader();
    const decoder = new TextDecoder();

    // アシスタントのメッセージ要素を作成
    const messageElement = createMessageElement('assistant', '');
    const contentElement = messageElement.querySelector('.message-content');

    let fullResponse = '';
    let buffer = '';  // 未処理のデータをバッファリング

    while (true) {
        const { done, value } = await reader.read();

        if (done) break;

        // streamオプションでマルチバイト文字の分割を防ぐ
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');

        // 最後の不完全な行はバッファに残す
        buffer = lines.pop() || '';

        for (const line of lines) {
            if (line.startsWith('data: ')) {
                const data = line.slice(6).trim();
                if (data === '[DONE]') {
                    break;
                }
                if (data === '') continue;  // 空行をスキップ

                try {
                    const json = JSON.parse(data);
                    if (json.content) {
                        fullResponse += json.content;
                        contentElement.textContent = fullResponse;
                        scrollToBottom();
                    }
                    if (json.error) {
                        throw new Error(json.error);
                    }
                } catch (e) {
                    console.error('JSONパースエラー:', e, 'データ:', data);
                }
            }
        }
    }

    chatHistory.push({ role: 'assistant', content: fullResponse });
}

// メッセージを追加
function addMessage(role, content) {
    const messageElement = createMessageElement(role, content);
    scrollToBottom();
}

// メッセージ要素を作成
function createMessageElement(role, content) {
    const chatContainer = document.getElementById('chat-container');

    // ウェルカムメッセージを削除
    const welcomeMessage = chatContainer.querySelector('.welcome-message');
    if (welcomeMessage) {
        welcomeMessage.remove();
    }

    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${role}-message`;

    const headerDiv = document.createElement('div');
    headerDiv.className = 'message-header';
    headerDiv.textContent = role === 'user' ? 'あなた' : 'AI';

    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content';
    contentDiv.textContent = content;

    messageDiv.appendChild(headerDiv);
    messageDiv.appendChild(contentDiv);
    chatContainer.appendChild(messageDiv);

    return messageDiv;
}

// チャットをクリア
function clearChat() {
    if (confirm('チャット履歴をクリアしますか？')) {
        chatHistory = [];
        const chatContainer = document.getElementById('chat-container');
        chatContainer.innerHTML = `
            <div class="welcome-message">
                <h2>ようこそ！</h2>
                <p>ローカルで動作するLLMとチャットできます。</p>
                <p>下のテキストボックスに質問を入力してください。</p>
            </div>
        `;
    }
}

// エラーメッセージを表示
function showError(message) {
    const chatContainer = document.getElementById('chat-container');
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.textContent = message;
    chatContainer.appendChild(errorDiv);
    scrollToBottom();
}

// 自動スクロール
function scrollToBottom() {
    const chatContainer = document.getElementById('chat-container');
    chatContainer.scrollTop = chatContainer.scrollHeight;
}
