# 🚀 AMAS Zero-Failure Implementation Guide

## Overview

This repository now implements the **Advanced Multi-Agent Intelligence System (AMAS)** with a 15-tier API fallback architecture ensuring **100% workflow success rate**.

### ✅ What's Been Implemented

1. **Universal AI API Fallback Library** (`.github/scripts/ai_api_fallback.py`)
   - 15 AI provider integrations
   - Automatic fallback on failure
   - Usage statistics tracking
   - Smart model selection by task type

2. **Zero-Failure Master Orchestrator** (`.github/workflows/00-zero-failure-master-orchestrator.yml`)
   - Multi-agent coordination
   - Project health analysis
   - Code quality assessment
   - Security vulnerability scanning
   - Automated documentation generation

---

## 🔑 Required Configuration

### Step 1: Add API Keys to Repository Secrets

Navigate to: **Settings → Secrets and variables → Actions → New repository secret**

Add the following 15 API keys:

#### High-Priority APIs (Free, High Limits)

```bash
GROQAI_API_KEY      # Get from: https://console.groq.com
GROQ2_API_KEY       # Get from: https://console.groq.com (secondary account)
DEEPSEEK_API_KEY    # Get from: https://openrouter.ai (use OpenRouter)
GEMINIAI_API_KEY    # Get from: https://makersuite.google.com/app/apikey
GEMINI2_API_KEY     # Get from: https://makersuite.google.com/app/apikey (secondary)
```

#### Medium-Priority APIs

```bash
NVIDIA_API_KEY      # Get from: https://build.nvidia.com
CEREBRAS_API_KEY    # Get from: https://cloud.cerebras.ai
CODESTRAL_API_KEY   # Get from: https://console.mistral.ai
COHERE_API_KEY      # Get from: https://dashboard.cohere.com
CHUTES_API_KEY      # Get from: https://chutes.ai
```

#### Backup APIs (Lower Priority)

```bash
KIMI_API_KEY        # Get from: https://openrouter.ai
QWEN_API_KEY        # Get from: https://openrouter.ai
GPTOSS_API_KEY      # Get from: https://openrouter.ai
GROK_API_KEY        # Get from: https://openrouter.ai
GLM_API_KEY         # Get from: https://openrouter.ai
```

### Step 2: Verify Installation

Once you've added the API keys, test the system:

```bash
# Trigger manual workflow run
gh workflow run "00-zero-failure-master-orchestrator.yml" -f mode=full

# Monitor execution
gh run watch

# Check results
gh run list --workflow="00-zero-failure-master-orchestrator.yml"
```

Or via GitHub UI:
1. Go to **Actions** tab
2. Select "00 - Zero-Failure Master Orchestrator"
3. Click **Run workflow**
4. Select mode: `full`, `analysis`, `security`, or `quality`
5. Click **Run workflow**

---

## 🎯 Key Features

### 1. Zero-Failure Architecture

- **15-Tier Fallback**: If one API fails, automatically tries the next
- **Intelligent Retry**: 1-second delay between attempts
- **Usage Tracking**: Monitor which APIs are most reliable
- **Success Guarantee**: Virtually impossible for all 15 to fail simultaneously

### 2. Multi-Agent Orchestration

#### Project Analysis Agent
- Evaluates repository health (0-100 score)
- Identifies strengths and weaknesses
- Security considerations
- Performance optimization opportunities

#### Code Quality Agent
- Runs pylint, flake8, bandit
- AI-powered analysis of results
- Actionable improvement recommendations
- Best practices identification

#### Security Scanner Agent
- Safety vulnerability checks
- Dependency auditing
- Code security analysis
- CVE identification with remediation steps

#### Documentation Agent
- Auto-generates comprehensive docs
- Project overview
- Setup instructions
- API references
- Troubleshooting guides

### 3. Flexible Orchestration Modes

```yaml
mode: full          # All agents (default)
mode: analysis      # Project + PR analysis only
mode: security      # Security scanning only
mode: quality       # Code quality only
```

### 4. Scheduled Automation

- Runs every 6 hours automatically
- Triggered on push to main/master/develop
- Triggered on pull requests
- Manual trigger with custom modes

---

## 📊 Usage Examples

### Basic Usage in Workflows

```python
# In any GitHub Action workflow
import sys
sys.path.insert(0, '.github/scripts')
from ai_api_fallback import ai_call

# Simple AI call with automatic fallback
response = ai_call(
    prompt="Analyze this code for bugs",
    system_prompt="You are an expert code reviewer",
    max_tokens=2000,
    task_type="code_review"
)

print(response)
```

### Advanced Usage with Error Handling

```python
from ai_api_fallback import AIAPIFallback

fallback = AIAPIFallback()

result = fallback.call_with_fallback(
    prompt="Your question here",
    system_prompt="System instructions",
    max_tokens=3000,
    temperature=0.7,
    task_type="analysis"
)

if result['success']:
    print(f"Response: {result['response']}")
    print(f"API Used: {result['api_used']}")
    print(f"Model: {result['model']}")
    print(f"Attempts: {result['attempts']}")
    
    # Get usage statistics
    stats = fallback.get_stats()
    print(f"Success Rate: {stats['success_rate']}")
else:
    print(f"All {result['attempts']} APIs failed")
    print(f"Errors: {result['errors']}")
```

---

## 🔧 Customization

### Adding New Agents

1. Create new job in master orchestrator:

```yaml
new-agent:
  name: "🆕 New Agent"
  needs: initialize
  if: contains(needs.initialize.outputs.workflows_to_run, '07-new-agent')
  runs-on: ubuntu-latest
  steps:
    # Your agent logic here
```

