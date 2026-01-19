# 🌟 Gemini CLI - AI Agent Skill

## Overview
Google Gemini 2.0 Flash is one of the fastest multimodal AI models available. This skill teaches agents how to use Gemini via CLI for text, image, and code tasks.

## Why Gemini for Mobile?

✅ **Blazing Fast**: 2-3x faster than Claude on simple tasks  
✅ **Multimodal**: Text, images, audio, video support  
✅ **Free Tier**: Generous quota (15 RPM, 1M TPM)  
✅ **Long Context**: Up to 1M tokens  
✅ **Code Execution**: Built-in Python interpreter

## Prerequisites

- Agents-Mobile installed
- Bun runtime
- Google AI Studio API key (free)

## Getting API Key

1. Visit: https://ai.google.dev/aistudio
2. Click **"Get API Key"**
3. Create new key or use existing
4. Copy key (format: `AIza...`)

## Installation

### Method 1: Official CLI (Recommended)
```bash
# Install via Bun
bun install -g @google/generative-ai-cli

# Or via npm (if Bun fails)
npm install -g @google/generative-ai-cli

# Verify
genai --version
```

### Method 2: Custom Wrapper
Create `~/.local/bin/gemini`:

```bash
#!/usr/bin/env bash
# Gemini CLI wrapper using curl

API_KEY="${GEMINI_API_KEY:-}"
MODEL="${GEMINI_MODEL:-gemini-2.0-flash-exp}"
API_URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent"

if [[ -z "$API_KEY" ]]; then
    echo "Error: GEMINI_API_KEY not set"
    exit 1
fi

PROMPT="$*"

if [[ -z "$PROMPT" ]]; then
    echo "Usage: gemini <prompt>"
    exit 1
fi

# Build request
REQUEST=$(cat <<EOF
{
  "contents": [{
    "parts": [{
      "text": "$PROMPT"
    }]
  }]
}
EOF
)

# Make API call
curl -s "$API_URL?key=$API_KEY" \
    -H 'Content-Type: application/json' \
    -d "$REQUEST" | \
    jq -r '.candidates[0].content.parts[0].text // "Error: No response"'
```

Make executable:
```bash
chmod +x ~/.local/bin/gemini
```

## Configuration

### Set API Key
```bash
# Temporary (current session)
export GEMINI_API_KEY="AIza..."

# Permanent (add to ~/.zshrc or ~/.bashrc)
echo 'export GEMINI_API_KEY="AIza..."' >> ~/.zshrc
source ~/.zshrc
```

### Choose Model
Available models:
- `gemini-2.0-flash-exp` - **Recommended** (fastest, free)
- `gemini-1.5-pro` - More capable, slower
- `gemini-1.5-flash` - Good balance

```bash
# Set default model
export GEMINI_MODEL="gemini-2.0-flash-exp"
```

## Usage Patterns

### Basic Queries
```bash
# Simple question
gemini "What is Bun runtime?"

# Code explanation
gemini "Explain this code: $(cat server.ts)"

# Code generation
gemini "Write a Bun HTTP server with WebSocket support"
```

### With Files
```bash
# Analyze file
gemini "Review this code for bugs" < server.ts

# Multiple files
cat src/*.ts | gemini "Find common patterns in these files"

# Diff review
git diff | gemini "Review these changes"
```

### Interactive Mode
```bash
# Start conversation
gemini-chat() {
    while true; do
        read -p "You: " prompt
        [[ -z "$prompt" ]] && break
        echo -n "Gemini: "
        gemini "$prompt"
        echo ""
    done
}

gemini-chat
```

### With Images (Multimodal)
```bash
# Analyze screenshot
gemini-vision screenshot.png "What's in this image?"

# OCR text extraction
gemini-vision document.jpg "Extract all text from this image"

# Code from whiteboard
gemini-vision whiteboard.jpg "Convert this pseudocode to TypeScript"
```

## Advanced Features

### Code Execution
Gemini can run Python code internally:

```bash
gemini "Calculate the first 100 prime numbers and return as JSON"
```

### Long Context
Process entire codebases:

```bash
# Analyze all TypeScript files
find . -name "*.ts" -exec cat {} \; | gemini "Summarize this codebase architecture"
```

### Structured Output
Request JSON responses:

```bash
gemini "List 5 Bun optimization tips in JSON format with fields: tip, impact, difficulty"
```

## Integration with Agents-Mobile

### 1. Code Review Agent
```bash
# Pre-commit hook
cat > .git/hooks/pre-commit << 'EOFHOOK'
#!/bin/bash
git diff --cached | gemini "Review these changes for bugs and suggest improvements"
EOFHOOK

chmod +x .git/hooks/pre-commit
```

### 2. Documentation Generator
```bash
# Generate skill documentation
gemini "Create a skill guide for Docker integration in Markdown format" > skills/docker.md
```

### 3. Debugging Assistant
```bash
# Analyze logs
tail -n 100 /var/log/app.log | gemini "Find errors and suggest fixes"

# Performance analysis
bun --print bench.ts 2>&1 | gemini "Optimize this benchmark"
```

