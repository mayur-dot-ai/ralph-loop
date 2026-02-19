#!/bin/bash
# ralph-wrapper.sh - Ralph Wiggum loop implementation for Developer Agent
# Takes GitHub issue #, spawns Developer in loop until completion or max iterations

ISSUE_NUM="${1}"
MAX_ITERATIONS="${2:-10}"
REPO="ClawSysMon-Pro"
ORG="mayur-dot-ai"

if [ -z "$ISSUE_NUM" ]; then
  echo "Usage: $0 <issue_number> [max_iterations]"
  echo "Example: $0 14 10"
  exit 1
fi

echo "🔄 Ralph Wiggum Loop: Issue #${ISSUE_NUM} (max ${MAX_ITERATIONS} iterations)"
echo "=================================================="

# Fetch issue details
ISSUE_DATA=$(python3 /home/ec2-user/github-mcp/github-wrapper.py issue-get "$ORG" "$REPO" "$ISSUE_NUM")
ISSUE_TITLE=$(echo "$ISSUE_DATA" | grep -o '"title":"[^"]*"' | cut -d'"' -f4)
ISSUE_BODY=$(echo "$ISSUE_DATA" | grep -o '"body":"[^"]*"' | cut -d'"' -f4 | head -c 500)

echo "📋 Issue: #${ISSUE_NUM} - ${ISSUE_TITLE}"
echo "📝 Spec: ${ISSUE_BODY}..."
echo ""

ITERATION=0
STATUS="INCOMPLETE"

while [ "$STATUS" = "INCOMPLETE" ] && [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; do
  ITERATION=$((ITERATION + 1))
  echo "🔄 Iteration $ITERATION/$MAX_ITERATIONS"
  
  # Build the task for Developer Agent
  TASK="# Task: Implement GitHub Issue #${ISSUE_NUM}

## Issue Details
Title: ${ISSUE_TITLE}

## Your Job
1. Read the full issue from GitHub: https://github.com/${ORG}/${REPO}/issues/${ISSUE_NUM}
   Use this command to get the issue:
   \`\`\`bash
   python3 /home/ec2-user/github-mcp/github-wrapper.py issue-get ${ORG} ${REPO} ${ISSUE_NUM}
   \`\`\`

2. Understand what needs to be built

3. Create the implementation:
   - Write the code/changes needed
   - Test locally if possible
   - Create/update files in the repo

4. Commit your changes:
   \`\`\`bash
   python3 /home/ec2-user/github-mcp/github-wrapper.py file-create-or-update \\
     ${ORG} ${REPO} <path> <content> \"fix: Issue #${ISSUE_NUM} - <your message>\"
   \`\`\`

5. If complete, output: IMPLEMENTATION_COMPLETE
6. If blocked, describe the issue and ask for help

## Context
This is iteration $ITERATION of $MAX_ITERATIONS. Previous context available in results.
If you already made progress, continue from where you left off."

  # Spawn Developer Agent
  echo "  └─ Spawning Developer Agent..."
  python3 /home/ec2-user/clawservants/developer/clawservant.py --task "$TASK" > /tmp/dev_output_${ITERATION}.json 2>&1
  
  # Check result
  RESULT=$(cat /tmp/dev_output_${ITERATION}.json 2>/dev/null | grep -o '"result":"[^"]*' | cut -d'"' -f4 | head -c 200)
  
  if echo "$RESULT" | grep -q "IMPLEMENTATION_COMPLETE"; then
    STATUS="COMPLETE"
    echo "  ✅ COMPLETE: Implementation finished!"
  else
    echo "  ⏳ Status: Work in progress"
    echo "  Output: ${RESULT:0:100}..."
  fi
  
  echo ""
done

echo "=================================================="
if [ "$STATUS" = "COMPLETE" ]; then
  echo "✅ SUCCESS: Issue #${ISSUE_NUM} implementation complete in $ITERATION iterations"
else
  echo "⚠️  MAX_ITERATIONS ($MAX_ITERATIONS) reached. Issue may need manual review."
fi