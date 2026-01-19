---
name: MCP Builder
description: Create Model Context Protocol servers from scratch
when_to_use: When you need to save/load context, create persistent memory, or build custom tool protocols
difficulty: Advanced
requires: Bun runtime, basic TypeScript knowledge
---

# 🔧 MCP Builder Skill

This skill teaches AI agents how to create **MCP (Model Context Protocol) servers** from scratch.

## What is MCP?

MCP is a protocol for AI agents to:
- 💾 **Save context** across sessions (persistent memory)
- 🔧 **Expose tools** to other agents
- 🌐 **Share state** between multiple AI systems
- 📊 **Store structured data** (JSON, graphs, embeddings)

## Step-by-Step: Create an MCP Server

### 1. Initialize Project

```bash
# Create new Bun project
mkdir my-mcp-server
cd my-mcp-server
bun init -y

# Install MCP SDK
bun add @modelcontextprotocol/sdk
```

### 2. Create Server (`index.ts`)

```typescript
#!/usr/bin/env bun

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

// Create MCP server
const server = new Server(
  {
    name: "my-mcp-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "save_context",
        description: "Save context to persistent storage",
        inputSchema: {
          type: "object",
          properties: {
            key: { type: "string", description: "Context key" },
            value: { type: "string", description: "Context value" },
          },
          required: ["key", "value"],
        },
      },
      {
        name: "load_context",
        description: "Load context from storage",
        inputSchema: {
          type: "object",
          properties: {
            key: { type: "string", description: "Context key" },
          },
          required: ["key"],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "save_context") {
    // Save to file (or database)
    const filePath = `./storage/${args.key}.json`;
    await Bun.write(filePath, JSON.stringify(args.value, null, 2));
    return {
      content: [{ type: "text", text: `Saved context: ${args.key}` }],
    };
  }

  if (name === "load_context") {
    // Load from file
    const filePath = `./storage/${args.key}.json`;
    const file = Bun.file(filePath);
    const exists = await file.exists();
    
    if (!exists) {
      return {
        content: [{ type: "text", text: `Context not found: ${args.key}` }],
        isError: true,
      };
    }
    
    const data = await file.json();
    return {
      content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
    };
  }

  return {
    content: [{ type: "text", text: "Unknown tool" }],
    isError: true,
  };
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("MCP Server running on stdio");
}

main().catch(console.error);
```

### 3. Make Executable

```bash
chmod +x index.ts
mkdir -p storage
```

### 4. Test Locally

```bash
# Run server
bun run index.ts

# It should output: "MCP Server running on stdio"
```

### 5. Configure for AI Agents

Add to Claude Code / OpenCode config (`~/.config/opencode/opencode.jsonc`):

```json
{
  "mcpServers": {
    "my-mcp": {
      "command": "bun",
      "args": ["run", "/path/to/my-mcp-server/index.ts"]
    }
  }
}
```

## Advanced: Add More Tools

### Example: Search Tool

```typescript
{
  name: "search_context",
  description: "Search saved contexts by keyword",
  inputSchema: {
    type: "object",
    properties: {
      query: { type: "string" },
    },
    required: ["query"],
  },
}
```

Handler:

```typescript
if (name === "search_context") {
  const files = await readdir("./storage");
  const results = [];
  
  for (const file of files) {
    const data = await Bun.file(`./storage/${file}`).json();
    const content = JSON.stringify(data);
    
    if (content.includes(args.query)) {
      results.push({ file, data });
    }
  }
  
  return {
    content: [{ type: "text", text: JSON.stringify(results, null, 2) }],
  };
}
```

## Mobile-Specific: Save to SD Card

```typescript
// Android: Save to /sdcard/Agents-Mobile/mcp-storage
const STORAGE_DIR = "/sdcard/Agents-Mobile/mcp-storage";

// Create directory if needed
await mkdir(STORAGE_DIR, { recursive: true });

// Save
const filePath = `${STORAGE_DIR}/${args.key}.json`;
await Bun.write(filePath, JSON.stringify(args.value, null, 2));
```

## Use Cases

1. **Persistent Agent Memory**: Save conversations, learned facts, preferences
2. **Cross-Session Context**: Load previous work when resuming tasks
3. **Multi-Agent Coordination**: Share state between different AI agents
4. **Custom Tools**: Expose device-specific functions (camera, GPS, sensors)

## Testing

```bash
# Test save
echo '{"tool":"save_context","args":{"key":"test","value":"Hello World"}}' | bun run index.ts

# Test load
echo '{"tool":"load_context","args":{"key":"test"}}' | bun run index.ts
```

## Troubleshooting

- **"Module not found"**: Run `bun install` first
- **"Permission denied"**: Check write access to storage directory
- **Agent not detecting MCP**: Restart agent after config change

## Next Steps

- Add database support (SQLite, PostgreSQL)
- Implement vector embeddings for semantic search
- Add encryption for sensitive data
- Create web UI for management

---

**Skill Level**: Advanced  
**Estimated Time**: 30-60 minutes  
**Prerequisites**: Bun installed, basic TypeScript  
**Agent Compatibility**: Claude Code, OpenCode, Gemini CLI (with adapters)
