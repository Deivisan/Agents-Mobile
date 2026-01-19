# 🤖 AI Agents Guide - Agents-Mobile

This document explains how to integrate different AI agents with Agents-Mobile.

---

## Supported AI Agents

| Agent | Provider | Best For | Cost | Mobile-Friendly |
|-------|----------|----------|------|-----------------|
| [Claude](#claude-anthropic) | Anthropic | Code, reasoning, long context | ~$5/mo | ✅ Excellent |
| [Gemini CLI](#gemini-google) | Google | Free tier, fast responses | Free | ✅ Excellent |
| [OpenCode](#opencode) | Self-hosted | Privacy, offline mode | Free | ✅ Good |
| [ChatGPT](#chatgpt-openai) | OpenAI | General purpose | ~$10/mo | ⚠️ Moderate |
| [Ollama](#ollama-local) | Local | Fully offline, privacy | Free | ⚠️ Limited (RAM) |

---

## Claude (Anthropic)

**Best choice for**: Code generation, debugging, complex reasoning

### Installation

```bash
# Using Bun
bun add @anthropic-ai/sdk

# Or use community CLI
bun install -g claude-cli
```

### Configuration

```bash
# Get API key from: https://console.anthropic.com
export ANTHROPIC_API_KEY="sk-ant-your-key-here"

# Add to ~/.bashrc
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
```

### Quick Start

```bash
# Test connection
bun -e "
import Anthropic from '@anthropic-ai/sdk';
const client = new Anthropic();
const msg = await client.messages.create({
  model: 'claude-sonnet-4',
  max_tokens: 100,
  messages: [{ role: 'user', content: 'Hello!' }]
});
console.log(msg.content[0].text);
"
```

### Mobile Optimization

- Use **Claude Haiku** for simple tasks (10x cheaper)
- Cache responses to `/sdcard/Agents-Mobile/cache`
- Reduce `max_tokens` to 1024 on low battery
- Use streaming for better UX

**See**: [skills/claude-code.md](../skills/claude-code.md) for full guide

---

## Gemini CLI (Google)

**Best choice for**: Free tier, experiments, learning

### Installation

```bash
# Install Gemini CLI
bun install -g gemini-cli

# Or use official SDK
bun add @google/generative-ai
```

### Configuration

```bash
# Get API key from: https://makersuite.google.com/app/apikey
export GEMINI_API_KEY="your-key-here"

# Add to ~/.bashrc
echo 'export GEMINI_API_KEY="..."' >> ~/.bashrc
```

### Quick Start

```bash
# Using Gemini CLI
gemini "What is Bun runtime?"

# Using SDK
bun -e "
import { GoogleGenerativeAI } from '@google/generative-ai';
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-exp' });
const result = await model.generateContent('Hello!');
console.log(result.response.text());
"
```

### Mobile Optimization

- **Free tier**: 15 requests/minute, 1500/day
- Very fast responses (< 2s)
- Low battery drain
- Good for quick queries

---

## OpenCode

**Best choice for**: Privacy, self-hosted, offline work

### Installation

```bash
# Follow official guide
curl -fsSL https://opencode.dev/install.sh | bash

# Or manual install
git clone https://github.com/opencode/opencode.git
cd opencode
bun install
bun run build
```

### Configuration

```json
// ~/.config/opencode/opencode.jsonc
{
  "ai": {
    "provider": "anthropic",  // or "openai", "google"
    "model": "claude-sonnet-4",
    "apiKey": "your-key"
  },
  "mcpServers": {
    "agents-mobile": {
      "command": "bun",
      "args": ["run", "/sdcard/Agents-Mobile/mcp-server/index.ts"]
    }
  }
}
```

### Quick Start

```bash
# Start OpenCode
opencode

# Inside editor, use Cmd+K (or Ctrl+K) for AI chat
```

### Mobile Optimization

- Runs in Termux with X11 or SSH
- Can use local models via Ollama
- Supports MCP for persistent context
- Touch-friendly with on-screen keyboard

---

## ChatGPT (OpenAI)

**Best choice for**: General conversation, creative tasks

### Installation

```bash
# Official SDK
bun add openai

# Community CLI
bun install -g chatgpt-cli
```

### Configuration

```bash
# Get API key from: https://platform.openai.com/api-keys
export OPENAI_API_KEY="sk-proj-your-key"
```

### Quick Start

```bash
bun -e "
import OpenAI from 'openai';
const openai = new OpenAI();
const completion = await openai.chat.completions.create({
  model: 'gpt-4-turbo',
  messages: [{ role: 'user', content: 'Hello!' }]
});
console.log(completion.choices[0].message.content);
"
```

### Mobile Considerations

- **Cost**: Higher than Claude/Gemini (~$10/mo)
- **Speed**: Moderate (3-5s response time)
- **Battery**: Higher drain than Gemini
- **Rate limits**: 500 RPM on paid tier

---

## Ollama (Local Models)

**Best choice for**: Offline mode, privacy, no API costs

### Installation

```bash
# Requires ARM64 build
curl -fsSL https://ollama.com/install.sh | sh

# Or build from source
git clone https://github.com/ollama/ollama.git
cd ollama
go build
```

### Models for Mobile

| Model | Size | RAM Required | Speed |
|-------|------|--------------|-------|
| Phi-3-mini | 2.3GB | 4GB | Fast |
| TinyLlama | 637MB | 2GB | Very Fast |
| Gemma-2B | 1.4GB | 3GB | Fast |
| Llama-3.2-1B | 1.3GB | 3GB | Fast |

**Avoid**: Llama-70B, Mixtral (too large for mobile)

### Quick Start

```bash
# Pull model
ollama pull phi3

# Run query
ollama run phi3 "Explain how chroot works"

# Using API
curl http://localhost:11434/api/generate -d '{
  "model": "phi3",
  "prompt": "Hello!"
}'
```

### Mobile Optimization

- Use **quantized models** (Q4_0 or smaller)
- Limit context to 2048 tokens max
- Offload to GPU if supported (experimental)
- Stop model when idle to save battery

**Note**: Ollama on mobile is **experimental** - expect crashes on low RAM devices.

---

## Comparison Table

| Feature | Claude | Gemini | OpenCode | ChatGPT | Ollama |
|---------|--------|--------|----------|---------|--------|
| **Free Tier** | No | Yes | Yes | No | Yes |
| **Cost/month** | ~$5 | Free | Free | ~$10 | Free |
| **Offline** | No | No | Partial | No | Yes |
| **Speed** | Fast | Very Fast | Varies | Moderate | Fast |
| **Code Quality** | Excellent | Good | Varies | Good | Moderate |
| **Battery Drain** | Low | Very Low | Low | Moderate | High |
| **RAM Usage** | <100MB | <50MB | ~200MB | <100MB | 2-4GB |
| **MCP Support** | Yes | No | Yes | No | No |

---

## Skills Integration

All agents can read and execute **Agents-Mobile skills**:

```bash
# Load skill into agent context
SKILL=$(cat skills/mcp-builder.md)

# Claude example
claude "Context: $SKILL\n\nTask: Create MCP server for notes"

# Gemini example
gemini "$SKILL\n\nBuild a note-taking MCP"
```

**Available Skills**:
- [mcp-builder.md](../skills/mcp-builder.md) - Create MCP servers
- [mobile-debug.md](../skills/mobile-debug.md) - Optimize mobile performance
- [claude-code.md](../skills/claude-code.md) - Claude integration
- [bun-optimizer.md](../skills/bun-optimizer.md) - Bun performance (coming soon)

---

## Multi-Agent Workflows

Combine agents for best results:

```bash
#!/bin/bash
# Use Gemini for fast queries, Claude for complex code

QUERY="$1"

if [[ ${#QUERY} -lt 100 ]]; then
    # Short query → Gemini (free, fast)
    gemini "$QUERY"
else
    # Long query → Claude (better reasoning)
    claude "$QUERY"
fi
```

---

## Battery-Aware Agent Switching

```bash
#!/bin/bash
# Switch agents based on battery level

BATTERY=$(termux-battery-status | jq -r '.percentage')

if [[ $BATTERY -lt 30 ]]; then
    echo "🔋 Low battery - using Ollama (offline)"
    ollama run tinyllama "$1"
elif [[ $BATTERY -lt 60 ]]; then
    echo "🔋 Medium battery - using Gemini (free, fast)"
    gemini "$1"
else
    echo "✅ Full battery - using Claude (best quality)"
    claude "$1"
fi
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "API key invalid" | Check env var: `echo $ANTHROPIC_API_KEY` |
| "Rate limit exceeded" | Wait 60s or switch to different agent |
| "Out of memory" | Use smaller model (Gemini/Haiku vs GPT-4) |
| "Network timeout" | Check mobile data, increase timeout to 60s |
| "Agent not found" | Verify installation: `which claude` |

---

## Next Steps

1. Pick an agent based on your needs (see comparison table)
2. Install using instructions above
3. Test with simple query
4. Load skills from `skills/` folder
5. Explore MCP integration for persistent memory

**Need help?** Open an issue: https://github.com/Deivisan/Agents-Mobile/issues
