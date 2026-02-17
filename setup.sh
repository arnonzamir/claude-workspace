#!/bin/bash
set -e

echo "=== Claude Workspace Setup ==="

# ── Repos ────────────────────────────────────────────────────────────────────
mkdir -p ~/workspace
cd ~/workspace

REPOS=(
  "https://github.com/arnonzamir/collage-sports.git collage_sports"
  "https://github.com/arnonzamir/family-banking.git family-banking"
  "https://github.com/arnonzamir/mcp-dashboard.git mcp-dashboard"
  "https://github.com/arnonzamir/lifelists4.git mcp-server"
  "https://github.com/arnonzamir/raspotify-setup.git raspotify-setup"
  "https://github.com/arnonzamir/claude-workspace.git claude-workspace"
)

for entry in "${REPOS[@]}"; do
  url=$(echo "$entry" | cut -d' ' -f1)
  dir=$(echo "$entry" | cut -d' ' -f2)
  if [ -d "$dir/.git" ]; then
    echo "↻ $dir (already cloned, pulling)"
    git -C "$dir" pull --ff-only 2>/dev/null || echo "  (skipped, has local changes)"
  else
    echo "↓ Cloning $dir"
    git clone "$url" "$dir"
  fi
done

# ── MCP configs ───────────────────────────────────────────────────────────────
echo ""
echo "=== Setting up MCP configs ==="

# collage_sports uses coolify + cloudflare MCPs
cat > ~/workspace/collage_sports/.mcp.json << 'EOF'
{
  "mcpServers": {
    "cloudflare": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://docs.mcp.cloudflare.com/sse"
      ]
    },
    "coolify": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "@masonator/coolify-mcp@latest"
      ],
      "env": {
        "COOLIFY_BASE_URL": "https://cp.arnonzamir.co.il",
        "COOLIFY_ACCESS_TOKEN": "QjFGbopAQehJI5Fg4U3yS14GBOn0BXp6WhpJBqMl3bca3945"
      }
    }
  }
}
EOF
echo "✓ collage_sports/.mcp.json"

# Global Claude settings
mkdir -p ~/.claude
cat > ~/.claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash",
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep",
      "WebFetch",
      "WebSearch",
      "Task",
      "mcp__coolify__*",
      "mcp__claude_ai_Atlassian__*"
    ]
  }
}
EOF
echo "✓ ~/.claude/settings.json"

# ── npm install for repos that need it ───────────────────────────────────────
echo ""
echo "=== Installing dependencies ==="

for dir in mcp-server mcp-dashboard; do
  if [ -f ~/workspace/$dir/package.json ]; then
    echo "↓ npm install in $dir"
    (cd ~/workspace/$dir && npm install)
  fi
done

echo ""
echo "=== Done! ==="
echo "Repos cloned to ~/workspace/"
echo "Run 'claude' in any project directory to start working."
