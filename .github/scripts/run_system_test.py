#!/usr/bin/env python3
import os, sys, subprocess
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from scripts.ai_api_fallback import AIAPIFallback

def run_tests() -> dict:
    results = {}
    try:
        result = subprocess.run(['pytest', '-v'], capture_output=True, text=True)
        results['pytest'] = {'stdout': result.stdout, 'returncode': result.returncode}
    except Exception as e:
        results['error'] = str(e)
    return results

def analyze_test_results(results: dict) -> str:
    fallback = AIAPIFallback()
    prompt = f"Analyze test results: {str(results)[:2000]}"
    result = fallback.generate_response(prompt, max_tokens=500)
    return result.get('response', '') if result.get('success') else ''

def main():
    test_results = run_tests()
    analysis = analyze_test_results(test_results)
    print(f"Test Results: {test_results}")
    print(f"Analysis: {analysis}" if analysis else "Analysis failed")
    sys.exit(0 if test_results.get('pytest', {}).get('returncode', 1) == 0 else 1)

if __name__ == "__main__":
    main()
