#!/bin/bash

# Enhanced hook with queue system integration
# Manages workflow transitions and updates task queues
# Now includes GitHub/Atlassian integration support

set -euo pipefail

# Initialize queue manager
QUEUE_MANAGER=".claude/queues/queue_manager.sh"

# Read the subagent output from stdin
SUBAGENT_OUTPUT=$(cat)

# Parse subagent name and status from the output
SUBAGENT_NAME=""
SUBAGENT_STATUS=""

# Extract agent information from output
# Extended to include integration statuses
if echo "$SUBAGENT_OUTPUT" | grep -q "READY_FOR_DEVELOPMENT"; then
    SUBAGENT_NAME="requirements-analyst"
    SUBAGENT_STATUS="READY_FOR_DEVELOPMENT"
elif echo "$SUBAGENT_OUTPUT" | grep -q "READY_FOR_IMPLEMENTATION"; then
    SUBAGENT_NAME="architect"
    SUBAGENT_STATUS="READY_FOR_IMPLEMENTATION"
elif echo "$SUBAGENT_OUTPUT" | grep -q "READY_FOR_TESTING"; then
    SUBAGENT_NAME="implementer"
    SUBAGENT_STATUS="READY_FOR_TESTING"
elif echo "$SUBAGENT_OUTPUT" | grep -q "TESTING_COMPLETE"; then
    SUBAGENT_NAME="tester"
    SUBAGENT_STATUS="TESTING_COMPLETE"
elif echo "$SUBAGENT_OUTPUT" | grep -q "DOCUMENTATION_COMPLETE"; then
    SUBAGENT_NAME="documenter"
    SUBAGENT_STATUS="DOCUMENTATION_COMPLETE"
elif echo "$SUBAGENT_OUTPUT" | grep -q "INTEGRATION_COMPLETE"; then
    SUBAGENT_NAME="integration-coordinator"
    SUBAGENT_STATUS="INTEGRATION_COMPLETE"
elif echo "$SUBAGENT_OUTPUT" | grep -q "INTEGRATION_FAILED"; then
    SUBAGENT_NAME="integration-coordinator"
    SUBAGENT_STATUS="INTEGRATION_FAILED"
fi

echo "=== AGENT WORKFLOW TRANSITION ==="
echo "Completed Agent: $SUBAGENT_NAME"
echo "Status: $SUBAGENT_STATUS"
echo

# Update queue system if agent and status detected
if [ -n "$SUBAGENT_NAME" ] && [ -n "$SUBAGENT_STATUS" ] && [ -x "$QUEUE_MANAGER" ]; then
    # Find and complete the current task for this agent
    CURRENT_TASK_ID=$(jq -r ".active_workflows[] | select(.assigned_agent == \"$SUBAGENT_NAME\") | .id" .claude/queues/task_queue.json 2>/dev/null | head -n 1)

    if [ -n "$CURRENT_TASK_ID" ] && [ "$CURRENT_TASK_ID" != "null" ]; then
        "$QUEUE_MANAGER" complete "$CURRENT_TASK_ID" "$SUBAGENT_STATUS"
        echo "📋 Updated task queue: Completed task $CURRENT_TASK_ID"
    fi
fi

# Function to check if integration is needed
needs_integration() {
    local status="$1"
    case "$status" in
        "READY_FOR_DEVELOPMENT"|"READY_FOR_IMPLEMENTATION"|"READY_FOR_TESTING"|"TESTING_COMPLETE"|"DOCUMENTATION_COMPLETE")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to prompt for integration
prompt_integration() {
    local status="$1"
    local source_file="$2"

    # Check AUTO_INTEGRATE environment variable
    local auto_integrate="${AUTO_INTEGRATE:-prompt}"

    case "$auto_integrate" in
        "always")
            echo "🔗 Auto-integration enabled (always mode)"
            return 0
            ;;
        "never")
            echo "ℹ️  Auto-integration disabled (never mode)"
            return 1
            ;;
        *)
            echo ""
            echo "🔗 This status may require integration with external systems:"
            echo "   Status: $status"
            echo "   This would create GitHub issues, Jira tickets, or update documentation."
            echo ""
            echo -n "Create integration task? [y/N]: "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                return 0
            else
                return 1
            fi
            ;;
    esac
}

