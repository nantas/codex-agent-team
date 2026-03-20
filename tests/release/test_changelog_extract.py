import subprocess
import sys


def test_extract_specific_version_block():
    result = subprocess.run(
        [
            sys.executable,
            ".agents/scripts/changelog_extract.py",
            "--version",
            "1.0.0",
            "--changelog-path",
            "CHANGELOG.md",
        ],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    assert "## [1.0.0]" not in result.stdout
    assert "### Added" in result.stdout
