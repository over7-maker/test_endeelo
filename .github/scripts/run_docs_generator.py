#!/usr/bin/env python3
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from scripts.ai_api_fallback import AIAPIFallback

def generate_docs(codebase_info: str) -> str:
    fallback = AIAPIFallback()
    prompt = f"Generate documentation for: {codebase_info[:2000]}"
    result = fallback.generate_response(prompt, max_tokens=1000)
    return result.get('response', '') if result.get('success') else ''

def main():
    codebase = "Project codebase analysis"
    docs = generate_docs(codebase)
    if docs:
        print("Generated Documentation:")
        print(docs)
        with open('docs/AUTO_GENERATED.md', 'w') as f:
            f.write(docs)
    else:
        print("Failed to generate docs")
        sys.exit(1)

if __name__ == "__main__":
    main()
