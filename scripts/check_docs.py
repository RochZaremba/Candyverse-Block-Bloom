#!/usr/bin/env python3
"""Minimalny validator struktury pakietu dokumentacji (stdlib-only)."""
from pathlib import Path
import json
import re
import sys

root = Path(__file__).resolve().parents[1]
required = [
    'README.md','AGENTS.md','START_CODEX.md','docs/INDEX.md','docs/PRD.md',
    'docs/GAME_DESIGN.md','docs/VISUAL_DIRECTION.md','docs/ARCHITECTURE.md',
    'docs/ROADMAP.md','docs/STATUS.md','docs/TEST_PLAN.md',
    'docs/RELEASE_GOOGLE_PLAY.md','docs/PRIVACY_AND_SAFETY.md',
    'docs/adr/README.md','assets/design_tokens.json'
]
errors = []
for path in required:
    if not (root / path).is_file():
        errors.append(f'Missing required file: {path}')

for markdown in root.rglob('*.md'):
    contents = markdown.read_text(encoding='utf-8')
    for url in re.findall(r'\]\(([^)]+)\)', contents):
        if url.startswith(('http://','https://','#','mailto:')):
            continue
        clean = url.split('#', 1)[0]
        if not clean:
            continue
        target = (markdown.parent / clean).resolve()
        if not target.exists():
            errors.append(f'Broken local link in {markdown.relative_to(root)}: {url}')

try:
    obj = json.loads((root / 'assets/design_tokens.json').read_text(encoding='utf-8'))
    assert len(obj['palette']) >= 8
except Exception as exc:
    errors.append(f'Design tokens invalid: {exc}')

if errors:
    for err in errors:
        print('ERROR:', err)
    sys.exit(1)
print(f'OK: {len(list(root.rglob("*.md")))} markdown documents, valid links, valid design tokens.')
