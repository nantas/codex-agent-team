from pathlib import Path


def test_install_guide_enforces_agents_skills_only():
    text = Path(".agents/INSTALL.md").read_text(encoding="utf-8")
    assert ".agents/skills" in text
    assert ".codex/skills" not in text
