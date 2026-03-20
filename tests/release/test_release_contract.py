from pathlib import Path


def test_release_contract_has_required_sections():
    text = Path("docs/release-contract.md").read_text(encoding="utf-8")
    for key in [
        "Prompt Triggers",
        "Version Resolution Rules",
        "Release Page Required Sections",
        "Agent Install Prompt Canonical Line",
        "Install Scope Mapping",
    ]:
        assert f"## {key}" in text
