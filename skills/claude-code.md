---
name: Claude Code Integration
description: Integrate Claude Code CLI agent with Agents-Mobile environment
when_to_use: When you want to use Anthropic's Claude as your primary mobile AI agent
difficulty: Beginner
requires: Node.js or Bun, API key from Anthropic
---

# 🤖 Claude Code Integration Skill

This skill teaches how to set up **Claude Code CLI** in the Agents-Mobile environment.

> **Note**: "Claude Code" refers to Anthropic's Claude AI accessed via CLI tools, not a specific product called "Claude Code".

## What is Claude?

**Claude** (by Anthropic) is an advanced AI assistant that excels at:
- 💻 **Code generation** and debugging
- 📚 **Long context** understanding (200K tokens)
- 🧠 **Complex reasoning** and analysis
- 🛠️ **Tool use** via MCP protocol

## Installation Options

### Option 1: Official Anthropic SDK

```bash
# Install Anthropic CLI tools
bun add @anthropic-ai/sdk

# Or globally
bun install -g @anthropic-ai/sdk
```

### Option 2: Community CLI Tools

```bash
# Claude CLI (community-built)
bun install -g claude-cli

# Alternative: aichat (supports multiple providers)
bun install -g aichat
```

### Option 3: OpenCode Integration

If using OpenCode editor:

```json
// ~/.config/opencode/opencode.jsonc
{
  "ai": {
    "provider": "anthropic",
    "model": "claude-sonnet-4",
    "apiKey": "your-api-key-here"
  }
}
```

## Setup Steps

### 1. Get API Key

- Visit: https://console.anthropic.com
- Create account (or sign in)
- Go to API Keys section
- Generate new key
- Copy key (starts with `sk-ant-...`)

### 2. Configure Environment

```bash
# Add to ~/.bashrc or ~/.zshrc
export ANTHROPIC_API_KEY="sk-ant-your-key-here"

# Reload shell
source ~/.bashrc  # or source ~/.zshrc
```

### 3. Test Connection

```bash
# Using Anthropic SDK
bun -e "
import Anthropic from '@anthropic-ai/sdk';
const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
const msg = await client.messages.create({
  model: 'claude-sonnet-4',
  max_tokens: 100,
  messages: [{ role: 'user', content: 'Hello Claude!' }]
});
console.log(msg.content[0].text);
"
```

Expected output: Claude's greeting response.

### 4. Create Helper Script

Create `scripts/claude.sh`:

```bash
#!/bin/bash
# Simple Claude CLI wrapper for Agents-Mobile

PROMPT="$1"

if [[ -z "$PROMPT" ]]; then
    echo "Usage: bash scripts/claude.sh 'your prompt here'"
    exit 1
fi

bun -e "
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY
});

const response = await client.messages.create({
  model: 'claude-sonnet-4',
  max_tokens: 4096,
  messages: [
    { role: 'user', content: \`$PROMPT\` }
  ]
});

console.log(response.content[0].text);
"
```

Usage:

```bash
chmod +x scripts/claude.sh
bash scripts/claude.sh "Explain how Bun works"
```

## Mobile-Specific Optimizations

### 1. Reduce Token Usage (Save Battery/Data)

```javascript
// Shorter context for mobile
const response = await client.messages.create({
  model: 'claude-sonnet-4',
  max_tokens: 1024,  // Lower limit
  messages: [...]
});
```

### 2. Cache Responses Locally

```javascript
import { createHash } from 'crypto';

const cacheDir = '/sdcard/Agents-Mobile/claude-cache';

async function cachedClaude(prompt) {
  const hash = createHash('md5').update(prompt).digest('hex');
  const cachePath = `${cacheDir}/${hash}.json`;
  
  // Check cache
  const cached = Bun.file(cachePath);
  if (await cached.exists()) {
    return await cached.json();
  }
  
  // Call API
  const response = await client.messages.create({...});
  
  // Save to cache
  await Bun.write(cachePath, JSON.stringify(response));
  
  return response;
}
```

