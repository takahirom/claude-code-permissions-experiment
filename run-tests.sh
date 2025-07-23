#!/bin/bash

# Claude Code権限ルール実験スクリプト

echo "=== Claude Code Bash権限ルール実験 ==="
echo "日時: $(date)"
echo ""

# PATHにカレントディレクトリを追加
export PATH="$(pwd):$PATH"

# mycommandの権限確認
echo "mycommand の権限: $(ls -la mycommand)"
echo "PATH: $PATH"
echo "which mycommand: $(which mycommand)"
echo ""

# 結果ファイル
RESULTS_FILE="results.txt"
echo "# Claude Code Bash権限ルール実験結果" > "$RESULTS_FILE"
echo "実行日時: $(date)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# テスト実行関数
run_test() {
    local settings_file="$1"
    local test_command="$2"
    local description="$3"
    
    echo "【$description】"
    echo "設定: $settings_file → $test_command"
    
    # 設定適用
    cp "settings-patterns/$settings_file" .claude/settings.json
    
    # 結果記録
    echo "【$description】" >> "$RESULTS_FILE"
    echo "設定: $settings_file" >> "$RESULTS_FILE"
    echo "コマンド: $test_command" >> "$RESULTS_FILE"
    echo "結果:" >> "$RESULTS_FILE"
    
    # Claude Codeでテスト
    timeout 30s bash -c "echo 'execute bash \"$test_command\"' | claude" >> "$RESULTS_FILE" 2>&1
    echo "" >> "$RESULTS_FILE"
    echo "---"
}

# 実験1: 完全一致
echo "=== 実験1: 完全一致 Bash(./mycommand hello) ==="
run_test "01-exact-match.json" "./mycommand hello" "完全一致 - 許可"
run_test "01-exact-match.json" "./mycommand hi" "完全一致 - 拒否"

# 実験2: ワイルドカード
echo "=== 実験2: ワイルドカード Bash(./mycommand*) ==="
run_test "02-wildcard.json" "./mycommand hello" "ワイルドカード - 基本"
run_test "02-wildcard.json" "./mycommand -f hello" "ワイルドカード - オプション"

# 実験3: コロン記法
echo "=== 実験3: コロン記法 Bash(./mycommand:*) ==="
run_test "03-colon.json" "./mycommand hello" "コロン記法 - 通常"
run_test "03-colon.json" "./mycommand:hello" "コロン記法 - コロン付き"

# 実験4: mycommand限定 -f パターン
echo "=== 実験4: mycommand限定 -f パターン Bash(./mycommand:*-f*) ==="
run_test "04-force-wildcard.json" "./mycommand -f hello" "mycommand:*-f* - 許可"
run_test "04-force-wildcard.json" "./mycommand -n hello" "mycommand:*-f* - 拒否"

# 実験5: 二重コロン
echo "=== 実験5: 二重コロン Bash(./mycommand:sub:*) ==="
run_test "05-double-colon.json" "./mycommand hello" "double colon - 通常"
run_test "05-double-colon.json" "./mycommand sub" "double colon - sub単体"
run_test "05-double-colon.json" "./mycommand hello sub" "double colon - スペース区切り"
run_test "05-double-colon.json" "./mycommand:sub hello" "double colon - 1コロン"
run_test "05-double-colon.json" "./mycommand:sub:hello" "double colon - 2コロン"

# 実験6: -f 後続パターン
echo "=== 実験6: -f 後続パターン Bash(./mycommand:-f*) ==="
run_test "06-f-suffix.json" "./mycommand -f" ":-f* - 単体"
run_test "06-f-suffix.json" "./mycommand -f hello" ":-f* - 引数付き"
run_test "06-f-suffix.json" "./mycommand hoge -f huga" ":-f* - 中間-f"
run_test "06-f-suffix.json" "./mycommand -n hello" ":-f* - 異なるオプション"

# 実験7: シンプル -f
echo "=== 実験7: シンプル -f Bash(./mycommand:-f) ==="
run_test "07-simple-f.json" "./mycommand -f" ":-f - 完全一致"
run_test "07-simple-f.json" "./mycommand -f hello" ":-f - 引数付き"
run_test "07-simple-f.json" "./mycommand hoge -f huga" ":-f - 中間-f"

# 実験8: スペース含むコロンパターン
echo "=== 実験8: スペース含むコロンパターン Bash(./mycommand -f:*) ==="
run_test "08-colon-space-test.json" "./mycommand -f" "空文字列継続 - 基本"
run_test "08-colon-space-test.json" "./mycommand -f hoge" "空文字列継続 - 引数付き"
run_test "08-colon-space-test.json" "./mycommand hoge -f" "空文字列継続 - 順序違い"

echo ""
echo "=== 実験完了 ==="
echo "結果は $RESULTS_FILE を確認してください"