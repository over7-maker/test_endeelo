#!/bin/bash
# Update All Workflows with 21 API Keys
# This script verifies that all workflows have the complete set of 21 API keys

echo "🚀 Checking workflow configurations..."
echo ""

# List of all 21 required API keys
REQUIRED_KEYS=(
  "GROQAI_API_KEY"
  "GROQ1KEY"
  "GROQ2KEY"
  "DEEPSEEK_API_KEY"
  "GEMINIAI_API_KEY"
  "GEMINI2_API_KEY"
  "NVIDIA_API_KEY"
  "NIVIIDIAKEY"
  "CEREBRAS_API_KEY"
  "CEREBRASKEY"
  "CODESTRAL_API_KEY"
  "COHERE_API_KEY"
  "CHUTES_API_KEY"
  "KIMI_API_KEY"
  "QWEN_API_KEY"
  "GPTOSS_API_KEY"
  "GROK_API_KEY"
  "GLM_API_KEY"
  "ZAIKEY"
  "ALIBABAKEY"
  "GROQ2_API_KEY"
)

echo "✅ Required API keys: ${#REQUIRED_KEYS[@]}"
echo ""

# Check workflows directory
WORKFLOWS_DIR=".github/workflows"

if [ ! -d "$WORKFLOWS_DIR" ]; then
  echo "❌ Workflows directory not found: $WORKFLOWS_DIR"
  exit 1
fi

echo "📂 Checking workflows in $WORKFLOWS_DIR:"
echo ""

# Check each workflow file
for workflow in "$WORKFLOWS_DIR"/*.yml; do
  if [ -f "$workflow" ]; then
    filename=$(basename "$workflow")
    echo "📄 $filename:"
    
    missing_keys=0
    for key in "${REQUIRED_KEYS[@]}"; do
      if ! grep -q "$key" "$workflow"; then
        echo "  ⚠️  Missing: $key"
        missing_keys=$((missing_keys + 1))
      fi
    done
    
    if [ $missing_keys -eq 0 ]; then
      echo "  ✅ All 21 API keys configured"
    else
      echo "  ❌ Missing $missing_keys API keys"
    fi
    echo ""
  fi
done

echo ""
echo "✅ Workflow verification complete!"
echo ""
echo "💡 To add missing keys, update workflows to include:"
echo ""
echo "env:"
for key in "${REQUIRED_KEYS[@]}"; do
  echo "  $key: \${{ secrets.$key }}"
done
