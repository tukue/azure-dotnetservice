#!/usr/bin/env bash
set -euo pipefail

POLICIES_DIR="$(dirname "$0")/policies"
PLAN_FILE="${1:-tfplan.json}"

if [ ! -f "$PLAN_FILE" ]; then
  echo "Usage: $0 <terraform-plan-json>"
  echo "Generate plan JSON: terraform show -json tfplan > tfplan.json"
  exit 1
fi

echo "═══ OPA Policy Check ═══"

violations=0
for policy in "$POLICIES_DIR"/*.rego; do
  name="$(basename "$policy" .rego)"
  echo ""
  echo "── Checking: $name ──"

  result=$(opa eval \
    --data "$policy" \
    --input "$PLAN_FILE" \
    --format json \
    "data.terraform.$(echo "$name" | sed 's/^[^_]*_//' | tr '[:upper:]' '[:lower:]').deny" 2>/dev/null || true)

  if echo "$result" | grep -q '"result"'; then
    violations_found=$(echo "$result" | opa eval --stdin-input --format values "count(input.result)" 2>/dev/null || echo "0")
    if [ "$violations_found" -gt 0 ]; then
      violations=$((violations + violations_found))
      echo "$result" | opa eval --stdin-input --format pretty "input.result[_]" 2>/dev/null || true
    else
      echo "  ✓ Passed"
    fi
  else
    echo "  ✓ Passed"
  fi
done

echo ""
echo "═══ Results ═══"
if [ "$violations" -gt 0 ]; then
  echo "BLOCKING: $violations policy violation(s) found."
  exit 1
else
  echo "ALL POLICIES PASSED."
  exit 0
fi
