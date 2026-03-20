from pathlib import Path


def test_repo_docs_prefer_agents_install_path():
    corpus = "\n".join(
        Path(p).read_text(encoding="utf-8")
        for p in ["README.md", ".codex/INSTALL.md", "docs/release-operations.md"]
    )
    assert ".agents/skills" in corpus
