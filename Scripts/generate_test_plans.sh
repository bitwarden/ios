#!/bin/bash

PROJECT_PATH="Bitwarden.xcodeproj"
TEST_PLAN_UNIT_PATH="TestPlans/TestPlan-Unit.xctestplan"
TEST_PLAN_SNAPSHOT_PATH="TestPlans/TestPlan-Snapshot.xctestplan"
TEST_PLAN_INSPECTOR_PATH="TestPlans/TestPlan-ViewInspector.xctestplan"
SNAPSHOT_TESTS_TARGET="BitwardenSharedTests"

start_time=$SECONDS

mint install atakankarsli/xctestplanner@v1.0.9

echo "🧱 Getting test files and adding test to plans if needed..."
echo "--------"

handle_test_in_plans() {
    local CLASS_NAME=$1
    local TEST=$2
    local INCLUDE_PLAN_PATH=$3

    ENTRY_PATTERN_TO_CHECK_IF_EXISTS="${CLASS_NAME}.*${TEST}()"
    ENTRY="${CLASS_NAME}/${TEST}()"

    echo $ENTRY

    # Select snapshot tests in the Snapshot test plan.
    if ! grep -qE $ENTRY_PATTERN_TO_CHECK_IF_EXISTS $INCLUDE_PLAN_PATH; then
        mint run atakankarsli/xctestplanner@v1.0.9 select $ENTRY -f $INCLUDE_PLAN_PATH
        echo "🧪 $ENTRY added to selected tests in snapshot test plan."
    fi

    # Skip snapshot tests in the Unit test plan.
    if ! grep -qE $ENTRY_PATTERN_TO_CHECK_IF_EXISTS $TEST_PLAN_UNIT_PATH; then
        mint run atakankarsli/xctestplanner@v1.0.9 skip $ENTRY -f $TEST_PLAN_UNIT_PATH
        echo "🧪 $ENTRY added to skipped tests in unit test plan."
    fi
}


TEST_FILES=$(find ./BitwardenShared -name '*Tests*' -type f)
if [ -z "$TEST_FILES" ]; then
  echo "ℹ️ No test files found."
  exit 1
fi

for FILE in $TEST_FILES; do
    # Extract class name
    class_name=$(grep -E "class [A-Za-z0-9_]+Tests" "$FILE" | \
        sed -E 's/.*class ([A-Za-z0-9_]+).*/\1/' | head -1)

    if [ -z "$class_name" ]; then
        continue
    fi
    
    # Find all test methods
    grep -n "func test" "$FILE" | while IFS=: read line_num line_content; do
        method_name=$(echo "$line_content" | sed -E 's/.*func (test[A-Za-z0-9_]*).*/\1/')
        
        # Check if it's a snapshot test
        if [[ "$method_name" =~ ^test_snapshot_ ]]; then
            echo "🔍 Found snapshot test method: $class_name/$method_name"
            handle_test_in_plans "$class_name" "$method_name" "$TEST_PLAN_SNAPSHOT_PATH"
        else
            # Extract the function body to check for .inspect()
            # Get all lines from this test method to the next method or end of class
            function_body=$(awk -v start="$line_num" '
                NR >= start {
                    print
                    # Count braces
                    for (i = 1; i <= length($0); i++) {
                        char = substr($0, i, 1)
                        if (char == "{") brace_count++
                        if (char == "}") brace_count--
                    }
                    # Exit when we close the function (back to 0)
                    if (brace_count == 0 && NR > start) exit
                }
            ' "$FILE")
            
            # Check if function body contains .inspect()
            if echo "$function_body" | grep -q "\.inspect()"; then
                 echo "🔍 Found inspect test method: $class_name/$method_name"
                handle_test_in_plans "$class_name" "$method_name" "$TEST_PLAN_INSPECTOR_PATH"
            fi
        fi
    done
done

# WORKAROUND: Currently, there is no way to select/skip test per target so they are being added to all targets
# so we need to remove them from all the targets except "BitwardenSharedTests" in the Unit test plans.
TEMP_OUTPUT_FILE="TestPlans/TestPlan-UnitTemp.xctestplan"

jq '(.testTargets[]) |= if .target.name != "BitwardenSharedTests" then del(.skippedTests) else . end' "$TEST_PLAN_UNIT_PATH" > "$TEMP_OUTPUT_FILE"

mv "$TEMP_OUTPUT_FILE" "$TEST_PLAN_UNIT_PATH"

echo "🧱 Tests added successfully."

duration=$SECONDS
echo "✅ Completed in $duration seconds"