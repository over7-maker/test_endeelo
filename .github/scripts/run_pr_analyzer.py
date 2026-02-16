#!/usr/bin/env python3
import os
import sys
import requests
from typing import Dict, Any, Optional

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from scripts.ai_api_fallback import AIAPIFallback

def get_pr_diff(pr_number: int, repo: str, token: str) -> Optional[str]:
    url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}"
    headers = {"Authorization": f"token {token}", "Accept": "application/vnd.github.v3.diff"}
    response = requests.get(url, headers=headers)
    return response.text if response.status_code == 200 else None

def analyze_pr(pr_data: Dict[str, Any], diff: str) -> Optional[Dict[str, Any]]:
    fallback = AIAPIFallback()
    prompt = f"""Analyze this Pull Request:
Title: {pr_data.get('title', 'N/A')}
Description: {pr_data.get('body', 'N/A')}
Files Changed: {pr_data.get('changed_files', 0)}
Diff: {diff[:2000]}
Provide code quality assessment and recommendations."""
    result = fallback.generate_response(prompt, max_tokens=800)
    return result if result.get('success') else None

def post_review(pr_number: int, comment: str, repo: str, token: str) -> bool:
    url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}/reviews"
    headers = {"Authorization": f"token {token}", "Accept": "application/vnd.github.v3+json"}
    payload = {"body": comment, "event": "COMMENT"}
    response = requests.post(url, headers=headers, json=payload)
    return response.status_code == 200

def main():
    pr_number = os.getenv('PR_NUMBER')
    repo = os.getenv('GITHUB_REPOSITORY')
    token = os.getenv('GITHUB_TOKEN')
    if not all([pr_number, repo, token]):
        print("Missing environment variables")
        sys.exit(1)
    url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}"
    response = requests.get(url, headers={"Authorization": f"token {token}"})
    if response.status_code != 200:
        sys.exit(1)
    pr_data = response.json()
    diff = get_pr_diff(int(pr_number), repo, token)
    if not diff:
        sys.exit(1)
    analysis = analyze_pr(pr_data, diff)
    if analysis and analysis.get('response'):
        post_review(int(pr_number), analysis['response'], repo, token)

if __name__ == "__main__":
    main()
