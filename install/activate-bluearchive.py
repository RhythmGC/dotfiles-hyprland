#!/usr/bin/env python3
"""Activate this checkout's BlueArchive runtime, preserving existing user settings.

Old names occur only here as migration inputs. Run without --apply to preview.
"""
import argparse
import datetime
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


def rename_text(text):
    for old, new in (
        ("quickshell/ii", "quickshell/ba"),
        ("quickshell/inir", "quickshell/ba"),
        ("illogical-impulse", "baOS"),
        (".config/inir", ".config/baOS"),
        ("ILLOGICAL_IMPULSE_VIRTUAL_ENV", "BA_VENV"),
        ("INIR", "BA"),
        ("iNiR", "BlueArchive"),
        ("Inir", "Ba"),
        ("BlueArchiveOS", "BlueArchive"),
    ):
        text = text.replace(old, new)
    text = re.sub(r"(?<![a-zA-ZÀ-ÿ])inir", "ba", text)
    text = re.sub(r"(?<![a-zA-Z])ii(?=$|[^\w]|[A-Z_])", "ba", text)
    return text


def migrate_config(value):
    if isinstance(value, dict):
        return {rename_text(k): migrate_config(v) for k, v in value.items()}
    if isinstance(value, list):
        return [migrate_config(v) for v in value]
    if isinstance(value, str):
        # Only identifiers and known paths, never arbitrary text, passwords or tokens.
        if value in ("ii", "inir") or re.fullmatch(r"ii[A-Z]\w*", value):
            return rename_text(value)
        if any(p in value for p in ("/quickshell/ii", "/quickshell/inir", "/illogical-impulse/")):
            return rename_text(value)
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    runtime = repo / ".config/quickshell/ba"
    home = Path.home()
    config = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    state = Path(os.environ.get("XDG_STATE_HOME", home / ".local/state"))
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup = state / "ba/migration-backups" / stamp
    print(f"Runtime: {runtime}")
    print(f"User config: {config / 'baOS'}")
    print(f"Backup: {backup}")
    if not args.apply:
        print("Preview only. Use --apply to activate and restart BlueArchive.")
        return

    backup.mkdir(parents=True)
    sequence = 0

    def save(path):
        nonlocal sequence
        sequence += 1
        target = backup / f"{sequence:03d}-{path.name}"
        if path.is_symlink():
            target.symlink_to(os.readlink(path))
        elif path.is_dir():
            shutil.copytree(path, target, symlinks=True)
        else:
            shutil.copy2(path, target)
        with (backup / "paths.jsonl").open("a") as stream:
            stream.write(json.dumps({"original": str(path), "backup": str(target)}) + "\n")

    def write(path, text, mode=None):
        path.parent.mkdir(parents=True, exist_ok=True)
        exists = path.exists()
        if exists and path.read_text() == text:
            return
        if exists or path.is_symlink():
            save(path)
        previous_mode = path.stat().st_mode & 0o777 if exists else 0o600
        temp = path.with_name(path.name + ".ba-new")
        temp.write_text(text)
        temp.chmod(mode if mode is not None else previous_mode)
        temp.replace(path)

    # Stop by instance ID: config paths may resolve through an old symlink.
    was_service_active = subprocess.run(
        ["systemctl", "--user", "is-active", "--quiet", "ba.service"]
    ).returncode == 0
    if was_service_active:
        subprocess.run(["systemctl", "--user", "stop", "ba.service"], check=True)
    instances = subprocess.run(["qs", "--no-color", "list", "--all"], capture_output=True, text=True, check=True)
    for block in re.split(r"(?=Instance )", instances.stdout):
        match = re.match(r"Instance ([\w]+):", block)
        if match and re.search(r"Shell ID: (?:inir|ii|ba)\s", block):
            subprocess.run(["qs", "kill", "-i", match[1]], check=True, timeout=15)

    data = config / "baOS"
    if not data.exists():
        for name in ("inir", "illogical-impulse"):
            old = config / name
            if old.is_dir():
                shutil.copytree(old, data, symlinks=True)
                break
        else:
            data.mkdir(parents=True)
            shutil.copy2(runtime / "defaults/config.json", data / "config.json")
    config_file = data / "config.json"
    if config_file.exists():
        write(config_file, json.dumps(migrate_config(json.loads(config_file.read_text())), ensure_ascii=False, indent=4) + "\n")

    # Update only existing shell integration files, preserving unrelated local edits.
    candidates = [config / "starship.toml"]
    for directory in ("fish", "hypr", "matugen", "kitty", "systemd/user"):
        parent = config / directory
        if parent.exists():
            candidates.extend(p for p in parent.rglob("*") if p.is_file() and not p.is_symlink())
    for path in candidates:
        if not path.is_file() or path.suffix not in (".fish", ".conf", ".lua", ".toml", ".sh", ".service", ".css"):
            continue
        try:
            original = path.read_text()
        except UnicodeError:
            continue
        renamed = rename_text(original)
        if renamed != original:
            write(path, renamed)
    for old in (config / "fish/conf.d/inir-env.fish", config / "fish/completions/inir.fish"):
        if old.exists():
            save(old)
            target = old.with_name(old.name.replace("inir", "ba"))
            if not target.exists():
                shutil.copy2(old, target)
            old.unlink()
    write(config / "fish/conf.d/ba-env.fish", '# BlueArchive Python environment\nset -gx BA_VENV "$HOME/.local/state/quickshell/.venv"\n')
    write(config / "fish/completions/ba.fish", (runtime / "scripts/completions/ba.fish").read_text())

    link = config / "quickshell/ba"
    if link.resolve() != runtime:
        if link.is_symlink():
            save(link)
            link.unlink()
        elif link.exists():
            save(link)
            shutil.move(str(link), str(backup / "previous-ba-runtime"))
        link.parent.mkdir(parents=True, exist_ok=True)
        link.symlink_to(runtime, target_is_directory=True)
    for name in ("ii", "inir"):
        old = config / "quickshell" / name
        if old.is_symlink():
            save(old)
            old.unlink()
        elif old.exists():
            # Move the full old runtime, including any local-only files, into the backup.
            target = backup / f"previous-{name}-runtime"
            shutil.move(str(old), str(target))
            with (backup / "paths.jsonl").open("a") as stream:
                stream.write(json.dumps({"original": str(old), "backup": str(target)}) + "\n")
    binary = home / ".local/bin/ba"
    write(binary, '#!/usr/bin/env bash\nexport BA_CMD=ba\nruntime="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ba"\nsource "$runtime/scripts/quickshell-env.sh"\nexec "$runtime/scripts/ba" "$@"\n', 0o755)
    for old in (home / ".local/bin/inir", config / "illogical-impulse", config / "inir"):
        if old.is_symlink():
            save(old)
            old.unlink()
    version_file = data / "version.json"
    version = json.loads(version_file.read_text()) if version_file.exists() else {}
    for key in ("repoPath", "repo_path"):
        version[key] = str(runtime)
    for key in ("installMode", "install_mode"):
        version[key] = "repo-link"
    for key in ("updateStrategy", "update_strategy"):
        version[key] = "repo-setup"
    write(version_file, json.dumps(version, indent=2) + "\n")
    subprocess.run(["systemctl", "--user", "daemon-reload"], check=True)
    if was_service_active:
        subprocess.run(["systemctl", "--user", "start", "ba.service"], check=True)
    else:
        subprocess.run([str(binary), "start"], check=True)
    print(f"BlueArchive activated. Backups: {backup}")


if __name__ == "__main__":
    main()
