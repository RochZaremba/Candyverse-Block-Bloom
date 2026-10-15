"""Meaningful edge cases for the release artifact/key safety tools."""
import struct
import subprocess
import tempfile
import unittest
from pathlib import Path

from audit_android_artifact import validate_elf, packaged_xml
from create_upload_key import outside_repository, properties_escape
from android_release_smoke import read_page_size, board_snapshot


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
    def test_s_piece_placement_does_not_require_occupied_origin(self):
        import xml.etree.ElementTree as ET
        occupied = {(1, 2), (1, 3), (2, 1), (2, 2)}
        nodes = [ET.Element('node', {'content-desc': f'Wiersz {r}, kolumna {c}, '+('zajęte' if (r, c) in occupied else 'puste')})
                 for r in range(1, 9) for c in range(1, 9)]
        snapshot = board_snapshot(nodes)
        self.assertFalse(snapshot[0])
        self.assertEqual(sum(snapshot), 4)
        self.assertEqual(snapshot, board_snapshot(list(reversed(nodes))))
        nodes[0].set('content-desc', 'Wiersz 1, kolumna 1, zajęte')
        self.assertNotEqual(snapshot, board_snapshot(nodes))

    def test_partial_board_is_not_accepted_as_restore_evidence(self):
        import xml.etree.ElementTree as ET
        with self.assertRaisesRegex(ValueError, 'complete board'):
            board_snapshot([ET.Element('node', {'text': 'Wiersz 1, kolumna 1, zajęte'})])

    def test_android7_page_size_falls_back_to_own_process_mapping(self):
        def old_android(*args):
            if args[1] == 'getconf':
                raise subprocess.CalledProcessError(127, args)
            return 'KernelPageSize:        4 kB\nMMUPageSize:           4 kB\n'
        self.assertEqual(read_page_size(old_android), 4096)

    def test_16kb_runtime_page_size_is_not_inferred_from_image_name(self):
        self.assertEqual(read_page_size(lambda *args: '16384'), 16384)
        with self.assertRaises(RuntimeError):
            read_page_size(lambda *args: '8192')


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
