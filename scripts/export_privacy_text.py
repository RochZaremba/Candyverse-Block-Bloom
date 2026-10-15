#!/usr/bin/env python3
"""Export the same bilingual policy for bundled, offline in-app reading."""
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class Policy(HTMLParser):
    def __init__(self):
        super().__init__()
        self.language = None
        self.block = None
        self.buffer = []
        self.sections = {'pl': [], 'en': []}

    def handle_starttag(self, tag, attributes):
        if tag == 'section':
            self.language = dict(attributes).get('lang')
        if self.language in self.sections and tag in ('h2', 'h3', 'p', 'dt', 'dd'):
            self.block = tag
            self.buffer = []

    def handle_data(self, data):
        if self.block:
            self.buffer.append(data)

    def handle_endtag(self, tag):
        if tag == self.block:
            self.sections[self.language].append(' '.join(''.join(self.buffer).split()))
            self.block = None
        if tag == 'section':
            self.language = None


if __name__ == '__main__':
    policy = Policy()
    policy.feed((ROOT/'public_pages/index.html').read_text())
    destination = ROOT/'assets/privacy'
    destination.mkdir(exist_ok=True)
    for language, paragraphs in policy.sections.items():
        if not paragraphs or not any('rochzaremba@gmail.com' in p for p in paragraphs):
            raise ValueError('Policy lacks publisher contact or translated content.')
        (destination/f'policy_{language}.txt').write_text('\n\n'.join(paragraphs)+'\n')
