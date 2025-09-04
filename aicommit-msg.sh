#!/usr/bin/env bash
set -euo pipefail

# ========================================================
# Git Commit AI Message Generator ✨
# ========================================================
#
# To be able to run this script from anywhere, add it to your PATH or in ~/.local/bin after making it executable.
#
# ========================================================
# TIP: create `.aicommit.env` file in your root home dir to override values and set API keys
#
# ----------- [EXAMPLE] .aicommit.env -----------
#   DEFAULT_PROVIDER="gemini"
#   OPENAI_MODEL="gpt-4o-mini"
#   GEMINI_MODEL="gemini-2.5-flash-lite"
#   OLLAMA_MODEL="llama3.2"
#   GEMINI_API_KEY="YOUR_GOOGLE_API_KEY"
#   OPENAI_API_KEY="YOUR_OPENAI_API_KEY"
#
# -----------------------------------------------
#
# The script will auto-load this file if it exists.
# ========================================================
#

ENV_FILE="$HOME/.aicommit.env"
if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

: "${DEFAULT_PROVIDER:=gemini}"
: "${OPENAI_MODEL:=gpt-4o-mini}"
: "${GEMINI_MODEL:=gemini-2.5-flash-lite}"
: "${OLLAMA_MODEL:=llama3.2}"

PROVIDER=""
FULL_MODE="false"
VERBOSE="false"

show_help() {
    cat <<EOF

****************************************
Git Commit AI Message Generator ✨
****************************************

Usage:
  aicommit-msg [provider] [options]

Provider resolution order:
  1. CLI argument (first non-flag argument)
  2. AI_MODEL_PROVIDER environment variable
  3. Default provider: $DEFAULT_PROVIDER

Supported providers:
  openai   - OpenAI (Model: $OPENAI_MODEL)
  gemini   - Google Gemini (Model: $GEMINI_MODEL)
  copilot  - GitHub Copilot CLI (No reliable for commit messages)
  ollama   - Ollama local model (Model: $OLLAMA_MODEL) 

Options:
  --full       Include full code diff in prompt (unsafe for sensitive code)
  -v, --verbose  Enable verbose logging
  -h, --help     Show this help message

Modes:
  SAFE  - Default, only file names and status (recommended)
  FULL  - Include complete staged diff

Notes:
  - Generated message is copied to clipboard if possible.
  - Also exported to environment variable AI_COMMIT_MSG
    (works only if the script is sourced).
  - If you want to use different models, change the script accordingly.

Examples:
  aicommit-msg openai
  aicommit-msg gemini --full
  AI_MODEL_PROVIDER=copilot ./aicommit-msg.sh -v

Read the script header for more details on default configuration for API keys and models.

EOF
}

# --- parse args ---
for arg in "$@"; do
    case "$arg" in
        --full) FULL_MODE="true" ;;
        -v|--verbose) VERBOSE="true" ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --*) 
            ;;  # ignore unknown flags
        *)
            if [ -z "$PROVIDER" ]; then
                PROVIDER="$arg"
            fi
            ;;
    esac
done


# verbose logging
logv() {
  if [ "$VERBOSE" = "true" ]; then
    echo "[DEBUG] $*"
  fi
}


logv "Verbose mode enabled"


if [ -z "$PROVIDER" ] && [ -n "${AI_MODEL_PROVIDER:-}" ]; then
    logv "Using provider from AI_MODEL_PROVIDER env var"
    PROVIDER="$AI_MODEL_PROVIDER"
fi

if [ -z "$PROVIDER" ]; then
    logv "Using default provider: $DEFAULT_PROVIDER"
    PROVIDER="$DEFAULT_PROVIDER"
fi


if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "[ERROR] Not inside a git repository."
    exit 1
fi

# first check if there are staged changes
if ! git diff --cached --quiet; then
    logv "Found staged changes."
else
    echo "[ERROR] No staged changes found."
    exit 1
fi

if [ "$FULL_MODE" = "true" ]; then
    echo "[-] Using full diff mode, be sure that you do not commit sensitive data!"
    CHANGES=$(git diff --cached)
    MODE="FULL"
else
    CHANGES=$(git status --short --branch)
    MODE="SAFE"
fi


logv "Using provider: $PROVIDER"
logv "Mode: $MODE"


MAX_BYTES=$((15 * 1024))  # 15 KB
CHANGE_SIZE=$(printf "%s" "$CHANGES" | wc -c)


logv "Change size: $CHANGE_SIZE bytes"
logv "-------------- Changes --------------"
logv "$CHANGES"
logv "-------------------------------------"



