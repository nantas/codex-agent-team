import os
import shutil
import subprocess
import tempfile
from pathlib import Path


def run(cmd: str, cwd: str) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)


def test_install_script_requires_scope_or_interactive_flag():
    p = run("bash .agents/install-local.sh", cwd=".")
    assert p.returncode != 0
    assert "--scope project|global" in p.stderr


def test_install_script_project_scope_installs_into_target_dir():
    tmp = tempfile.mkdtemp(prefix="install-target-")
    try:
        p = run(
            (
                "bash .agents/install-local.sh "
                "--scope project "
                "--repo \"$PWD\" "
                f"--target-dir \"{tmp}\" "
                "--skill-name codex-agent-team-test"
            ),
            cwd=".",
        )
        assert p.returncode == 0, p.stderr
        assert Path(tmp, "codex-agent-team-test", "SKILL.md").is_file()
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
