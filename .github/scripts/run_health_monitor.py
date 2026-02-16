#!/usr/bin/env python3
import os, sys, psutil
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from scripts.ai_api_fallback import AIAPIFallback

def collect_health_metrics():
    return {
        'cpu_percent': psutil.cpu_percent(interval=1),
        'memory_percent': psutil.virtual_memory().percent,
        'disk_percent': psutil.disk_usage('/').percent
    }

def analyze_health(metrics: dict) -> str:
    fallback = AIAPIFallback()
    prompt = f"Analyze system health: {str(metrics)}"
    result = fallback.generate_response(prompt, max_tokens=400)
    return result.get('response', '') if result.get('success') else ''

def main():
    metrics = collect_health_metrics()
    analysis = analyze_health(metrics)
    print(f"Health Metrics: {metrics}")
    print(f"Analysis: {analysis}" if analysis else "Analysis failed")

if __name__ == "__main__":
    main()
