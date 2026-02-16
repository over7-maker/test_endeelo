#!/usr/bin/env python3
import os, sys, subprocess
from typing import Dict, Any
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from scripts.ai_api_fallback import AIAPIFallback

def run_security_checks() -> Dict[str, Any]:
    results = {}
    try:
        result = subprocess.run(['bandit', '-r', '.', '-f', 'json'], capture_output=True, text=True)
        results['bandit'] = result.stdout
    except Exception as e:
        results['error'] = str(e)
    return results

def analyze_security(results: Dict[str, Any]) -> str:
    fallback = AIAPIFallback()
    prompt = f"Analyze security scan: {str(results)[:2000]}"
    result = fallback.generate_response(prompt, max_tokens=600)
    return result.get('response', '') if result.get('success') else ''

def main():
    results = run_security_checks()
    analysis = analyze_security(results)
    print(analysis if analysis else "Analysis failed")

if __name__ == "__main__":
    main()
