WORKFLOW_FIXES_GUIDE.md  # Complete Workflow Fixes Guide

## ✅ COMPLETED

1. **ai-issue-responder.yml** - Fixed! ✅

## ⚠️ REMAINING 5 WORKFLOWS TO FIX

Each workflow has the same problem: Invalid Python heredoc syntax.
Follow these instructions for each file:

---

### 2. ai-pr-analyzer.yml

**Lines to DELETE:** 49-129

**REPLACE WITH:**
```yaml
      - name: "🤖 Run PR Analyzer"
        run: python3 .github/scripts/run_pr_analyzer.py
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
```

---

### 3. ai-code-security-scan.yml

**Lines to DELETE:** Find the step with `python3 <<'PYTHON_SCRIPT'` and delete entire section

**REPLACE WITH:**
```yaml
      - name: "🤖 Run Security Scan"
        run: python3 .github/scripts/run_security_scan.py
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### 4. ai-docs-generator.yml

**Lines to DELETE:** Find the step with `python3 <<'PYTHON_SCRIPT'` and delete entire section

**REPLACE WITH:**
```yaml
      - name: "🤖 Run Docs Generator"
        run: python3 .github/scripts/run_docs_generator.py
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### 5. ai-health-monitor.yml

**Lines to DELETE:** Find the step with `python3 <<'PYTHON_SCRIPT'` and delete entire section

**REPLACE WITH:**
```yaml
      - name: "🤖 Run Health Monitor"
        run: python3 .github/scripts/run_health_monitor.py
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### 6. system-health-test.yml

**Lines to DELETE:** Find the step with `python3 <<'PYTHON_SCRIPT'` and delete entire section

**REPLACE WITH:**
```yaml
      - name: "🤖 Run System Test"
        run: python3 .github/scripts/run_system_test.py
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 🎯 HOW TO FIND THE SECTION TO DELETE

1. Open the workflow file
2. Press Ctrl+F and search for: `<<'PYTHON`
3. This will highlight the line with `python3 <<'PYTHON_SCRIPT'`
4. Look UP from there to find the step name (starts with `- name:`)
5. Look DOWN to find the closing `PYTHON_SCRIPT` line
6. DELETE everything from the `- name:` line to the `PYTHON_SCRIPT` closing line
7. PASTE the replacement code (5 lines)
8. Commit!

## ✨ PATTERN TO REMEMBER

All fixes follow this pattern:
- Remove the large heredoc block with all API keys
- Replace with simple script call
- Keep only `GITHUB_TOKEN` and one context variable
- The script handles all API fallback logic internally

## 🚀 After All Fixes

Once all 6 workflows are fixed:
1. All workflow files will be clean and simple
2. All Python scripts contain the complex logic
3. 21-tier API fallback works automatically
4. No more YAML syntax errors!
5. All workflows will run successfully! 🎉
