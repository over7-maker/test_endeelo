#!/usr/bin/env python3
import os
import sys
import json
import requests
from typing import Dict, Any, Optional

# Import from the ai_api_fallback system
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from scripts.ai_api_fallback import AIAPIFallback

def analyze_issue(issue_data: Dict[str, Any]) -> Optional[str]:
    """Analyze GitHub issue and generate AI response."""
    fallback = AIAPIFallback()
    
    prompt = f"""
Analyze this GitHub issue and provide helpful response:

Title: {issue_data.get('title', 'N/A')}
Body: {issue_data.get('body', 'N/A')}
Labels: {', '.join([label['name'] for label in issue_data.get('labels', [])])}

Provide:
1. Issue classification
2. Recommended actions
3. Helpful response for the user
"""
    
    result = fallback.generate_response(prompt, max_tokens=500)
    return result.get('response') if result.get('success') else None

def post_comment(issue_number: int, comment: str, repo: str, token: str) -> bool:
    """Post comment to GitHub issue."""
    url = f"https://api.github.com/repos/{repo}/issues/{issue_number}/comments"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    response = requests.post(url, headers=headers, json={"body": comment})
    return response.status_code == 201

def main():
    # Get environment variables
    issue_number = os.getenv('ISSUE_NUMBER')
    repo = os.getenv('GITHUB_REPOSITORY')
    token = os.getenv('GITHUB_TOKEN')
    
    if not all([issue_number, repo, token]):
        print("Missing required environment variables")
        sys.exit(1)
    
    # Get issue data
    url = f"https://api.github.com/repos/{repo}/issues/{issue_number}"
    headers = {"Authorization": f"token {token}"}
    response = requests.get(url, headers=headers)
    
    if response.status_code != 200:
        print(f"Failed to fetch issue: {response.status_code}")
        sys.exit(1)
    
    issue_data = response.json()
    
    # Analyze and respond
    ai_response = analyze_issue(issue_data)
    if ai_response:
        success = post_comment(int(issue_number), ai_response, repo, token)
        print(f"Comment posted: {success}")
    else:
        print("Failed to generate AI response")
        sys.exit(1)

if __name__ == "__main__":
    main()