### 4. Mission Planner
```bash
# Generate new mission
gemini "Create a mission for testing Agents-Mobile on Samsung Galaxy S21" > missions/mission-03-samsung.md
```

## Aliases for Agents-Mobile

Add to `~/.agents-mobile/aliases/core.zsh`:

```bash
# Gemini shortcuts
alias ask='gemini'
alias explain='gemini "Explain: "'
alias code-review='git diff | gemini "Review these changes"'
alias gen-docs='gemini "Generate documentation for this file: "'
alias fix-bug='gemini "Fix this bug: "'
alias optimize='gemini "Optimize this code: "'

# Multimodal
alias ocr='gemini-vision --mode ocr'
alias describe='gemini-vision --mode describe'
```

## Mobile Optimizations

### Reduce Token Usage
```bash
# Truncate input
gemini "$(cat large-file.ts | head -n 100) ... (truncated)"

# Summarize first
SUMMARY=$(cat large-file.ts | gemini "Summarize in 3 sentences")
gemini "Based on this summary: $SUMMARY, suggest improvements"
```

### Batch Requests
```bash
# Collect questions, send once
QUESTIONS=$(cat <<EOF
1. How to optimize Bun for ARM?
2. Best practices for mobile development?
3. How to reduce memory usage?
EOF
)

gemini "$QUESTIONS"
```

### Cache Responses
```bash
# Cache common queries
CACHE_DIR=~/.cache/gemini
mkdir -p "$CACHE_DIR"

gemini-cached() {
    HASH=$(echo "$*" | md5sum | cut -d' ' -f1)
    CACHE_FILE="$CACHE_DIR/$HASH"
    
    if [[ -f "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
    else
        gemini "$@" | tee "$CACHE_FILE"
    fi
}
```

## Comparison with Other Models

| Feature | Gemini Flash | Claude Sonnet | Grok Code |
|---------|-------------|---------------|-----------|
| **Speed** | 🟢 Fastest | 🟡 Fast | 🟢 Very Fast |
| **Code Quality** | 🟡 Good | 🟢 Excellent | 🟢 Very Good |
| **Context Window** | 🟢 1M tokens | 🟢 200K tokens | 🟡 128K tokens |
| **Cost (Free)** | 🟢 15 RPM | 🔴 Limited | 🟢 Unlimited* |
| **Multimodal** | 🟢 Yes | 🟡 Limited | 🔴 No |
| **Best For** | Speed, Images | Deep Reasoning | Quick Code |

*Via OpenCode Zen

## Troubleshooting

### Issue: API Key Invalid
```bash
# Test API key
curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY" | jq

# Should return list of models
```

### Issue: Rate Limit
```bash
# Check quota
gemini "ping" >/dev/null
echo "Status: $?"  # 0 = success, 1 = rate limited

# Wait and retry
sleep 60
```

### Issue: Response Truncated
```bash
# Increase max tokens (default: 2048)
gemini --max-tokens 8192 "Long prompt here..."
```

## Best Practices

### 1. Be Specific
```bash
# Bad
gemini "Help with code"

# Good
gemini "Refactor this Bun server to use async/await instead of callbacks"
```

### 2. Use Examples
```bash
# Provide example of desired output
gemini "Convert this to TypeScript. Example output: interface User { id: string; name: string; }"
```

### 3. Iterate
```bash
# Step 1: High-level plan
PLAN=$(gemini "How should I structure a REST API in Bun?")

# Step 2: Detailed implementation
gemini "Implement this plan: $PLAN"
```

## Security Considerations

⚠️ **Never send sensitive data**:
- API keys (except Gemini's own)
- Passwords
- Personal information
- Proprietary code (if restricted)

Use local models (Ollama) for sensitive work.

## Resources

- **Official Docs**: https://ai.google.dev/docs
- **API Reference**: https://ai.google.dev/api
- **Pricing**: https://ai.google.dev/pricing (free tier: 15 RPM, 1M TPM)
- **Model Garden**: https://ai.google.dev/models
- **Community**: https://discuss.ai.google.dev

## Agent Instructions

When using Gemini:

1. ✅ **Use for speed** - Gemini is fastest for simple tasks
2. ✅ **Leverage multimodal** - Send images/screenshots when helpful
3. ✅ **Request structured output** - JSON, tables, code blocks
4. ✅ **Cache common queries** - Avoid repeating expensive calls
5. ✅ **Batch when possible** - Multiple questions in one request
6. ❌ **Don't send secrets** - Use local models for sensitive data
7. ❌ **Don't exceed rate limits** - 15 RPM on free tier
8. ❌ **Don't ignore errors** - Check response before using

## Success Metrics

- ✅ API key configured and working
- ✅ CLI responds to basic queries
- ✅ Multimodal queries work (if needed)
- ✅ Integration with Agents-Mobile aliases
- ✅ Response time < 3s for typical queries

---

**Skill Level**: Beginner  
**Estimated Setup Time**: 5-10 minutes  
**Mobile Compatible**: ✅ Yes (excellent)  
**Requires Root**: ❌ No  
**Free Tier**: ✅ Yes (15 RPM, 1M TPM)
