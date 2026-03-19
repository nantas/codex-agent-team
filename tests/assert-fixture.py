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


def assert_interaction_protocol_contract(
    state: AssertionState, *, layer: str, lower_markers: set[str]
) -> None:
    if "interaction.preflight.passed" not in lower_markers:
        fail("missing required preflight marker 'interaction.preflight.passed'", layer=layer)

    session_path, _, _ = artifact_matches(
        state.run_dir, state.filesystem_files, ".codex/multi-agent/session.json"
    )
    if session_path is None:
        fail("missing session artifact '.codex/multi-agent/session.json'", layer=layer)
    session_payload = json.loads(session_path.read_text(encoding="utf-8"))

    required_keys = [
        "execution_mode",
        "awaiting_user_reply",
        "awaiting_mode",
        "question_stage_id",
        "question_batch_index",
        "question_ids",
        "reply_route",
        "last_sync_turn_id",
    ]
    for key in required_keys:
        if key not in session_payload:
            fail(f"session.json missing interaction key '{key}'", layer=layer)

    execution_mode = session_payload["execution_mode"]
    if execution_mode not in ("parallel", "serial"):
        fail("session.json execution_mode must be 'parallel' or 'serial'", layer=layer)

    if not isinstance(session_payload["awaiting_user_reply"], bool):
        fail("session.json awaiting_user_reply must be boolean", layer=layer)

    if session_payload["awaiting_mode"] not in ("interactive_ask", "message_ask"):
        fail("session.json awaiting_mode must be 'interactive_ask' or 'message_ask'", layer=layer)

    if not isinstance(session_payload["question_stage_id"], str) or not session_payload[
        "question_stage_id"
    ]:
        fail("session.json question_stage_id must be non-empty string", layer=layer)

    if not isinstance(session_payload["question_batch_index"], int) or session_payload[
        "question_batch_index"
    ] < 1:
        fail("session.json question_batch_index must be integer >= 1", layer=layer)

    question_ids = session_payload["question_ids"]
    if not isinstance(question_ids, list) or not question_ids:
        fail("session.json question_ids must be non-empty list", layer=layer)
    if not all(isinstance(x, str) and x for x in question_ids):
        fail("session.json question_ids must contain non-empty string ids", layer=layer)

    reply_route = session_payload["reply_route"]
    if not isinstance(reply_route, dict) or not reply_route:
        fail("session.json reply_route must be non-empty object", layer=layer)

    if execution_mode == "parallel" and len(reply_route) < len(question_ids):
        fail(
            "parallel execution requires reply_route coverage for the active question ids",
            layer=layer,
        )

    if not isinstance(session_payload["last_sync_turn_id"], str) or not session_payload[
        "last_sync_turn_id"
    ]:
        fail("session.json last_sync_turn_id must be non-empty string", layer=layer)

    team_path, _, _ = artifact_matches(state.run_dir, state.filesystem_files, ".codex/multi-agent/team.json")
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

    assert_interaction_protocol_contract(state, layer=layer, lower_markers=lower_markers)

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
            "markers": ["interaction-preflight-passed", "interaction-routing-persisted"],
            "artifacts": ["session.json", "checkpoints.json"],
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
            "interaction.preflight.skipped",
            "interaction.subagent.direct_user_input",
            "interaction.unstructured_large_relay",
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
