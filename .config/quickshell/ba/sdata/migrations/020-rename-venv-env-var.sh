#!/usr/bin/env bash
# Retired: BlueArchive uses baOS and BA_VENV directly.
MIGRATION_ID="020-rename-venv-env-var"
MIGRATION_TITLE="BlueArchive canonical environment"
MIGRATION_DESCRIPTION="No compatibility aliases are required."
MIGRATION_REQUIRED=false
migration_check() { return 1; }
migration_preview() { :; }
migration_apply() { :; }
