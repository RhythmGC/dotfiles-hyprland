#!/usr/bin/env python3
"""Regression checks for preserving personal data during the namespace migration."""
import sys
import unittest
import importlib.util
from pathlib import Path

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("activation", Path(__file__).with_name("activate-bluearchive.py"))
activation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(activation)


class MigrationTests(unittest.TestCase):
    def test_identifiers_paths_and_personal_data(self):
        original = {
            "panelFamily": "ii",
            "enabledPanels": ["iiBar", "iiDock", "waffleBar"],
            "appearance": {"globalStyle": "inir", "rounding": {"inir": 1}},
            "path": "/home/example/.config/quickshell/ii/scripts/ba",
            "notes": "définir ii inir",
            "network": {"password": "example-inir-value"},
        }
        migrated = activation.migrate_config(original)
        self.assertEqual(migrated["panelFamily"], "ba")
        self.assertEqual(migrated["enabledPanels"], ["baBar", "baDock", "waffleBar"])
        self.assertEqual(migrated["appearance"], {"globalStyle": "ba", "rounding": {"ba": 1}})
        self.assertEqual(migrated["path"], "/home/example/.config/quickshell/ba/scripts/ba")
        self.assertEqual(migrated["notes"], original["notes"])
        self.assertEqual(migrated["network"], original["network"])
        self.assertEqual(activation.migrate_config(migrated), migrated)
        self.assertEqual(original["panelFamily"], "ii")


if __name__ == "__main__":
    unittest.main()