if [ "$CHANGE_SIZE" -gt "$MAX_BYTES" ]; then
    echo "[WARN] Staged diff too large: ${CHANGE_SIZE} bytes"

    if [ "$FULL_MODE" = "true" ]; then
        echo "[ERROR] Refusing to send full diff over ${MAX_BYTES} bytes."
        echo "        Try without --full (safer summary mode)."
        exit 1
    else
        echo "[-] Using top 120 modified files only"
        # take only the top 120 modified files
        CHANGES=$(git diff --cached --name-status | head -n 120)
    fi
fi


PROMPT=$(cat <<EOF
You are a professional developer assistant. Generate a git commit message
for the staged changes provided below. Follow **Conventional Commit style**
strictly with header, body, and footer.

[Instructions]
1. Header format: <type>(<scope>): <subject>
   - type: must be one of the following (all lower case):
     chore    : routine/automated tasks
     deprecate: deprecating functionality
     feat     : adding new functionality
     fix      : bug fixes/errors
     release  : release-related changes
   - scope: optional, relevant module/area
   - subject: imperative, concise (≤50 chars)
2. Blank line
3. Body:
   - Explain **what** was changed and **why**
   - In bullet points for multiple changes
   - Wrap lines at ~72 characters
4. Blank line
5. Footer:
   - Optional, include metadata (e.g., BREAKING CHANGE)
6. Important
    - Do not make up any descriptions or assumptions.
    - Do **not** create descriptions, explanations, or context that
     are not present in the staged changes.
    - If the change is obvious from the staged changes or commit title,
     leave body and footer empty.
7. Output exactly in this format:

<type>(<scope>): <subject>

<body>

<footer>

Context (staged changes):
$CHANGES
EOF
)


logv "-------------- Prompt --------------"
logv "$PROMPT"
logv "------------------------------------"


# --- Providers ---
generate_openai() {
    if [ -z "${OPENAI_API_KEY:-}" ]; then
        echo "[ERROR] OPENAI_API_KEY not set." >&2
        exit 1
    fi
    curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
          \"model\": \"$OPENAI_MODEL\",
          \"messages\": [
            {\"role\": \"system\", \"content\": \"You are a helpful assistant for writing commit messages.\"},
            {\"role\": \"user\", \"content\": \"$PROMPT\"}
          ]
        }" | jq -r '.choices[0].message.content'
}

generate_gemini() {
    if [ -z "${GEMINI_API_KEY:-}" ]; then
        echo "[ERROR] GEMINI_API_KEY not set." >&2
        exit 1
    fi
    curl -s -X POST \
        -H "Content-Type: application/json" \
        "https://generativelanguage.googleapis.com/v1beta/models/$GEMINI_MODEL:generateContent?key=$GEMINI_API_KEY" \
        -d "{
          \"contents\": [{
            \"parts\": [{\"text\": \"$PROMPT\"}]
          }]
        }" | jq -r '.candidates[0].content.parts[0].text'
}

generate_copilot() {
    if ! command -v gh &>/dev/null; then
        echo "[ERROR] GitHub CLI (gh) not installed." >&2
        exit 1
    fi
    gh copilot explain "$PROMPT"
}

generate_ollama() {
    if ! command -v ollama &>/dev/null; then
        echo "[ERROR] Ollama not installed." >&2
        exit 1
    fi
    echo "$PROMPT" | ollama run "$OLLAMA_MODEL"
}


RESPONSE=""

echo "--- using provider: $PROVIDER (mode: $MODE)"

case "$PROVIDER" in
    openai)   RESPONSE=$(generate_openai) ;;
    gemini)   RESPONSE=$(generate_gemini) ;;
    copilot)  RESPONSE=$(generate_copilot) ;;
    ollama)   RESPONSE=$(generate_ollama) ;;
    *)
        echo "[ERROR] Unknown provider: $PROVIDER (use openai|gemini|copilot|ollama)"
        exit 1
        ;;
esac

if [ -z "$RESPONSE" ]; then
    echo "[ERROR] No response from AI provider."
    exit 1
fi

echo
echo "✨ Suggested Commit Message:"
echo "--------------------------------------------------"
echo "$RESPONSE"
echo "--------------------------------------------------"

# --- copy to clipboard if possible ---
copy_to_clipboard() {
    if command -v pbcopy &>/dev/null; then
        printf "%s" "$1" | pbcopy
    elif command -v wl-copy &>/dev/null; then
        printf "%s" "$1" | wl-copy
    elif command -v xclip &>/dev/null; then
        printf "%s" "$1" | xclip -selection clipboard
    else
        echo "[-] Install pbcopy (macOS), xclip (X11), or wl-copy (Wayland) to enable clipboard copy."
        return 1
    fi
    echo "[-] copied to clipboard."
}

copy_to_clipboard "$RESPONSE"

# save to env, will only work if sourced
export AI_COMMIT_MSG="$RESPONSE"
