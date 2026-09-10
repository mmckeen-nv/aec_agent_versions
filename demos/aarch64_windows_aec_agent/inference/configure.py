"""Profile inference operations; JSON stdin keeps credentials out of command lines.

Uses PyYAML and python-dotenv already installed with Hermes. Never returns secrets.
"""
import io
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile
from datetime import datetime, timezone
from urllib.parse import urlsplit
from urllib.request import Request, build_opener, HTTPRedirectHandler
from urllib.error import HTTPError, URLError

import yaml
from dotenv import dotenv_values

DEFAULTS = dict(provider='custom:nvidia-switchyard', model='switchyard/openai/gpt-5.6-sol',
                base_url='https://inference-api.nvidia.com/v1', key_env='NVIDIA_API_KEY',
                api_mode='codex_responses', context_length=1000000)


class ConfigurationError(Exception):
    pass


def validate(s):
    if not re.fullmatch(r'custom:[a-zA-Z0-9_-]+', s['provider']):
        raise ConfigurationError('Provider must use custom:<name>.')
    if not re.fullmatch(r'[A-Z][A-Z0-9_]*', s['key_env']):
        raise ConfigurationError('Invalid API key environment variable name.')
    if not isinstance(s['model'], str) or not s['model'].strip() or any(c in s['model'] for c in '\r\n'):
        raise ConfigurationError('A single-line model ID is required.')
    url = urlsplit(s['base_url'])
    if (url.scheme not in ('http', 'https') or not url.hostname or url.username or url.password
            or url.query or url.fragment or re.search(r'\s', s['base_url'])):
        raise ConfigurationError('Use an HTTP(S) API base URL without credentials, query, or fragment.')
    _ = url.port  # Reject invalid ports too.
    if url.path.rstrip('/').endswith(('/responses', '/chat/completions')):
        raise ConfigurationError('Use the API base URL (usually ending /v1), not a request route.')
    if s['api_mode'] not in ('chat_completions', 'codex_responses'):
        raise ConfigurationError('API mode must be chat_completions or codex_responses.')
    if not 8192 <= int(s['context_length']) <= 1050000:
        raise ConfigurationError('Context length must be between 8192 and 1050000.')
    s['context_length'] = int(s['context_length'])
    s['base_url'] = s['base_url'].rstrip('/')
    return s


def read_config(root):
    return yaml.safe_load((root / 'config.yaml').read_text(encoding='utf-8-sig'))


def settings(config):
    model = config['model']
    provider = model['provider']
    entry = config['providers'][provider.removeprefix('custom:')]
    return validate(dict(provider=provider, model=model['default'],
                         base_url=model.get('base_url', entry.get('base_url')),
                         key_env=entry['key_env'], api_mode=entry.get('api_mode', 'chat_completions'),
                         context_length=model.get('context_length', entry.get('context_length', 32768))))


def credential(root, s):
    # Profile credentials must win over an inherited key for a different profile.
    path = root / '.env'
    values = dotenv_values(stream=io.StringIO(path.read_text(encoding='utf-8-sig')), interpolate=False) if path.exists() else {}
    return values.get(s['key_env']) or os.environ.get(s['key_env'], '')


