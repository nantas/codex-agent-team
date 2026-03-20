# Codex Agent Team Test Harness

This V1 harness uses a dual-layer model.

- Top layer: fixture scenarios are written to exercise the real `codex-agent-team` workflow contract.
- Bottom layer: repository-local scripts produce deterministic evidence bundles so assertions remain stable while the workflow evolves.

Local commands:

- `tests/run-fixture.sh <fixture>`
- `tests/collect-artifacts.sh <run-dir>`
- `python3 tests/assert-fixture.py --fixture <fixture> --run-dir <run-dir>`
- `tests/run-all.sh`
- `python3 -m pytest tests/release -q`
- `bash tests/release/e2e-smoke.sh`

Output layout per run:

- `tests/out/<fixture>/<run-id>/run-metadata.json`
- `tests/out/<fixture>/<run-id>/workspace/.codex/multi-agent/*`
- `tests/out/<fixture>/<run-id>/session/*.log`
- `tests/out/<fixture>/<run-id>/artifacts/manifest.json`

V1 scope limits:

- validates workflow correctness only
- does not score intelligence quality
- does not attempt full interruption or recovery robustness coverage

Release automation smoke checks:

- `tests/release/*` validates release contract, install docs, install script, notes generation, workflow contract, and release orchestrator dry-run behavior.
- `tests/release/e2e-smoke.sh` validates end-to-end dry-run release flow and both install scopes using temporary target directories.
