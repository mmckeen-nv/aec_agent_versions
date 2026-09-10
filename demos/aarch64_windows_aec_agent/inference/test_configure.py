import copy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

import yaml

spec = importlib.util.spec_from_file_location('configure', Path(__file__).with_name('configure.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
PLATFORM = Path(__file__).resolve().parents[1]


class InferenceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.config = yaml.safe_load((PLATFORM / 'cliff_house_full_build/config/hermes/config.template.yaml').read_text())
        (self.root / 'config.yaml').write_text(yaml.safe_dump(self.config))

    def call(self, action, **kwargs):
        return module.main(dict(action=action, root=str(self.root), **kwargs))

    def custom(self, **kwargs):
        return dict(module.DEFAULTS, provider='custom:aec-inference', model='local/model: # revision',
                    key_env='AEC_INFERENCE_API_KEY', **kwargs)

    def test_legacy_profile_and_quoted_key(self):
        key = r"literal # $VALUE ${OTHER} ' \ tail"
        self.call('key', key=key)
        self.assertEqual(module.credential(self.root, module.DEFAULTS), key)
        result = self.call('read')
        self.assertTrue(result['has_key'])
        self.assertNotIn(key, json.dumps(result))

    def test_custom_settings_roundtrip_preserves_mcp_and_memory(self):
        s = self.custom(base_url='http://127.0.0.1:8000/v1/', api_mode='chat_completions')
        self.call('configure', settings=s, key='local')
        config = module.read_config(self.root)
        self.assertEqual(config['memory'], self.config['memory'])
        self.assertEqual(config['mcp_servers'], self.config['mcp_servers'])
        self.assertNotIn('service_tier', config['agent'])
        self.assertEqual(self.call('read')['model'], s['model'])
        self.assertEqual(self.call('read')['base_url'], 'http://127.0.0.1:8000/v1')
        self.assertNotIn('api_key: local', (self.root / 'config.yaml').read_text())
        self.assertEqual(len(list(self.root.glob('config.yaml.*.bak'))), 1)

    def test_key_erase_keeps_other_values(self):
        (self.root / '.env').write_text('OTHER=value\nNVIDIA_API_KEY=old\nexport NVIDIA_API_KEY=duplicate\n')
        self.call('key', key='new')
        self.call('key', key=None)
        self.assertEqual((self.root / '.env').read_text(), 'OTHER=value\n')

    def test_environment_key_is_persisted(self):
        with patch.dict(os.environ, NVIDIA_API_KEY='environment-value'):
            self.call('ensure_key')
        self.assertEqual(module.credential(self.root, module.DEFAULTS), 'environment-value')

    def test_profile_key_wins_over_environment(self):
        self.call('key', key='profile-value')
        with patch.dict(os.environ, NVIDIA_API_KEY='unrelated-value'):
            self.assertEqual(module.credential(self.root, module.DEFAULTS), 'profile-value')

    def test_invalid_input_does_not_modify_config(self):
        original = (self.root / 'config.yaml').read_bytes()
        for url in ('ftp://host', 'https://user:pass@host/v1', 'https://host/v1/responses',
                    'https://host/v1/chat/completions/', 'https://host/v1?key=value', 'https://host/\n'):
            with self.subTest(url=url), self.assertRaises(module.ConfigurationError):
                self.call('configure', settings=self.custom(base_url=url), key='value')
        self.assertEqual((self.root / 'config.yaml').read_bytes(), original)
        self.assertFalse((self.root / '.env').exists())

    def test_multiline_key_rejected_before_changes(self):
        original = (self.root / 'config.yaml').read_bytes()
        with self.assertRaises(module.ConfigurationError):
            self.call('configure', settings=self.custom(), key='value\nINJECTED=1')
        self.assertEqual((self.root / 'config.yaml').read_bytes(), original)

    def test_render_paths_and_model_safely_for_both_templates(self):
        for package in ('cliff_house_full_build', 'cliff_house_modifications'):
            result = self.call('render', template=str(PLATFORM / package / 'config/hermes/config.template.yaml'),
                               settings=self.custom(), replacements={'__DML_ROOT__': 'C:/Test, Folder/#é', '__DML_STORE__': 'C:/store'})
            config = yaml.safe_load(result['text'])
            self.assertEqual(config['model']['default'], self.custom()['model'])
            self.assertEqual(config['memory']['daystrom_dml']['integration_dir'], 'C:/Test, Folder/#é')

    def server(self, status, response):
        captured = []
        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                captured.append((self.path, self.headers['Authorization'], json.loads(self.rfile.read(int(self.headers['Content-Length'])))))
                self.send_response(status)
                self.send_header('Content-Type', 'application/json')
                if status == 302:
                    self.send_header('Location', '/redirected')
                self.end_headers()
                self.wfile.write(json.dumps(response).encode())
            def log_message(self, *args):
                pass
        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        return f'http://127.0.0.1:{server.server_port}/v1', captured

    def test_both_api_routes_and_authorization(self):
        for mode, response, route, field in (
            ('chat_completions', {'choices': [{'message': {'content': 'READY'}}]}, '/v1/chat/completions', 'messages'),
            ('codex_responses', {'output': [{'content': [{'type': 'output_text', 'text': 'READY'}]}]}, '/v1/responses', 'input'),
        ):
            url, captured = self.server(200, response)
            self.call('configure', settings=self.custom(base_url=url, api_mode=mode), key='test-token')
            self.assertTrue(self.call('probe')['ok'])
            self.assertEqual(captured[0][0:2], (route, 'Bearer test-token'))
            self.assertIn(field, captured[0][2])

    def test_empty_error_and_id_only_responses_fail(self):
        for response in ({'id': 'only'}, {'error': {'message': 'failure'}}, {'choices': []}):
            url, _ = self.server(200, response)
            self.call('configure', settings=self.custom(base_url=url), key='test-token')
            with self.assertRaises(module.ConfigurationError):
                self.call('probe')

    def test_http_error_and_redirect_do_not_leak_key(self):
        for status in (401, 302):
            url, captured = self.server(status, {'error': 'test-token'})
            self.call('configure', settings=self.custom(base_url=url), key='test-token')
            with self.assertRaises(module.ConfigurationError) as exc:
                self.call('probe')
            self.assertNotIn('test-token', str(exc.exception))
            self.assertEqual(len(captured), 1)


if __name__ == '__main__':
    unittest.main()
