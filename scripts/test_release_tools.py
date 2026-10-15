"""Meaningful edge cases for the release artifact/key safety tools."""
import struct
import tempfile
import unittest
from pathlib import Path

from audit_android_artifact import validate_elf, packaged_xml
from create_upload_key import outside_repository, properties_escape


def native_library(segments):
    data = bytearray(64+56*len(segments))
    data[:6] = b'\x7fELF\x02\x01'
    struct.pack_into('<Q', data, 32, 64)
    struct.pack_into('<HH', data, 54, 56, len(segments))
    for index, (kind, alignment, offset, address, size) in enumerate(segments):
        struct.pack_into('<IIQQQQQQ', data, 64+56*index,
                         kind, 6, offset, address, address, size, size, alignment)
    return data


class ReleaseToolsTests(unittest.TestCase):
    def test_resolves_shrunk_and_development_xml_from_resource_table(self):
        for path in ('res/Qq.xml', 'res/xml/backup_rules.xml'):
            resources = f'    resource 0x7f100000 xml/backup_rules\n      () (file) {path} type=XML\n'
            self.assertEqual(packaged_xml(resources, 'backup_rules'), ('0x7f100000', path))
        with self.assertRaises(ValueError):
            packaged_xml(resources, 'data_extraction_rules')

    def test_rejects_missing_default_or_parent_traversal_xml_path(self):
        for variant in ('(v31) (file) res/Qq.xml', '() (file) res/../Qq.xml'):
            with self.assertRaises(ValueError):
                packaged_xml(f'resource 0x7f100000 xml/backup_rules\n {variant} type=XML\n', 'backup_rules')

    def test_store_icon_matches_play_file_requirements(self):
        from PIL import Image
        path = Path(__file__).resolve().parent.parent/'assets/brand/store_icon_512.png'
        with Image.open(path) as icon:
            self.assertEqual(icon.size, (512, 512))
            self.assertEqual(icon.mode, 'RGBA')
            self.assertEqual(icon.getchannel('A').getextrema(), (255, 255))
            self.assertIn('srgb', icon.info)
        self.assertLess(path.stat().st_size, 1024*1024)

    def test_rejects_4kb_load_even_if_relro_is_aligned(self):
        with self.assertRaisesRegex(ValueError, 'PT_LOAD'):
            validate_elf(native_library([(1, 4096, 0, 0, 16384)]))

    def test_accepts_relro_covering_entire_load_like_flutter(self):
        validate_elf(native_library([(1, 65536, 0, 0, 20480),
                                    (0x6474e552, 1, 0, 0, 20480)]))

    def test_rejects_partial_relro_not_aligned_to_16kb(self):
        with self.assertRaisesRegex(ValueError, 'partial RELRO'):
            validate_elf(native_library([(1, 16384, 0, 0, 32768),
                                        (0x6474e552, 1, 0, 0, 20480)]))

    def test_accepts_aligned_partial_relro(self):
        validate_elf(native_library([(1, 16384, 0, 0, 32768),
                                    (0x6474e552, 1, 0, 0, 16384)]))

    def test_rejects_corrupted_header(self):
        with self.assertRaises(ValueError):
            validate_elf(b'\x7fELF')
        data = native_library([(1, 16384, 0, 0, 32768)])
        struct.pack_into('<Q', data, 32, 999999)
        with self.assertRaises(ValueError):
            validate_elf(data)

    def test_cannot_generate_key_in_any_worktree(self):
        with self.assertRaisesRegex(ValueError, 'outside'):
            outside_repository(Path(__file__).resolve().parent/'private-key')

    def test_external_symlink_into_worktree_is_also_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            link = Path(directory)/'repo-link'
            link.symlink_to(Path(__file__).resolve().parent)
            with self.assertRaisesRegex(ValueError, 'outside'):
                outside_repository(link/'private-key')

    def test_properties_paths_escape_java_delimiters(self):
        self.assertEqual(properties_escape(r'C:\private keys\upload.p12'),
                         r'C\:\\private\ keys\\upload.p12')


if __name__ == '__main__':
    unittest.main()
