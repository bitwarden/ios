#!/bin/bash

# General hook that runs when any agent or command completes
# Provides project status and suggests next actions

set -euo pipefail

# Read output from stdin
OUTPUT=$(cat)

echo "=== PROJECT STATUS CHECK ==="

# Check current project state
PROJECT_STATUS="UNKNOWN"

# Look for common completion markers
if echo "$OUTPUT" | grep -q "TESTING_COMPLETE\|tests.*passed\|All tests passed"; then
    PROJECT_STATUS="READY_FOR_RELEASE"
elif echo "$OUTPUT" | grep -q "READY_FOR_TESTING\|implementation.*complete"; then
    PROJECT_STATUS="READY_FOR_TESTING"
elif echo "$OUTPUT" | grep -q "READY_FOR_DEVELOPMENT\|requirements.*complete"; then
    PROJECT_STATUS="READY_FOR_DEVELOPMENT"
elif echo "$OUTPUT" | grep -q "build.*successful\|Build completed"; then
    PROJECT_STATUS="BUILD_COMPLETE"
elif echo "$OUTPUT" | grep -q "error\|Error\|FAILED\|failed"; then
    PROJECT_STATUS="NEEDS_ATTENTION"
fi

echo "Current Status: $PROJECT_STATUS"
echo

# Provide contextual suggestions
case "$PROJECT_STATUS" in
    "READY_FOR_DEVELOPMENT")
        echo "🚀 Suggested Actions:"
        echo "  • Launch cpp-developer for C++ components"
        echo "  • Launch assembly-developer for 6502 kernel"
        echo "  • Consider parallel development for efficiency"
        ;;

    "READY_FOR_TESTING")
        echo "🧪 Suggested Actions:"
        echo "  • Launch testing-agent for comprehensive validation"
        echo "  • Run unit tests: cmake --build . --target test"
        echo "  • Validate assembly integration"
        ;;

    "BUILD_COMPLETE")
        echo "🔨 Build Status: Success"
        echo "  • Binary ready for testing"
        echo "  • Consider running test suite"
        ;;

    "NEEDS_ATTENTION")
        echo "⚠️  Issues Detected"
        echo "  • Review error messages above"
        echo "  • Fix compilation or runtime issues"
        echo "  • Re-run after corrections"
        ;;

    "READY_FOR_RELEASE")
        echo "✨ Project Complete!"
        echo "  • All components tested and validated"
        echo "  • Ready for deployment or distribution"
        ;;

    *)
        echo "📋 General Suggestions:"
        echo "  • Use requirements-analyst for new features"
        echo "  • Check build status: cmake --build ."
        echo "  • Run tests: ctest"
        ;;
esac

# Check for available agents
if [ -d ".claude/agents" ]; then
    echo
    echo "Available Agents:"
    for agent in .claude/agents/*.md; do
        if [ -f "$agent" ]; then
            agent_name=$(basename "$agent" .md)
            # Extract description more robustly, handling YAML frontmatter
            agent_desc=$(grep "^description:" "$agent" | sed -E 's/^description: *"?([^"]*)"?.*$/\1/' || echo "Agent description")
            echo "  • $agent_name: $agent_desc"
        fi
    done
fi

echo
echo "=== END STATUS CHECK ==="