"""Meaningful edge cases for the release artifact/key safety tools."""
import struct
import tempfile
import unittest
from pathlib import Path

from audit_android_artifact import validate_elf
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
