from pathlib import Path


def test_release_workflow_has_required_steps():
    text = Path(".github/workflows/release.yml").read_text(encoding="utf-8")
    assert "on:" in text
    assert "tags:" in text and "v*" in text
    assert "generate_release_notes.py" in text
    assert "Agent Auto Install" in text or "release-notes" in text
