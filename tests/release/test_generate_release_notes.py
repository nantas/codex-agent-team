import subprocess
import sys


def test_release_notes_include_required_install_prompt_line():
    result = subprocess.run(
        [
            sys.executable,
            ".agents/scripts/generate_release_notes.py",
            "--repo",
            "acme/codex-agent-team",
            "--version",
            "1.0.0",
            "--changelog-path",
            "CHANGELOG.md",
        ],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    assert "## Changelog" in result.stdout
    assert "## Agent Auto Install" in result.stdout
    assert (
        "https://github.com/acme/codex-agent-team/blob/v1.0.0/.agents/INSTALL.md"
        in result.stdout
    )