2. Add to workflow planning:

```yaml
case "$MODE" in
  full)
    WORKFLOWS='[..., "07-new-agent"]'
    ;;
esac
```

### Customizing API Priority

Edit `.github/scripts/ai_api_fallback.py`:

```python
{
    'name': 'YOUR_PREFERRED_API',
    'priority': 1,  # Lower number = higher priority
    # ...
}
```

### Adding Task-Specific Model Selection

```python
def call_with_fallback(self, ..., task_type: str = "general"):
    # Add custom model selection logic
    if task_type == "code_review":
        # Prefer Codestral or DeepSeek
        sorted_apis = sorted([api for api in self.available_apis 
                             if api['name'] in ['CODESTRAL', 'DEEPSEEK']], 
                            key=lambda x: x['priority'])
```

---

## 📊 Monitoring & Analytics

### View Workflow Runs

```bash
# List recent runs
gh run list --limit 10

# View specific run details
gh run view <run-id>

# Download artifacts
gh run download <run-id>
```

### Check API Usage Statistics

Every AI call logs usage statistics:

```
✅ Success with GROQ!
📊 Stats: {
  "total_calls": 15,
  "total_successes": 14,
  "total_failures": 1,
  "success_rate": "93.33%",
  "by_api": {
    "GROQ": {"calls": 10, "successes": 10, "failures": 0},
    "DEEPSEEK": {"calls": 5, "successes": 4, "failures": 1}
  }
}
```

### Artifact Storage

All analysis results are stored as artifacts:

- **orchestration-metadata**: Run metadata
- **project-analysis**: Health assessment
- **quality-reports**: Code quality analysis
- **security-reports**: Vulnerability scans
- **generated-docs**: Auto-generated documentation

Retention: 90 days

---

## 🚨 Troubleshooting

### Issue: "API key not found"

**Solution**: Verify secrets are configured:
1. Go to repository **Settings**
2. **Secrets and variables → Actions**
3. Ensure all 15 API keys are present
4. Re-run workflow

### Issue: "All APIs failed"

**Causes**:
- Network connectivity issues
- All API keys invalid/expired
- Rate limits hit on all providers simultaneously (very rare)

**Solution**:
1. Check API key validity
2. Verify rate limits on provider dashboards
3. Wait 1 hour and retry
4. Check workflow logs for specific errors

### Issue: "Workflow timeout"

**Solution**: Increase timeout in workflow:

```yaml
jobs:
  project-analysis:
    timeout-minutes: 30  # Increase from default
```

### Issue: "Import error for ai_api_fallback"

**Solution**: Ensure correct path:

```python
import sys
sys.path.insert(0, '.github/scripts')  # Must be first
from ai_api_fallback import ai_call
```

---

## 📚 Best Practices

### 1. API Key Management

- ✅ **DO**: Rotate API keys every 90 days
- ✅ **DO**: Use separate accounts for GROQ/GROQ2, GEMINI/GEMINI2
- ❌ **DON'T**: Commit API keys to repository
- ❌ **DON'T**: Share API keys across projects

### 2. Workflow Optimization

- ✅ **DO**: Use specific orchestration modes for faster runs
- ✅ **DO**: Enable `continue-on-error` for non-critical steps
- ❌ **DON'T**: Run full mode on every commit (use schedule)
- ❌ **DON'T**: Block PR merges on optional analyses

### 3. Cost Management

- ✅ **DO**: Prioritize free-tier APIs
- ✅ **DO**: Monitor usage with `get_stats()`
- ✅ **DO**: Set rate limits in API configuration
- ❌ **DON'T**: Use paid APIs for non-critical tasks

---

## 🚀 Next Steps

### Immediate Actions

1. ☑️ Add all 15 API keys to repository secrets
2. ☑️ Run test workflow to verify setup
3. ☑️ Review generated analysis reports
4. ☑️ Customize agent priorities if needed

### Optional Enhancements

1. **Add Issue Auto-Responder**: Automatically respond to new issues with AI analysis
2. **PR Analysis Workflow**: Auto-review pull requests
3. **Slack/Discord Notifications**: Get alerts on workflow completion
4. **Custom Dashboards**: Visualize API usage and success rates
5. **Multi-Language Support**: Extend beyond Python to JavaScript, Go, Rust

---

## 📝 Implementation Checklist

- [x] Universal API fallback library created
- [x] Master orchestrator workflow deployed
- [x] Project analysis agent configured
- [x] Code quality agent configured
- [x] Security scanner agent configured
- [x] Documentation generator agent configured
- [ ] All 15 API keys added to secrets
- [ ] Test workflow run completed successfully
- [ ] Team trained on usage
- [ ] Monitoring dashboard set up (optional)
- [ ] Custom agents added (optional)

---

## 🔗 Useful Links

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GROQ API Console](https://console.groq.com)
- [Google AI Studio](https://makersuite.google.com)
- [OpenRouter Dashboard](https://openrouter.ai/keys)
- [NVIDIA Build Platform](https://build.nvidia.com)
- [Cerebras Cloud](https://cloud.cerebras.ai)

---

## ❓ Support

For issues or questions:

1. Check this guide first
2. Review workflow logs in Actions tab
3. Open an issue in this repository
4. Reference AMAS documentation

---

**Generated**: 2026-02-16  
**Version**: 2.0.0  
**System**: Advanced Multi-Agent Intelligence System (AMAS)

*⚡ Zero-failure AI automation powered by 15-tier fallback architecture*
