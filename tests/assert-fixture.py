#!/usr/bin/env python3
"""Layered fixture assertion CLI for codex-agent-team V1 harness."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Sequence, Tuple


SUPPORTED_FIXTURES = {
    "basic-happy-path",
    "role-override-path",
    "checkpoint-path",
    "recovery-prep-path",
    "interaction-protocol-path",
    "resource-safety-path",
    "emfile-downgrade-path",
}

REQUIRED_README_SECTIONS = [
    "fixture id",
    "prompt/input shape",
    "expected phase markers",
    "expected filesystem artifacts",
    "must-not-happen markers",
]


@dataclass
class AssertionState:
    fixture: str
    run_dir: Path
    fixture_readme: Path
    manifest_path: Path
    manifest: Dict = field(default_factory=dict)
    readme_sections: Dict[str, List[str]] = field(default_factory=dict)
    session_files: List[Path] = field(default_factory=list)
    filesystem_files: List[Path] = field(default_factory=list)
    session_text: str = ""
    marker_pool: List[str] = field(default_factory=list)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Assert a codex-agent-team fixture run with layered checks."
    )
    parser.add_argument("--fixture", required=True, help="Fixture name to assert")
    parser.add_argument(
        "--run-dir",
        required=True,
        help="Run directory path, e.g. tests/out/basic-happy-path/<run-id>",
    )
    return parser.parse_args()


def fail(message: str, *, layer: str | None = None) -> None:
    prefix = f"[{layer}] " if layer else ""
    print(f"FAIL {prefix}{message}")
    raise AssertionError(message)


def parse_readme_sections(readme_path: Path) -> Dict[str, List[str]]:
    sections: Dict[str, List[str]] = {}
    current = None
    heading_re = re.compile(r"^##\s+(.*\S)\s*$")

    for raw in readme_path.read_text(encoding="utf-8").splitlines():
        heading_match = heading_re.match(raw)
        if heading_match:
            current = heading_match.group(1).strip().lower()
            sections[current] = []
            continue
        if current is None:
            continue
        line = raw.strip()
        if not line:
            continue
        if line.startswith("- "):
            item = line[2:].strip()
            if item.startswith("`") and item.endswith("`") and len(item) >= 2:
                item = item[1:-1]
            sections[current].append(item)
        else:
            sections[current].append(line)
    return sections


def try_load_json(path: Path) -> Dict:
    return json.loads(path.read_text(encoding="utf-8"))


def find_manifest(run_dir: Path) -> Path | None:
    candidates = [
        run_dir / "artifacts" / "manifest.json",
        run_dir / "manifest.json",
        run_dir / "artifacts-manifest.json",
    ]
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return None


def collect_evidence_paths(run_dir: Path, manifest: Dict) -> Tuple[List[Path], List[Path]]:
    def _resolve(path_like: str) -> Path:
        path = Path(path_like)
        return path if path.is_absolute() else (run_dir / path)

    session: List[Path] = []
    fs: List[Path] = []

    # Preferred contract: evidence.filesystem.files / evidence.session_logs.files
    evidence = manifest.get("evidence", {})
    fs_entries = evidence.get("filesystem", {}).get("files", [])
    session_entries = evidence.get("session_logs", {}).get("files", [])

    # Compatibility contract: top-level arrays.
    fs_entries = fs_entries or manifest.get("filesystem_evidence_files", [])
    session_entries = session_entries or manifest.get("session_log_files", [])

    for item in fs_entries:
        if isinstance(item, str):
            fs.append(_resolve(item))
    for item in session_entries:
        if isinstance(item, str):
            session.append(_resolve(item))

    # Last fallback: infer from artifacts folders when manifest leaves file lists empty.
    if not fs:
        inferred_fs_root = run_dir / "artifacts" / "filesystem"
        if inferred_fs_root.is_dir():
            fs.extend([p for p in inferred_fs_root.rglob("*") if p.is_file()])
    if not session:
        for directory_name in ("session-logs", "session"):
            inferred_session_root = run_dir / "artifacts" / directory_name
            if inferred_session_root.is_dir():
                session.extend([p for p in inferred_session_root.rglob("*") if p.is_file()])
                if session:
                    break

    return fs, session


def load_marker_pool(manifest: Dict, session_text: str) -> List[str]:
    markers: List[str] = []
    candidate_lists: Sequence = [
        manifest.get("phase_markers", []),
        manifest.get("emitted_markers", []),
        manifest.get("observed_markers", []),
        manifest.get("markers", []),
    ]
    for maybe_list in candidate_lists:
        if isinstance(maybe_list, list):
            for marker in maybe_list:
                if isinstance(marker, str):
                    markers.append(marker)

    # Parse markers from session text: marker:<name> or [marker] <name>
    marker_patterns = [
        re.compile(r"\bmarker:\s*([A-Za-z0-9._/-]+)"),
        re.compile(r"\[marker\]\s*([A-Za-z0-9._/-]+)", flags=re.IGNORECASE),
    ]
    for line in session_text.splitlines():
        for pattern in marker_patterns:
            match = pattern.search(line)
            if match:
                markers.append(match.group(1))
    return sorted(set(markers))


def logical_artifact_paths(run_dir: Path, files: Sequence[Path]) -> Tuple[set[str], Dict[str, Path]]:
    aliases: set[str] = set()
    resolved: Dict[str, Path] = {}
    for path in files:
        candidates = [path.name]
        if path.is_relative_to(run_dir):
            rel = path.relative_to(run_dir).as_posix()
            candidates.append(rel)
            if rel.startswith("artifacts/filesystem/multi-agent/"):
                candidates.append(
                    ".codex/multi-agent/" + rel.removeprefix("artifacts/filesystem/multi-agent/")
                )
            if rel.startswith("workspace/.codex/multi-agent/"):
                candidates.append(
                    ".codex/multi-agent/" + rel.removeprefix("workspace/.codex/multi-agent/")
                )
        for candidate in candidates:
            aliases.add(candidate.lower())
            resolved[candidate.lower()] = path
    return aliases, resolved


def artifact_matches(
    run_dir: Path, files: Sequence[Path], artifact_spec: str
) -> Tuple[Path | None, str, str | None]:
    path_part, _, condition = artifact_spec.partition("::")
    aliases, resolved = logical_artifact_paths(run_dir, files)
    target = path_part.strip().lower()

    if target in aliases:
        return resolved[target], path_part.strip(), condition or None

    basename = Path(path_part.strip()).name.lower()
    if basename in aliases:
        return resolved[basename], path_part.strip(), condition or None

    return None, path_part.strip(), condition or None


def nested_value(payload: object, key: str) -> object:
    current = payload
    for part in key.split("."):
        if not isinstance(current, dict) or part not in current:
            raise KeyError(key)
        current = current[part]
    return current


def validate_artifact_condition(path: Path, condition: str | None) -> None:
    if not condition:
        return

    name, _, value = condition.partition("=")
    if name == "json_key":
        payload = json.loads(path.read_text(encoding="utf-8"))
        nested_value(payload, value)
        return
    if name == "json_non_empty":
        payload = json.loads(path.read_text(encoding="utf-8"))
        found = nested_value(payload, value)
        if found in ("", [], {}, None):
            raise AssertionError(f"JSON key '{value}' in {path} is empty")
        return
    if name == "json_array_non_empty":
        payload = json.loads(path.read_text(encoding="utf-8"))
        found = nested_value(payload, value)
        if not isinstance(found, list) or not found:
            raise AssertionError(f"JSON array '{value}' in {path} is empty or not a list")
        return
    if name == "jsonl_non_empty" and value == "true":
        lines = [line for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
        if not lines:
            raise AssertionError(f"JSONL file {path} is empty")
        for line in lines:
            json.loads(line)
        return
    raise AssertionError(f"unsupported artifact condition '{condition}'")


def assert_specialist_user_route(state: AssertionState, *, layer: str) -> None:
    team_path, _, _ = artifact_matches(
        state.run_dir, state.filesystem_files, ".codex/multi-agent/team.json"
    )
    if team_path is None:
        fail("missing team artifact '.codex/multi-agent/team.json'", layer=layer)
    team_payload = json.loads(team_path.read_text(encoding="utf-8"))
    charter = team_payload.get("charter")
    if not isinstance(charter, list) or not charter:
        fail("team.json charter must be a non-empty list", layer=layer)
    for entry in charter:
        if not isinstance(entry, dict):
            continue
        role_id = entry.get("role_id")
        if role_id and role_id != "lead":
            if entry.get("user_interaction_route") != "via_lead":
                fail(
                    f"team.json role '{role_id}' must use user_interaction_route='via_lead'",
                    layer=layer,
                )


def assert_compact_recovery_schema(state: AssertionState, *, layer: str) -> None:
    compact_path, _, _ = artifact_matches(
        state.run_dir, state.filesystem_files, ".codex/multi-agent/compact-recovery.json"
    )
    if compact_path is None:
        fail("missing compact recovery artifact '.codex/multi-agent/compact-recovery.json'", layer=layer)
    payload = json.loads(compact_path.read_text(encoding="utf-8"))
    if "suspendedAgents" not in payload:
        fail("compact-recovery.json missing required key 'suspendedAgents'", layer=layer)
    if not isinstance(payload.get("suspendedAgents"), list):
        fail("compact-recovery.json key 'suspendedAgents' must be a list", layer=layer)


def assert_resource_safety_contract(state: AssertionState, *, layer: str) -> None:
    compact_path, _, _ = artifact_matches(
        state.run_dir, state.filesystem_files, ".codex/multi-agent/compact-recovery.json"
    )
    if compact_path is None:
        fail("missing compact recovery artifact '.codex/multi-agent/compact-recovery.json'", layer=layer)
    payload = json.loads(compact_path.read_text(encoding="utf-8"))
    entries = payload.get("suspendedAgents")
    if not isinstance(entries, list) or not entries:
        fail("resource-safety-path requires non-empty suspendedAgents", layer=layer)

    required = {
        "agent_id",
        "role_id",
        "task_id",
        "status",
        "suspend_reason",
        "handoff_checkpoint_id",
        "resume_input",
    }
    for i, entry in enumerate(entries):
        if not isinstance(entry, dict):
            fail(f"suspendedAgents[{i}] must be an object", layer=layer)
        missing = sorted(required - set(entry.keys()))
        if missing:
            fail(f"suspendedAgents[{i}] missing required keys: {missing}", layer=layer)

    sorted_entries = sorted(
        entries, key=lambda item: (item["handoff_checkpoint_id"], item["agent_id"])
    )
    if entries != sorted_entries:
        fail(
            "suspendedAgents must be in deterministic order by handoff_checkpoint_id then agent_id",
            layer=layer,
        )


def assert_emfile_downgrade_contract(state: AssertionState, *, layer: str) -> None:
    session_path, _, _ = artifact_matches(
        state.run_dir, state.filesystem_files, ".codex/multi-agent/session.json"
    )
    if session_path is None:
        fail("missing session artifact '.codex/multi-agent/session.json'", layer=layer)
    payload = json.loads(session_path.read_text(encoding="utf-8"))
    if payload.get("execution_mode") != "serial":
        fail("EMFILE downgrade fixture requires session.execution_mode='serial'", layer=layer)

    fd_downgrade = payload.get("fd_downgrade")
    if not isinstance(fd_downgrade, dict):
        fail("session.json missing required object 'fd_downgrade'", layer=layer)
    if fd_downgrade.get("active") is not True:
        fail("fd_downgrade.active must be true while EMFILE guardrail is active", layer=layer)
    trigger = str(fd_downgrade.get("trigger", "")).lower()
    if trigger not in {"emfile", "too many open files", "os error 24"}:
        fail(
            "fd_downgrade.trigger must be one of: EMFILE / Too many open files / os error 24",
            layer=layer,
        )
    if fd_downgrade.get("pause_spawn_waves") is not True:
        fail("fd_downgrade.pause_spawn_waves must be true during downgrade", layer=layer)
    if fd_downgrade.get("mode_before") != "parallel" or fd_downgrade.get("mode_after") != "serial":
        fail("fd_downgrade mode transition must be parallel -> serial", layer=layer)


def _collect_indentation_violations(lines: Sequence[str]) -> List[str]:
    violations: List[str] = []
    for raw in lines:
        if not raw or not raw.startswith(" "):
            continue
        leading_spaces = len(raw) - len(raw.lstrip(" "))
        if leading_spaces not in (2, 4):
            violations.append(raw)
    return violations


def _parse_expanded_block(lines: Sequence[str], start_idx: int) -> Dict[str, str]:
    fields: Dict[str, str] = {}
    i = start_idx + 1
    while i < len(lines):
        line = lines[i]
        if not line.startswith(" "):
            break
        primary = re.match(r"^\s{2}([a-z_]+):\s*(.*)$", line)
        secondary = re.match(r"^\s{4}([a-z_]+):\s*(.*)$", line)
        if primary:
            fields[primary.group(1)] = primary.group(2)
        elif secondary:
            fields[secondary.group(1)] = secondary.group(2)
        i += 1
    return fields


def assert_interaction_display_contract(state: AssertionState, *, layer: str) -> None:
    lines = state.session_text.splitlines()

    indent_violations = _collect_indentation_violations(lines)
    if indent_violations:
        fail(f"indentation contract violated: {indent_violations[0]}", layer=layer)
    if any((len(x) - len(x.lstrip(" "))) > 4 for x in lines if x.startswith(" ")):
        fail("indentation depth exceeded level 2", layer=layer)

    sent_collapsed_re = re.compile(
        r"^\[(?P<ts>[^\]]+)\] Sent input -> (?P<target>.+?) \| (?P<task_id>.+?) \| "
        r"(?P<intent>.+?) \| (?P<body>.+)$"
    )
    wait_collapsed_re = re.compile(
        r"^\[(?P<ts>[^\]]+)\] Finished waiting -> (?P<target>.+?) \| "
        r"(?P<status>completed|failed|timeout|cancelled) \| (?P<elapsed>\d+)ms \| (?P<result>.+)$"
    )

    sent_collapsed_idx = -1
    wait_collapsed_idx = -1
    sent_collapsed_match = None
    wait_collapsed_match = None
    sent_expanded_idx = -1
    wait_expanded_idx = -1

    for i, line in enumerate(lines):
        if sent_collapsed_idx < 0:
            m = sent_collapsed_re.match(line)
            if m:
                sent_collapsed_idx = i
                sent_collapsed_match = m
                continue
        if wait_collapsed_idx < 0:
            m = wait_collapsed_re.match(line)
            if m:
                wait_collapsed_idx = i
                wait_collapsed_match = m
                continue
        if sent_expanded_idx < 0 and re.match(r"^\[[^\]]+\] Sent input$", line):
            sent_expanded_idx = i
            continue
        if wait_expanded_idx < 0 and re.match(r"^\[[^\]]+\] Finished waiting$", line):
            wait_expanded_idx = i

    if sent_collapsed_idx < 0 or sent_collapsed_match is None:
        fail("missing collapsed 'Sent input' line", layer=layer)
    if wait_collapsed_idx < 0 or wait_collapsed_match is None:
        fail("missing collapsed 'Finished waiting' line", layer=layer)
    if sent_expanded_idx < 0:
        fail("missing expanded 'Sent input' block", layer=layer)
    if wait_expanded_idx < 0:
        fail("missing expanded 'Finished waiting' block", layer=layer)

    if sent_collapsed_idx > sent_expanded_idx:
        fail("summary-first violated for 'Sent input'", layer=layer)
    if wait_collapsed_idx > wait_expanded_idx:
        fail("summary-first violated for 'Finished waiting'", layer=layer)

    sent_collapsed_line = lines[sent_collapsed_idx]
    wait_collapsed_line = lines[wait_collapsed_idx]
    if len(sent_collapsed_line) > 100:
        fail("collapsed 'Sent input' exceeds default width 100", layer=layer)
    if len(wait_collapsed_line) > 100:
        fail("collapsed 'Finished waiting' exceeds default width 100", layer=layer)

    sent_fields = _parse_expanded_block(lines, sent_expanded_idx)
    wait_fields = _parse_expanded_block(lines, wait_expanded_idx)
    for key in ("target", "task_id", "intent", "topic", "body"):
        if key not in sent_fields:
            fail(f"expanded 'Sent input' missing field '{key}'", layer=layer)
    for key in ("target", "status", "elapsed_ms", "result", "next_action"):
        if key not in wait_fields:
            fail(f"expanded 'Finished waiting' missing field '{key}'", layer=layer)

    if sent_collapsed_match.group("target").strip() != sent_fields["target"].strip():
        fail("target mismatch between collapsed/expanded 'Sent input'", layer=layer)
    if sent_collapsed_match.group("task_id").strip() != sent_fields["task_id"].strip():
        fail("task_id mismatch between collapsed/expanded 'Sent input'", layer=layer)
    if wait_collapsed_match.group("target").strip() != wait_fields["target"].strip():
        fail("target mismatch between collapsed/expanded 'Finished waiting'", layer=layer)
    if wait_collapsed_match.group("status").strip() != wait_fields["status"].strip():
        fail("status mismatch between collapsed/expanded 'Finished waiting'", layer=layer)
    if wait_collapsed_match.group("elapsed").strip() != wait_fields["elapsed_ms"].strip():
        fail("elapsed_ms mismatch between collapsed/expanded 'Finished waiting'", layer=layer)

    body_value = sent_fields["body"]
    body_excerpt = sent_collapsed_match.group("body").strip()
    if len(body_value) > 140 and not body_excerpt.endswith("..."):
        fail("long body field must be truncated with ellipsis in collapsed view", layer=layer)

def assert_existence(state: AssertionState) -> None:
    layer = "existence"
    if state.fixture not in SUPPORTED_FIXTURES:
        fail(
            f"unsupported fixture '{state.fixture}'. Supported: {', '.join(sorted(SUPPORTED_FIXTURES))}",
            layer=layer,
        )
    if not state.run_dir.exists() or not state.run_dir.is_dir():
        fail(f"run directory not found: {state.run_dir}", layer=layer)
    if not state.fixture_readme.is_file():
        fail(f"fixture README not found: {state.fixture_readme}", layer=layer)

    manifest = find_manifest(state.run_dir)
    if manifest is None:
        fail(
            f"missing manifest. Expected one of: "
            f"{state.run_dir / 'artifacts' / 'manifest.json'}, "
            f"{state.run_dir / 'manifest.json'}, "
            f"{state.run_dir / 'artifacts-manifest.json'}",
            layer=layer,
        )
    state.manifest_path = manifest

    state.manifest = try_load_json(state.manifest_path)
    state.readme_sections = parse_readme_sections(state.fixture_readme)
    state.filesystem_files, state.session_files = collect_evidence_paths(
        state.run_dir, state.manifest
    )

    if not state.filesystem_files:
        fail("filesystem evidence missing (no files discovered)", layer=layer)
    if not state.session_files:
        fail("session-log evidence missing (no files discovered)", layer=layer)

    print(f"PASS [{layer}] fixture/run/manifest and both evidence channels exist")


def assert_structural(state: AssertionState) -> None:
    layer = "structural"
    for section in REQUIRED_README_SECTIONS:
        if section not in state.readme_sections:
            fail(
                f"fixture README missing required section '## {section.title()}'",
                layer=layer,
            )
        if not state.readme_sections.get(section):
            fail(
                f"fixture README section '## {section.title()}' is empty",
                layer=layer,
            )

    # Minimum manifest shape.
    if not isinstance(state.manifest, dict):
        fail("manifest root must be an object", layer=layer)
    if "fixture" in state.manifest and state.manifest["fixture"] != state.fixture:
        fail(
            f"manifest fixture mismatch: expected '{state.fixture}', found '{state.manifest['fixture']}'",
            layer=layer,
        )

    missing_refs = [str(p) for p in state.filesystem_files + state.session_files if not p.is_file()]
    if missing_refs:
        fail(f"manifest references missing files: {missing_refs}", layer=layer)

    # Validate JSON state artifacts where applicable.
    json_artifacts = [p for p in state.filesystem_files if p.suffix == ".json"]
    for path in json_artifacts:
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            fail(f"invalid JSON artifact {path}: {exc}", layer=layer)

    print(f"PASS [{layer}] README sections and manifest/artifact structure are valid")


def assert_semantic(state: AssertionState) -> None:
    layer = "semantic"
    state.session_text = "\n".join(
        p.read_text(encoding="utf-8", errors="replace") for p in state.session_files
    )
    state.marker_pool = load_marker_pool(state.manifest, state.session_text)

    required_markers = state.readme_sections.get("expected phase markers", [])
    required_artifacts = state.readme_sections.get("expected filesystem artifacts", [])

    lower_session_text = state.session_text.lower()
    lower_markers = {m.lower() for m in state.marker_pool}
    fs_aliases, _ = logical_artifact_paths(state.run_dir, state.filesystem_files)

    for marker in required_markers:
        marker_l = marker.lower()
        if marker_l not in lower_markers and marker_l not in lower_session_text:
            fail(f"required phase marker missing: '{marker}'", layer=layer)

    for artifact in required_artifacts:
        match, matched_spec, condition = artifact_matches(
            state.run_dir, state.filesystem_files, artifact
        )
        if match is None:
            fail(f"required filesystem artifact missing: '{artifact}'", layer=layer)
        try:
            validate_artifact_condition(match, condition)
        except (AssertionError, KeyError, json.JSONDecodeError) as exc:
            fail(f"artifact condition failed for '{matched_spec}': {exc}", layer=layer)

    assert_specialist_user_route(state, layer=layer)
    assert_compact_recovery_schema(state, layer=layer)
    if state.fixture == "interaction-protocol-path":
        assert_interaction_display_contract(state, layer=layer)
    if state.fixture == "resource-safety-path":
        assert_resource_safety_contract(state, layer=layer)
    if state.fixture == "emfile-downgrade-path":
        assert_emfile_downgrade_contract(state, layer=layer)

    # Fixture-specific explicit semantic rules.
    fixture_rules = {
        "basic-happy-path": {
            "markers": ["panel-confirmed", "team-formed"],
            "artifacts": ["panel.json", "tasks.json"],
        },
        "role-override-path": {
            "markers": ["role-override-confirmed", "role-override-applied"],
            "artifacts": ["team.json"],
        },
        "checkpoint-path": {
            "markers": ["checkpoint-triggered", "checkpoint-persisted"],
            "artifacts": ["checkpoints.json"],
        },
        "recovery-prep-path": {
            "markers": ["recovery-prep-refreshed"],
            "artifacts": ["compact-recovery.json"],
        },
        "interaction-protocol-path": {
            "markers": [
                "interaction-display-contract-passed",
                "interaction-display-semantics-consistent",
            ],
            "artifacts": ["session.json", "checkpoints.json"],
        },
        "resource-safety-path": {
            "markers": [
                "resource-close-cleanup-confirmed",
                "resource-resume-sequenced",
            ],
            "artifacts": ["compact-recovery.json", "session.json", "checkpoints.json"],
        },
        "emfile-downgrade-path": {
            "markers": [
                "resource-emfile-downgrade-triggered",
                "resource-emfile-serial-guard-active",
            ],
            "artifacts": ["session.json", "checkpoints.json", "compact-recovery.json"],
        },
    }
    rule = fixture_rules[state.fixture]
    for marker in rule["markers"]:
        marker_l = marker.lower()
        if marker_l not in lower_markers and marker_l not in lower_session_text:
            fail(
                f"fixture-specific marker missing for {state.fixture}: '{marker}'",
                layer=layer,
            )
    for artifact in rule["artifacts"]:
        artifact_name = Path(artifact).name.lower()
        if artifact_name not in fs_aliases:
            fail(
                f"fixture-specific artifact missing for {state.fixture}: '{artifact}'",
                layer=layer,
            )

    print(f"PASS [{layer}] generic and fixture-specific semantics hold")


def assert_must_not_happen(state: AssertionState) -> None:
    layer = "must-not-happen"
    forbidden = state.readme_sections.get("must-not-happen markers", [])

    fixture_forbidden = {
        "basic-happy-path": ["orchestration-before-panel-confirmation"],
        "role-override-path": ["silently-fallback-to-default-roles-after-override"],
        "checkpoint-path": ["checkpoint-skipped-at-required-boundary"],
        "recovery-prep-path": ["finish-without-recovery-prep-state-update"],
        "interaction-protocol-path": [
            "interaction.display.expanded_before_collapsed",
            "interaction.display.indentation.depth_exceeded",
            "interaction.display.unbounded_field_value",
        ],
        "resource-safety-path": [
            "resource.close_agent.skipped",
            "resource.resume_without_checkpoint_handoff",
            "resource.suspended_agents_stale",
        ],
        "emfile-downgrade-path": [
            "resource.emfile_spawn_wave_continued",
            "resource.emfile_downgrade_undocumented",
            "resource.emfile_parallel_before_stable",
        ],
    }
    forbidden = forbidden + fixture_forbidden[state.fixture]

    lower_session_text = state.session_text.lower()
    lower_markers = {m.lower() for m in state.marker_pool}
    manifest_forbidden = {
        str(x).lower()
        for x in state.manifest.get("must_not_happen_markers", [])
        if isinstance(x, str)
    }

    for marker in forbidden:
        marker_l = marker.lower()
        if marker_l in lower_markers or marker_l in lower_session_text or marker_l in manifest_forbidden:
            fail(f"forbidden marker observed: '{marker}'", layer=layer)

    print(f"PASS [{layer}] no forbidden markers observed")


def main() -> int:
    args = parse_args()
    run_dir = Path(args.run_dir).expanduser().resolve()
    fixture = args.fixture.strip()
    state = AssertionState(
        fixture=fixture,
        run_dir=run_dir,
        fixture_readme=Path("fixtures") / fixture / "README.md",
        manifest_path=Path(),
    )

    layers = [
        ("existence", assert_existence),
        ("structural", assert_structural),
        ("semantic", assert_semantic),
        ("must-not-happen", assert_must_not_happen),
    ]

    try:
        for _, check in layers:
            check(state)
    except AssertionError:
        print(f"RESULT: FAIL fixture={fixture} run_dir={run_dir}")
        return 1
    except FileNotFoundError as exc:
        print(f"FAIL [io] missing file during assertions: {exc}")
        print(f"RESULT: FAIL fixture={fixture} run_dir={run_dir}")
        return 1
    except json.JSONDecodeError as exc:
        print(f"FAIL [io] invalid JSON: {exc}")
        print(f"RESULT: FAIL fixture={fixture} run_dir={run_dir}")
        return 1

    print(f"RESULT: PASS fixture={fixture} run_dir={run_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