### 3. Offline Mode (Use Cached Skills)

```bash
# If no internet, use local skills
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    echo "📶 Offline mode - using cached skills"
    cat skills/mcp-builder.md
else
    echo "🌐 Online - calling Claude API"
    bash scripts/claude.sh "Explain MCP protocol"
fi
```

## Integrating with MCP

Enable Claude to use MCP tools:

```javascript
const response = await client.messages.create({
  model: 'claude-sonnet-4',
  max_tokens: 4096,
  tools: [
    {
      name: "save_context",
      description: "Save data to MCP storage",
      input_schema: {
        type: "object",
        properties: {
          key: { type: "string" },
          value: { type: "string" }
        }
      }
    }
  ],
  messages: [
    { role: "user", content: "Save 'Hello' to context key 'greeting'" }
  ]
});

// Handle tool use
if (response.stop_reason === 'tool_use') {
  const toolUse = response.content.find(c => c.type === 'tool_use');
  // Execute tool (e.g., call MCP server)
}
```

## Loading Skills

Point Claude to Agents-Mobile skills:

```javascript
const skillsContext = await Bun.file('skills/mcp-builder.md').text();

const response = await client.messages.create({
  model: 'claude-sonnet-4',
  max_tokens: 4096,
  messages: [
    {
      role: 'user',
      content: `Context: ${skillsContext}\n\nTask: Create an MCP server for todo management`
    }
  ]
});
```

## Cost Optimization

**Pricing** (as of 2026):
- Claude Sonnet 4: ~$0.003/1K tokens (input), ~$0.015/1K tokens (output)
- Claude Haiku: ~$0.00025/1K tokens (cheaper, faster)

**Tips**:
- Use **Haiku** for simple tasks (saves 90% cost)
- Cache responses aggressively
- Use streaming for long responses (better UX)

```javascript
// Streaming example
const stream = await client.messages.create({
  model: 'claude-sonnet-4',
  max_tokens: 1024,
  stream: true,
  messages: [...]
});

for await (const chunk of stream) {
  if (chunk.type === 'content_block_delta') {
    process.stdout.write(chunk.delta.text);
  }
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "API key invalid" | Check `ANTHROPIC_API_KEY` is set correctly |
| "Rate limit exceeded" | Wait 60s or upgrade plan |
| "Network timeout" | Check mobile data/WiFi, increase timeout |
| "Out of memory" | Reduce `max_tokens` to 1024 or less |
| "Tool use failed" | Verify MCP server is running |

## Advanced: Multi-Turn Conversations

```javascript
const conversationHistory = [];

async function chat(userMessage) {
  conversationHistory.push({
    role: 'user',
    content: userMessage
  });
  
  const response = await client.messages.create({
    model: 'claude-sonnet-4',
    max_tokens: 2048,
    messages: conversationHistory
  });
  
  conversationHistory.push({
    role: 'assistant',
    content: response.content[0].text
  });
  
  return response.content[0].text;
}

// Usage
await chat("Hello!");
await chat("What's 2+2?");
await chat("Multiply that by 10");
```

## Example Use Cases

1. **Code Review**: Paste code, ask Claude to review
2. **Debug Help**: Share error, get solution
3. **Documentation**: Generate docs from code
4. **Learning**: Ask technical questions
5. **Refactoring**: Get optimization suggestions

```bash
# Quick helper
alias ask-claude="bash scripts/claude.sh"

# Usage
ask-claude "How do I optimize this Bun script?"
```

---

**Skill Level**: Beginner  
**Estimated Time**: 20-30 minutes  
**Cost**: ~$5/month for moderate usage  
**Agent Compatibility**: Any environment with Bun/Node.js

## Next Steps

- Combine with MCP for persistent memory
- Build voice interface (Termux API + TTS)
- Create web UI for mobile browser access
- Integrate with Tasker for automation

**Official Docs**: https://docs.anthropic.com/claude/reference/getting-started-with-the-api