def atomic_write(path, text):
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix=path.name + '.', suffix='.tmp')
    try:
        with os.fdopen(fd, 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def write_key(root, name, key):
    if key is not None and (not key.strip() or any(c in key for c in '\r\n\x00')):
        raise ConfigurationError('The API key is empty or contains a line break.')
    path = root / '.env'
    lines = path.read_text(encoding='utf-8-sig').splitlines() if path.exists() else []
    lines = [line for line in lines if not re.match(r'^\s*(?:export\s+)?' + re.escape(name) + r'\s*=', line)]
    if key is not None:
        # dotenv single quotes preserve $, #, spaces, and literal backslashes.
        escaped = key.replace('\\', '\\\\').replace("'", "\\'")
        lines.append(f"{name}='{escaped}'")
    atomic_write(path, '\n'.join(lines) + ('\n' if lines else ''))


def apply_settings(config, s):
    validate(s)
    name = s['provider'].split(':', 1)[1]
    config['model'].update(provider=s['provider'], default=s['model'], base_url=s['base_url'],
                           api_key='${' + s['key_env'] + '}', context_length=s['context_length'])
    config.setdefault('providers', {})[name] = dict(name=name, base_url=s['base_url'], key_env=s['key_env'],
        default_model=s['model'], api_mode=s['api_mode'], context_length=s['context_length'])
    # NVIDIA's fast tier is not a portable request parameter.
    if s['provider'] != DEFAULTS['provider']:
        config.get('agent', {}).pop('service_tier', None)
    return config


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None  # Do not forward bearer credentials to redirected endpoints.


def probe(root, s, timeout):
    key = credential(root, s)
    if not key:
        raise ConfigurationError('API key is missing; run Change_API_Key.cmd.')
    body = dict(model=s['model'])
    if s['api_mode'] == 'chat_completions':
        route = '/chat/completions'
        body.update(messages=[dict(role='user', content='Reply with the single word READY.')], max_tokens=16)
    else:
        route = '/responses'
        body.update(input='Reply with the single word READY.', max_output_tokens=16)
    request = Request(s['base_url'] + route, data=json.dumps(body).encode(),
                      headers={'Authorization': 'Bearer ' + key, 'Content-Type': 'application/json'})
    try:
        with build_opener(NoRedirect).open(request, timeout=timeout) as response:
            data = json.load(response)
    except HTTPError as exc:
        raise ConfigurationError(f'Inference request failed (HTTP {exc.code}). Check endpoint, model, API mode, and key.') from None
    except (URLError, TimeoutError):
        raise ConfigurationError('Inference endpoint could not be reached within the timeout.') from None
    if not isinstance(data, dict) or data.get('error') or data.get('status') in ('failed', 'cancelled'):
        raise ConfigurationError('Inference endpoint returned an error payload.')
    if s['api_mode'] == 'chat_completions':
        outputs = [c.get('message', {}).get('content') for c in data.get('choices', [])]
    else:
        outputs = [c.get('text') for item in data.get('output', []) for c in item.get('content', []) if c.get('type') == 'output_text']
    if not any(isinstance(value, str) and value.strip() for value in outputs):
        raise ConfigurationError('Inference endpoint returned no generated text.')
    return dict(ok=True, **s)


def main(payload):
    action = payload['action']
    if action == 'validate':
        return validate(payload['settings'])
    root = Path(payload['root'])
    if action == 'render':
        text = Path(payload['template']).read_text(encoding='utf-8-sig')
        def replace(value):
            if isinstance(value, str):
                for token, replacement in payload['replacements'].items():
                    value = value.replace(token, str(replacement))
            elif isinstance(value, list):
                value = [replace(item) for item in value]
            elif isinstance(value, dict):
                value = {key: replace(item) for key, item in value.items()}
            return value
        config = apply_settings(replace(yaml.safe_load(text)), payload['settings'])
        return dict(text=yaml.safe_dump(config, sort_keys=False, allow_unicode=True))
    config = read_config(root)
    s = settings(config)
    if action == 'read':
        return dict(**s, has_key=bool(credential(root, s)))
    if action == 'ensure_key':
        key = credential(root, s)
        if not key:
            raise ConfigurationError('API key is missing.')
        write_key(root, s['key_env'], key)
        return dict(ok=True)
    if action == 'key':
        write_key(root, s['key_env'], payload.get('key'))
        return dict(ok=True)
    if action == 'configure':
        s.update(payload['settings'])
        config = apply_settings(config, s)
        key = payload.get('key')
        if key is not None and (not key.strip() or any(c in key for c in '\r\n\x00')):
            raise ConfigurationError('Invalid API key.')
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        shutil.copy2(root / 'config.yaml', root / f'config.yaml.{stamp}.bak')
        if key is not None:
            write_key(root, s['key_env'], key)
        atomic_write(root / 'config.yaml', yaml.safe_dump(config, sort_keys=False, allow_unicode=True))
        return dict(ok=True, **s)
    if action == 'probe':
        return probe(root, s, int(payload.get('timeout', 60)))
    raise ConfigurationError('Unknown inference action.')


if __name__ == '__main__':
    try:
        print(json.dumps(main(json.load(sys.stdin))))
    except ConfigurationError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
    except Exception:
        # YAML/JSON parser errors and transport errors can contain secrets. Do not print them.
        print('Inference operation failed. Check profile configuration, credentials, endpoint and dependencies.', file=sys.stderr)
        sys.exit(1)
