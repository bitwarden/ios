#!/bin/bash

# Generate agents.json from agent markdown files
# This script extracts YAML frontmatter from agent .md files and creates agents.json

set -euo pipefail

AGENTS_DIR=".claude/agents"
OUTPUT_FILE="$AGENTS_DIR/agents.json"

# Start JSON array
echo '{"agents":[' > "$OUTPUT_FILE"

first=true
for agent_file in "$AGENTS_DIR"/*.md; do
    [ -f "$agent_file" ] || continue

    # Extract YAML frontmatter
    if grep -q "^---$" "$agent_file"; then
        # Add comma between agents
        if [ "$first" = false ]; then
            echo ',' >> "$OUTPUT_FILE"
        fi
        first=false

        # Extract frontmatter and convert to JSON
        awk '/^---$/{f=!f;next} f' "$agent_file" | \
        python3 -c "
import sys, json, yaml
data = yaml.safe_load(sys.stdin)
json.dump(data, sys.stdout, indent=2)
" >> "$OUTPUT_FILE"
    fi
done

# Close JSON array
echo ']}' >> "$OUTPUT_FILE"

echo "✓ Generated $OUTPUT_FILE"
