#!/bin/bash

PROJECT_PATH="Bitwarden.xcodeproj"
TEST_PLAN_UNIT_PATH="TestPlans/TestPlan-Unit.xctestplan"
TEST_PLAN_SNAPSHOT_PATH="TestPlans/TestPlan-Snapshot.xctestplan"
SNAPSHOT_TESTS_TARGET="BitwardenSharedTests"

mint install atakankarsli/xctestplanner@v1.0.9

echo "🧱 Getting test files and adding test to plans if needed..."
echo "--------"

TEST_FILES=$(find ./BitwardenShared -name '*Tests*' -type f)
if [ -z "$TEST_FILES" ]; then
  echo "ℹ️ No test files found."
  exit 1
fi

for FILE in $TEST_FILES; do
    # Get the tests that start with "test_snapshot_"
    TESTS=$(grep -E '^\s*func\s+test_snapshot_' $FILE | awk '{print $2}' | awk -F'(' '{print $1}')
    if [ -z "$TESTS" ]; then
        continue
    fi

    for TEST in $TESTS; do
        # Get the class name, there are some classes with "final" applied so we need to check that as well
        # to get the correct class name.
        CLASS_NAME=$(grep -B 5000 "func $TEST" $FILE | grep "class " | tail -n 1 | awk '{print $2}' | awk -F':' '{print $1}')
        if [[ "$CLASS_NAME" == "class" ]]; then
            CLASS_NAME=$(grep -B 5000 "func $TEST" $FILE | grep "final class " | tail -n 1 | awk '{print $3}' | awk -F':' '{print $1}')
        fi
        
        ENTRY_PATTERN_TO_CHECK_IF_EXISTS="${CLASS_NAME}.*${TEST}()"
        ENTRY="${CLASS_NAME}/${TEST}()"

        # Select snapshot tests in the Snapshot test plan.
        if ! grep -qE $ENTRY_PATTERN_TO_CHECK_IF_EXISTS $TEST_PLAN_SNAPSHOT_PATH; then
            mint run atakankarsli/xctestplanner@v1.0.9 select $ENTRY -f $TEST_PLAN_SNAPSHOT_PATH
            echo "🧪 $ENTRY added to selected tests in snapshot test plan."
        fi

        # Skip snapshot tests in the Unit test plan.
        if ! grep -qE $ENTRY_PATTERN_TO_CHECK_IF_EXISTS $TEST_PLAN_UNIT_PATH; then
            mint run atakankarsli/xctestplanner@v1.0.9 skip $ENTRY -f $TEST_PLAN_UNIT_PATH
            echo "🧪 $ENTRY added to skipped tests in unit test plan."
        fi
    done
done

# WORKAROUND: Currently, there is no way to select/skip test per target so they are being added to all targets
# so we need to remove them from all the targets except "BitwardenSharedTests" in the Unit test plans.
TEMP_OUTPUT_FILE="TestPlans/TestPlan-UnitTemp.xctestplan"

jq '(.testTargets[]) |= if .target.name != "BitwardenSharedTests" then del(.skippedTests) else . end' "$TEST_PLAN_UNIT_PATH" > "$TEMP_OUTPUT_FILE"

mv "$TEMP_OUTPUT_FILE" "$TEST_PLAN_UNIT_PATH"

echo "🧱 Tests added successfully."
