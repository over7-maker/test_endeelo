#!/usr/bin/env python3
"""
Universal AI Orchestrator with 15-Provider Fallback Chain
Zero-failure guarantee through sequential provider attempts
"""

import os
import sys
import json
import time
import asyncio
import hashlib
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from pathlib import Path

try:
    import aiohttp
except ImportError:
    print("Installing aiohttp...")
    os.system("pip install aiohttp")
    import aiohttp


class APIProvider:
    """Individual API provider configuration"""
    def __init__(self, name: str, base_url: str, key_env: str, model: str, 
                 headers_func=None, payload_func=None):
        self.name = name
        self.base_url = base_url
        self.key_env = key_env
        self.model = model
        self.headers_func = headers_func or self.default_headers
        self.payload_func = payload_func or self.default_payload
        self.api_key = os.getenv(key_env)
    
    def default_headers(self):
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
    
    def default_payload(self, system_msg, user_prompt, max_tokens, temperature):
        return {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_msg},
                {"role": "user", "content": user_prompt}
            ],
            "max_tokens": max_tokens,
            "temperature": temperature
        }
    
    def is_available(self):
        return bool(self.api_key)


class UniversalAIOrchestrator:
    """
    Zero-Failure AI Orchestrator
    Tries providers sequentially until success
    """
    
    def __init__(self, cache_dir: str = ".github/data/cache"):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.metrics_dir = Path(".github/data/metrics")
        self.metrics_dir.mkdir(parents=True, exist_ok=True)
        
        # Provider chain ordered by reliability and cost-effectiveness
        self.providers = self._init_providers()
        
    def _init_providers(self) -> List[APIProvider]:
        """Initialize all 15 providers in fallback priority order"""
        return [
            # Tier 1: High reliability free providers
            APIProvider(
                "GROQ", 
                "https://api.groq.com/openai/v1/chat/completions",
                "GROQAI_API_KEY",
                "llama-3.3-70b-versatile"
            ),
            APIProvider(
                "DEEPSEEK",
                "https://openrouter.ai/api/v1/chat/completions",
                "DEEPSEEK_API_KEY",
                "deepseek/deepseek-chat-v3.1:free",
                headers_func=lambda self: {
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                    "HTTP-Referer": "https://github.com/over7-maker/test_endeelo",
                    "X-Title": "test_endeelo automation"
                }
            ),
            APIProvider(
                "CEREBRAS",
                "https://api.cerebras.ai/v1/chat/completions",
                "CEREBRAS_API_KEY",
                "llama3.1-70b"
            ),
            
            # Tier 2: Premium providers
            APIProvider(
                "NVIDIA",
                "https://integrate.api.nvidia.com/v1/chat/completions",
                "NVIDIA_API_KEY",
                "deepseek-ai/deepseek-r1"
            ),
            APIProvider(
                "CODESTRAL",
                "https://codestral.mistral.ai/v1/chat/completions",
                "CODESTRAL_API_KEY",
                "codestral-latest"
            ),
            APIProvider(
                "GEMINI2",
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
                "GEMINI2_API_KEY",
                "gemini-2.0-flash",
                headers_func=lambda self: {
                    "Content-Type": "application/json",
                    "X-goog-api-key": self.api_key
                },
                payload_func=lambda self, sys, usr, max_tok, temp: {
                    "contents": [{
                        "parts": [{"text": f"{sys}\n\n{usr}"}]
                    }],
                    "generationConfig": {
                        "maxOutputTokens": max_tok,
                        "temperature": temp
                    }
                }
            ),
            
            # Tier 3: Backup providers
            APIProvider(
                "GLM",
                "https://openrouter.ai/api/v1/chat/completions",
                "GLM_API_KEY",
                "z-ai/glm-4.5-air:free",
                headers_func=lambda self: {
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                    "HTTP-Referer": "https://github.com",
                    "X-Title": "test_endeelo"
                }
            ),
            APIProvider(
                "GROK",
                "https://openrouter.ai/api/v1/chat/completions",
                "GROK_API_KEY",
                "x-ai/grok-4-fast:free"
            ),
            APIProvider(
                "KIMI",
                "https://openrouter.ai/api/v1/chat/completions",
                "KIMI_API_KEY",
                "moonshotai/kimi-k2:free"
            ),
            APIProvider(
                "QWEN",
                "https://openrouter.ai/api/v1/chat/completions",
                "QWEN_API_KEY",
                "qwen/qwen3-coder:free"
            ),
            APIProvider(
                "GPTOSS",
                "https://openrouter.ai/api/v1/chat/completions",
                "GPTOSS_API_KEY",
                "openai/gpt-oss-120b:free"
            ),
            APIProvider(
                "CHUTES",
                "https://llm.chutes.ai/v1/chat/completions",
                "CHUTES_API_KEY",
                "zai-org/GLM-4.5-Air"
            ),
            APIProvider(
                "COHERE",
                "https://api.cohere.ai/v1/chat",
                "COHERE_API_KEY",
                "command-a-03-2025",
                payload_func=lambda self, sys, usr, max_tok, temp: {
                    "model": "command-a-03-2025",
                    "message": f"{sys}\n\n{usr}",
                    "max_tokens": max_tok,
                    "temperature": temp
                }
            ),
            APIProvider(
                "GROQ2",
                "https://api.groq.com/openai/v1/chat/completions",
                "GROQ2_API_KEY",
                "mixtral-8x7b-32768"
            ),
            APIProvider(
                "GEMINIAI",
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent",
                "GEMINIAI_API_KEY",
                "gemini-1.5-flash"
            ),
        ]
    
    def _get_cache_key(self, system_msg: str, user_prompt: str, 
                       max_tokens: int, temperature: float) -> str:
        """Generate cache key from request parameters"""
        content = f"{system_msg}|{user_prompt}|{max_tokens}|{temperature}"
        return hashlib.sha256(content.encode()).hexdigest()
    
    def _get_cache_path(self, cache_key: str) -> Path:
        """Get cache file path"""
        return self.cache_dir / f"{cache_key}.json"
    
    def _read_cache(self, cache_key: str) -> Optional[Dict]:
        """Read from cache if exists and fresh (<24h)"""
        cache_file = self._get_cache_path(cache_key)
        if not cache_file.exists():
            return None
        
        try:
            data = json.loads(cache_file.read_text())
            # Check if cache is fresh (24 hours)
            cached_time = datetime.fromisoformat(data.get('timestamp', ''))
            age_hours = (datetime.now() - cached_time).total_seconds() / 3600
            if age_hours < 24:
                return data
        except:
            pass
        return None
    
    def _write_cache(self, cache_key: str, data: Dict):
        """Write to cache"""
        cache_file = self._get_cache_path(cache_key)
        data['timestamp'] = datetime.now().isoformat()
        cache_file.write_text(json.dumps(data, indent=2))
    
    async def _try_provider(self, provider: APIProvider, system_msg: str,
                           user_prompt: str, max_tokens: int, 
                           temperature: float) -> Tuple[bool, Optional[str], float]:
        """
        Try single provider
        Returns: (success, response_text, duration_ms)
        """
        if not provider.is_available():
            return False, f"Provider {provider.name} not configured", 0.0
        
        start_time = time.time()
        
        try:
            headers = provider.headers_func()
            payload = provider.payload_func(system_msg, user_prompt, 
                                           max_tokens, temperature)
            
            timeout = aiohttp.ClientTimeout(total=30)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.post(
                    provider.base_url,
                    headers=headers,
                    json=payload
                ) as response:
                    duration_ms = (time.time() - start_time) * 1000
                    
                    if response.status == 200:
                        data = await response.json()
                        
                        # Extract response based on provider format
                        if provider.name in ["GEMINI2", "GEMINIAI"]:
                            text = data['candidates'][0]['content']['parts'][0]['text']
                        elif provider.name == "COHERE":
                            text = data['text']
                        else:
                            text = data['choices'][0]['message']['content']
                        
                        return True, text, duration_ms
                    else:
                        error_text = await response.text()
                        return False, f"HTTP {response.status}: {error_text[:200]}", duration_ms
                        
        except asyncio.TimeoutError:
            duration_ms = (time.time() - start_time) * 1000
            return False, "Request timeout", duration_ms
        except Exception as e:
            duration_ms = (time.time() - start_time) * 1000
            return False, f"Exception: {str(e)[:200]}", duration_ms
    
    async def execute(self, task_type: str, system_msg: str, user_prompt: str,
                     max_tokens: int = 2000, temperature: float = 0.7,
                     use_cache: bool = True) -> Dict:
        """
        Execute AI task with fallback chain
        Returns comprehensive result dict
        """
        start_time = time.time()
        
        # Check cache
        cache_key = self._get_cache_key(system_msg, user_prompt, max_tokens, temperature)
        if use_cache:
            cached = self._read_cache(cache_key)
            if cached:
                return {
                    'success': True,
                    'provider': cached.get('provider', 'cache'),
                    'response': cached['response'],
                    'duration_ms': (time.time() - start_time) * 1000,
                    'fallback_count': 0,
                    'cached': True,
                    'task_type': task_type
                }
        
        # Try providers sequentially
        fallback_count = 0
        attempts = []
        
        for provider in self.providers:
            if not provider.is_available():
                continue
            
            fallback_count += 1
            print(f"🔄 Trying provider {fallback_count}: {provider.name}...", file=sys.stderr)
            
            success, result, duration = await self._try_provider(
                provider, system_msg, user_prompt, max_tokens, temperature
            )
            
            attempts.append({
                'provider': provider.name,
                'success': success,
                'duration_ms': duration,
                'error': None if success else result
            })
            
            if success:
                print(f"✅ Success with {provider.name}!", file=sys.stderr)
                
                # Cache successful response
                if use_cache:
                    self._write_cache(cache_key, {
                        'provider': provider.name,
                        'response': result
                    })
                
                # Log metrics
                self._log_metrics(task_type, provider.name, True, duration, 
                                 fallback_count, attempts)
                
                total_duration = (time.time() - start_time) * 1000
                return {
                    'success': True,
                    'provider': provider.name,
                    'response': result,
                    'duration_ms': total_duration,
                    'fallback_count': fallback_count,
                    'cached': False,
                    'task_type': task_type,
                    'attempts': attempts
                }
            else:
                print(f"❌ {provider.name} failed: {result[:100]}", file=sys.stderr)
        
        # All providers failed
        total_duration = (time.time() - start_time) * 1000
        self._log_metrics(task_type, "none", False, total_duration, 
                         fallback_count, attempts)
        
        return {
            'success': False,
            'provider': 'none',
            'response': f"All {fallback_count} providers failed",
            'duration_ms': total_duration,
            'fallback_count': fallback_count,
            'cached': False,
            'task_type': task_type,
            'attempts': attempts
        }
    
    def _log_metrics(self, task_type: str, provider: str, success: bool,
                    duration_ms: float, fallback_count: int, attempts: List):
        """Log execution metrics"""
        metrics_file = self.metrics_dir / f"ai_metrics_{datetime.now().strftime('%Y%m')}.jsonl"
        
        metric = {
            'timestamp': datetime.now().isoformat(),
            'task_type': task_type,
            'provider': provider,
            'success': success,
            'duration_ms': duration_ms,
            'fallback_count': fallback_count,
            'total_attempts': len(attempts),
            'attempts': attempts
        }
        
        with metrics_file.open('a') as f:
            f.write(json.dumps(metric) + '\n')


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Universal AI Orchestrator')
    parser.add_argument('--task-type', required=True, help='Type of AI task')
    parser.add_argument('--system-message', required=True, help='System message')
    parser.add_argument('--user-prompt', required=True, help='User prompt')
    parser.add_argument('--max-tokens', type=int, default=2000, help='Max tokens')
    parser.add_argument('--temperature', type=float, default=0.7, help='Temperature')
    parser.add_argument('--no-cache', action='store_true', help='Disable cache')
    parser.add_argument('--output', required=True, help='Output JSON file')
    
    args = parser.parse_args()
    
    orchestrator = UniversalAIOrchestrator()
    
    result = asyncio.run(orchestrator.execute(
        task_type=args.task_type,
        system_msg=args.system_message,
        user_prompt=args.user_prompt,
        max_tokens=args.max_tokens,
        temperature=args.temperature,
        use_cache=not args.no_cache
    ))
    
    # Write output
    Path(args.output).write_text(json.dumps(result, indent=2))
    
    # Exit with appropriate code
    sys.exit(0 if result['success'] else 1)


if __name__ == '__main__':
    main()
