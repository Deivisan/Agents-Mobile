# 🤖 OpenCode Integration - AI Agent Skill

## Overview
OpenCode is an open-source AI coding assistant that runs locally or via cloud providers. This skill teaches AI agents how to integrate OpenCode with Agents-Mobile for maximum productivity.

## Prerequisites
- Agents-Mobile installed
- Bun runtime available
- Terminal access (Termux/Desktop)

## Installation

### Method 1: Official Installer (Recommended)
```bash
# Install OpenCode globally
bun install -g opencode

# Verify installation
opencode --version
```

### Method 2: From Source
```bash
cd ~/.agents-mobile/tools
git clone https://github.com/continuedev/opencode.git
cd opencode
bun install
bun link

# Verify
opencode --version
```

## Configuration

### 1. Create Config File
OpenCode config location: `~/.opencode/config.json`

```bash
mkdir -p ~/.opencode
cat > ~/.opencode/config.json << 'EOFCONFIG'
{
  "models": [
    {
      "title": "Claude Sonnet 4.5",
      "provider": "anthropic",
      "model": "claude-sonnet-4-5-20250514",
      "apiKey": "YOUR_ANTHROPIC_API_KEY"
    },
    {
      "title": "Gemini 2.0 Flash",
      "provider": "google",
      "model": "gemini-2.0-flash-exp",
      "apiKey": "YOUR_GOOGLE_API_KEY"
    },
    {
      "title": "Grok Code (Free)",
      "provider": "grok",
      "model": "grok-code",
      "apiKey": "FREE_VIA_OPENCODE_ZEN"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Grok Code Autocomplete",
    "provider": "grok",
    "model": "grok-code"
  },
  "embeddingsProvider": {
    "provider": "transformers.js"
  },
  "defaultModel": "Claude Sonnet 4.5"
}
EOFCONFIG
```

### 2. Add to Shell Aliases
Add to `~/.zshrc` or `~/.bashrc`:

```bash
# OpenCode aliases
alias code='opencode'
alias oc='opencode'
alias ai='opencode chat'
alias autocomplete='opencode autocomplete'
```

## Usage Patterns

### Basic Chat
```bash
# Start interactive chat
opencode chat "How do I optimize this Bun server?"

# Ask about file
opencode chat --file server.ts "Explain this code"

# Multi-file context
opencode chat --file src/*.ts "Find bugs in these files"
```

### Code Generation
```bash
# Generate function
opencode gen "Create a Bun HTTP server with WebSocket support"

# Generate tests
opencode gen --file api.ts "Write unit tests for this module"

# Generate docs
opencode gen --file utils.ts "Add JSDoc comments"
```

### Code Editing
```bash
# Refactor code
opencode edit server.ts "Refactor to use async/await"

# Fix bugs
opencode edit app.ts "Fix the memory leak"

# Optimize performance
opencode edit --all "Optimize for Bun runtime"
```

### Tab Autocomplete (Terminal)
```bash
# Enable autocomplete in current session
eval "$(opencode autocomplete init)"

# Add to shell RC for persistence
opencode autocomplete init >> ~/.zshrc
```

## Integration with Agents-Mobile

### 1. As Development Assistant
```bash
# Navigate to project
cd ~/.agents-mobile

# Ask OpenCode for help
opencode chat "How can I improve the install script?"

# Generate new skill
opencode gen "Create a skill for Docker integration"
```

### 2. Automated Code Review
```bash
# Review before commit
git diff | opencode chat "Review these changes"

# Check for security issues
opencode chat --file setup/*.sh "Find security vulnerabilities"
```

### 3. Documentation Generation
```bash
# Generate README sections
opencode gen "Create installation guide for this project"

# Update existing docs
opencode edit docs/agents.md "Add examples for each MCP"
```

## Advanced Features

### Custom Model Endpoints
For self-hosted models (Ollama, LM Studio):

```json
{
  "models": [
    {
      "title": "Local Qwen 2.5 Coder",
      "provider": "ollama",
      "model": "qwen2.5-coder:32b",
      "apiBase": "http://localhost:11434"
    }
  ]
}
```

### Context Providers
Enhance OpenCode with external context:

