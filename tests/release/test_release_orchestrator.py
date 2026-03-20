import re
import subprocess


def run(cmd: str) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)


def test_release_orchestrator_supports_patch_bump_dry_run():
    p = run(
        "bash .agents/release.sh "
        "--intent '发布新版本' "
        "--bump patch "
        "--repo acme/codex-agent-team "
        "--dry-run"
    )
    assert p.returncode == 0, p.stderr
    assert "TARGET_VERSION=1.0.1" in p.stdout


def test_release_orchestrator_supports_explicit_version_intent():
    p = run(
        "bash .agents/release.sh "
        "--intent '发布 v1.4.0' "
        "--repo acme/codex-agent-team "
        "--dry-run"
    )
    assert p.returncode == 0, p.stderr
    assert "TARGET_VERSION=1.4.0" in p.stdout


def test_release_orchestrator_rejects_invalid_version():
    p = run(
        "bash .agents/release.sh "
        "--intent '发布 v1.4' "
        "--repo acme/codex-agent-team "
        "--dry-run"
    )
    assert p.returncode != 0


def test_release_orchestrator_dry_run_does_not_mutate_git_head():
    head_before = run("git rev-parse HEAD")
    assert head_before.returncode == 0
    p = run(
        "bash .agents/release.sh "
        "--intent '发布 v1.5.0' "
        "--repo acme/codex-agent-team "
        "--dry-run"
    )
    assert p.returncode == 0, p.stderr
    head_after = run("git rev-parse HEAD")
    assert head_after.returncode == 0
    assert head_before.stdout.strip() == head_after.stdout.strip()
    assert re.search(r"TARGET_VERSION=1.5.0", p.stdout)