# Determine next steps and queue follow-up tasks
case "$SUBAGENT_STATUS" in
    "READY_FOR_DEVELOPMENT")
        echo "✅ Requirements analysis complete"

        # Check if integration is needed
        if needs_integration "$SUBAGENT_STATUS"; then
            # Try to find the source file from the completed task
            SOURCE_FILE=$(jq -r ".completed_tasks[-1] | select(.assigned_agent == \"$SUBAGENT_NAME\") | .source_file" .claude/queues/task_queue.json 2>/dev/null)

            if [ -n "$SOURCE_FILE" ] && [ "$SOURCE_FILE" != "null" ]; then
                if prompt_integration "$SUBAGENT_STATUS" "$SOURCE_FILE"; then
                    if [ -x "$QUEUE_MANAGER" ]; then
                        "$QUEUE_MANAGER" add-integration \
                            "$SUBAGENT_STATUS" \
                            "$SOURCE_FILE" \
                            "$SUBAGENT_NAME" \
                            "$CURRENT_TASK_ID"
                        echo "🔗 Integration task created for GitHub/Jira"
                    fi
                fi
            fi
        fi

        echo ""
        echo "📋 Next: Architecture and design phase"
        echo
        echo "Suggested next steps:"
        echo "  • Use 'architect' agent for technical design"
        echo "  • Or manually create architecture task with queue_manager.sh"
        ;;

    "READY_FOR_IMPLEMENTATION")
        echo "✅ Architecture design complete"

        # Check if integration is needed
        if needs_integration "$SUBAGENT_STATUS"; then
            SOURCE_FILE=$(jq -r ".completed_tasks[-1] | select(.assigned_agent == \"$SUBAGENT_NAME\") | .source_file" .claude/queues/task_queue.json 2>/dev/null)

            if [ -n "$SOURCE_FILE" ] && [ "$SOURCE_FILE" != "null" ]; then
                if prompt_integration "$SUBAGENT_STATUS" "$SOURCE_FILE"; then
                    if [ -x "$QUEUE_MANAGER" ]; then
                        "$QUEUE_MANAGER" add-integration \
                            "$SUBAGENT_STATUS" \
                            "$SOURCE_FILE" \
                            "$SUBAGENT_NAME" \
                            "$CURRENT_TASK_ID"
                        echo "🔗 Integration task created to update GitHub/Jira status"
                    fi
                fi
            fi
        fi

        echo "🔨 Next: Implementation phase"
        echo
        echo "Suggested next steps:"
        echo "  • Use 'implementer' agent to write the code"
        echo "  • Or manually create implementation task with queue_manager.sh"
        ;;

    "READY_FOR_TESTING")
        echo "✅ Implementation complete"

        # Check if integration is needed (create PR)
        if needs_integration "$SUBAGENT_STATUS"; then
            SOURCE_FILE=$(jq -r ".completed_tasks[-1] | select(.assigned_agent == \"$SUBAGENT_NAME\") | .source_file" .claude/queues/task_queue.json 2>/dev/null)

            if [ -n "$SOURCE_FILE" ] && [ "$SOURCE_FILE" != "null" ]; then
                if prompt_integration "$SUBAGENT_STATUS" "$SOURCE_FILE"; then
                    if [ -x "$QUEUE_MANAGER" ]; then
                        "$QUEUE_MANAGER" add-integration \
                            "$SUBAGENT_STATUS" \
                            "$SOURCE_FILE" \
                            "$SUBAGENT_NAME" \
                            "$CURRENT_TASK_ID"
                        echo "🔗 Integration task created to create GitHub PR"
                    fi
                fi
            fi
        fi

        echo "🧪 Next: Run comprehensive testing"
        echo
        echo "Suggested next steps:"
        echo "  • Use 'tester' agent for comprehensive testing"
        echo "  • Or manually create testing task with queue_manager.sh"
        ;;

    "TESTING_COMPLETE")
        echo "✅ All testing complete"

        # Check if integration is needed (post test results)
        if needs_integration "$SUBAGENT_STATUS"; then
            SOURCE_FILE=$(jq -r ".completed_tasks[-1] | select(.assigned_agent == \"$SUBAGENT_NAME\") | .source_file" .claude/queues/task_queue.json 2>/dev/null)

            if [ -n "$SOURCE_FILE" ] && [ "$SOURCE_FILE" != "null" ]; then
                if prompt_integration "$SUBAGENT_STATUS" "$SOURCE_FILE"; then
                    if [ -x "$QUEUE_MANAGER" ]; then
                        "$QUEUE_MANAGER" add-integration \
                            "$SUBAGENT_STATUS" \
                            "$SOURCE_FILE" \
                            "$SUBAGENT_NAME" \
                            "$CURRENT_TASK_ID"
                        echo "🔗 Integration task created to post test results"
                    fi
                fi
            fi
        fi

        echo "🎉 Ready for deployment/release"
        echo
        echo "📚 Optional: Create documentation"
        if [ -x "$QUEUE_MANAGER" ]; then
            echo -n "Queue documentation task? [y/N]: "
            read -r doc_response
            if [[ "$doc_response" =~ ^[Yy]$ ]]; then
                DOC_TASK_ID=$("$QUEUE_MANAGER" add "Create documentation" "documenter" "low" "documentation" "enhancements/current/tester/test_summary.md" "Document feature for users and developers")
                echo "📚 Documentation task queued: $DOC_TASK_ID"
            else
                echo "Skipping documentation - proceeding to final status"
            fi
            echo
            echo "Project Status: READY_FOR_RELEASE"
            echo "📊 Final Queue Status:"
            "$QUEUE_MANAGER" status
        fi
        ;;

    "DOCUMENTATION_COMPLETE")
        echo "✅ Documentation complete"

        # Check if integration is needed (publish to Confluence)
        if needs_integration "$SUBAGENT_STATUS"; then
            SOURCE_FILE=$(jq -r ".completed_tasks[-1] | select(.assigned_agent == \"$SUBAGENT_NAME\") | .source_file" .claude/queues/task_queue.json 2>/dev/null)

            if [ -n "$SOURCE_FILE" ] && [ "$SOURCE_FILE" != "null" ]; then
                if prompt_integration "$SUBAGENT_STATUS" "$SOURCE_FILE"; then
                    if [ -x "$QUEUE_MANAGER" ]; then
                        "$QUEUE_MANAGER" add-integration \
                            "$SUBAGENT_STATUS" \
                            "$SOURCE_FILE" \
                            "$SUBAGENT_NAME" \
                            "$CURRENT_TASK_ID"
                        echo "🔗 Integration task created to publish documentation"
                    fi
                fi
            fi
        fi

        echo "🎉 Feature development complete!"
        echo
        echo "Project Status: COMPLETE"
        if [ -x "$QUEUE_MANAGER" ]; then
            echo "📊 Final Queue Status:"
            "$QUEUE_MANAGER" status
        fi
        ;;

    "INTEGRATION_COMPLETE")
        echo "✅ External system integration complete"

        # Get integration details from the completed task
        TASK_DETAILS=$(jq -r ".completed_tasks[-1] | select(.assigned_agent == \"integration-coordinator\")" .claude/queues/task_queue.json 2>/dev/null)

        if [ -n "$TASK_DETAILS" ]; then
            PARENT_TASK=$(echo "$TASK_DETAILS" | jq -r '.metadata.parent_task_id // empty')
            WORKFLOW_STATUS=$(echo "$TASK_DETAILS" | jq -r '.metadata.workflow_status // empty')

            if [ -n "$PARENT_TASK" ] && [ "$PARENT_TASK" != "null" ]; then
                echo "📋 Integrated for workflow status: $WORKFLOW_STATUS"
                echo "🔗 Parent task: $PARENT_TASK"
            fi
        fi

        echo ""
        echo "Integration tasks update external systems:"
        echo "  • GitHub: Issues, PRs, labels"
        echo "  • Jira: Tickets, status updates"
        echo "  • Confluence: Documentation pages"
        echo ""
        echo "Continue with your normal development workflow."
        ;;

    "INTEGRATION_FAILED")
        echo "❌ Integration with external systems failed"
        echo ""
        echo "⚠️  Manual intervention required"
        echo ""
        echo "Check the integration log for details:"
        LOG_FILE=$(find enhancements/*/logs -name "integration-coordinator_*" -type f 2>/dev/null | tail -1)
        if [ -n "$LOG_FILE" ]; then
            echo "  Log: $LOG_FILE"
            echo ""
            echo "Common issues:"
            echo "  • API rate limits exceeded"
            echo "  • Authentication failures"
            echo "  • Missing configuration"
            echo ""
            echo "To retry:"
            echo "  .claude/queues/queue_manager.sh retry $CURRENT_TASK_ID"
        fi
        ;;

    *)
        echo "⚠️  Unknown status from subagent"
        echo "Manual intervention may be required"
        ;;
esac

# Show current queue status
if [ -x "$QUEUE_MANAGER" ]; then
    echo
    echo "📊 Current Queue Status:"
    "$QUEUE_MANAGER" status
fi

echo
echo "=== SUBAGENT OUTPUT ==="
echo "$SUBAGENT_OUTPUT"
echo "========================="