```json
{
  "contextProviders": [
    {
      "name": "codebase",
      "params": {
        "nRetrieve": 25,
        "nFinal": 5
      }
    },
    {
      "name": "diff",
      "params": {}
    },
    {
      "name": "terminal",
      "params": {}
    },
    {
      "name": "problems",
      "params": {}
    }
  ]
}
```

### Slash Commands
OpenCode supports powerful slash commands:

```
/edit    - Edit selected code
/comment - Add comments to code
/share   - Share conversation
/cmd     - Run terminal command
/http    - Make HTTP request
```

## Mobile-Specific Optimizations

### Reduce Memory Usage
```json
{
  "experimental": {
    "modelContextProtocolServers": {
      "enabled": false
    }
  },
  "analytics": {
    "enabled": false
  }
}
```

### Use Lighter Models
For mobile devices, prefer smaller models:
- `grok-code` (free, fast)
- `gemini-2.0-flash-exp` (excellent quality/speed)
- `claude-haiku` (cheapest Claude)

### Offline Mode
With Ollama on device:
```bash
# Install Ollama (if rooted Android)
termux-chroot
pacman -S ollama

# Pull model
ollama pull qwen2.5-coder:7b

# Configure OpenCode
opencode config set model ollama/qwen2.5-coder:7b
```

## Troubleshooting

### Issue: Command Not Found
```bash
# Verify Bun is in PATH
which bun

# Reinstall OpenCode
bun install -g opencode

# Check global bin directory
bun pm bin -g
```

### Issue: API Key Errors
```bash
# Test API key
curl -H "Authorization: Bearer YOUR_KEY" \
  https://api.anthropic.com/v1/models

# Set via environment variable (temporary)
export ANTHROPIC_API_KEY="your-key-here"
```

### Issue: Slow Performance
```bash
# Use streaming responses
opencode config set streaming true

# Reduce context window
opencode config set maxTokens 4096

# Switch to faster model
opencode config set model gemini-2.0-flash-exp
```

## Integration with Other Skills

### Combined with MCP Builder
```bash
# Generate MCP server with OpenCode
opencode gen "Create MCP server for YouTube downloads"

# Review generated code
opencode chat --file server.ts "Is this MCP spec compliant?"
```

### Combined with Mobile Debug
```bash
# Ask for thermal optimization
opencode chat "How to reduce CPU usage in this Bun app?"

# Generate watchdog script
opencode gen "Create temperature monitoring script"
```

## Best Practices

### 1. Use Context Wisely
```bash
# Bad: Too much context
opencode chat --file src/**/*.ts "Find bugs"

# Good: Targeted context
opencode chat --file src/server.ts "Check error handling"
```

### 2. Iterate Incrementally
```bash
# Step 1: Plan
opencode chat "How should I structure this API?"

# Step 2: Generate
opencode gen "Create API structure from plan"

# Step 3: Refine
opencode edit api.ts "Add error handling"
```

### 3. Leverage Codebase Search
```bash
# Find similar patterns
opencode chat "@codebase How are errors handled in other files?"

# Reference documentation
opencode chat "@docs What's the Bun HTTP server API?"
```

## Resources

- **Official Docs**: https://docs.opencode.dev
- **GitHub**: https://github.com/continuedev/opencode
- **Discord Community**: https://discord.gg/opencode
- **Model Providers**:
  - Anthropic (Claude): https://console.anthropic.com
  - Google (Gemini): https://ai.google.dev
  - OpenRouter (Multi-model): https://openrouter.ai

## Agent Instructions

When using this skill:

1. ✅ **Read existing code** before generating new code
2. ✅ **Test suggestions** before applying them
3. ✅ **Use streaming** for real-time feedback
4. ✅ **Leverage context providers** (@codebase, @terminal, @diff)
5. ✅ **Iterate incrementally** - don't generate everything at once
6. ❌ **Don't overwrite** without confirmation
7. ❌ **Don't use large contexts** on mobile (>10 files)
8. ❌ **Don't ignore errors** - fix them immediately

## Success Metrics

- ✅ OpenCode responds to queries
- ✅ Code generation works for simple tasks
- ✅ Autocomplete provides relevant suggestions
- ✅ Integration with Agents-Mobile aliases works
- ✅ Performance is acceptable on mobile device

---

**Skill Level**: Intermediate  
**Estimated Setup Time**: 10-15 minutes  
**Mobile Compatible**: ✅ Yes  
**Requires Root**: ❌ No
