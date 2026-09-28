#!/usr/bin/env python3
"""Atomic release-candidate gate for the CEF BrowserRuntime cutover.

This module is release tooling only: the application never imports it and it
never launches CEF.  It defines the complete compatibility, fault, and
performance matrix from epic #110 / ticket #131 and evaluates one release
record as a single Windows/Linux set: a single failed mandatory cell blocks
publication of the entire desktop set, and rollback always covers the whole
set (never one platform alone, never a legacy engine).

Matrix vocabulary (see docs/cef-browser-runtime-release-candidate.md):

- ``G``: mandatory release-gate cell (bundled CEF, must pass).
- ``P``: deliberately preserved non-CEF path (must pass as preserved).
- ``N/A``: not currently exposed; must not silently substitute a backend.
- ``X``: prohibited in the production target graph or artifact (must be absent).

The gate consumes one JSON release record::

    {
      "schema_version": 1,
      "cef_version": "152.0.8+g1ce985c+chromium-152.0.7977.134",
      "cells": {"windows-x64/matrix/embedded": {"kind": "G", "status": "pass"}},
      "faults": {"host:windows-x64/matrix/embedded": {"status": "pass"}},
      "perf": {"host_ready_s_cold": 4.2, ...},
      "manual": {"permissions": {"covered": true, "evidence": "..."}},
      "forbidden": {"webview2": "absent", ...}
    }

Use ``--example`` to emit a passing template record and ``--self-check`` to
prove the gate blocks a mutated record (used by CI).

The implementation uses only the Python standard library.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Mapping, Sequence


SCHEMA_VERSION = 1

#: Mandatory Windows x64 gate cells.
WINDOWS_G_CELLS = (
    "windows-x64/matrix/embedded",
    "windows-x64/matrix/standalone",
    "windows-x64/official-video/embedded",
)

#: Released native Linux x64 packages covered by the gate.
NATIVE_PACKAGES = ("debian-12", "ubuntu-22.04", "ubuntu-24.04", "portable")

#: Native/Flatpak compositor cells.
COMPOSITORS = ("x11", "wayland")

#: Matrix presentations.
PRESENTATIONS = ("embedded", "standalone")


def native_g_cells() -> tuple[str, ...]:
    """All 16 native Linux Matrix gate cells (4 packages x 2 compositors x 2 presentations)."""
    cells: list[str] = []
    for package in NATIVE_PACKAGES:
        for compositor in COMPOSITORS:
            for presentation in PRESENTATIONS:
                cells.append(f"native-{package}/{compositor}/matrix/{presentation}")
    return tuple(cells)


def flatpak_g_cells() -> tuple[str, ...]:
    """All 4 Flatpak Matrix gate cells (2 compositors x 2 presentations)."""
    return tuple(
        f"flatpak/{compositor}/matrix/{presentation}"
        for compositor in COMPOSITORS
        for presentation in PRESENTATIONS
    )


def mandatory_g_cells() -> tuple[str, ...]:
    """All 23 mandatory G cells in stable order."""
    return WINDOWS_G_CELLS + native_g_cells() + flatpak_g_cells()


#: Preserved non-CEF Linux official-video flows (the external browser),
#: one per native package/compositor.
def linux_video_p_cells() -> tuple[str, ...]:
    return tuple(
        f"native-{package}/{compositor}/official-video/preserved"
        for package in NATIVE_PACKAGES
        for compositor in COMPOSITORS
    )


#: Preserved deliberate external/remote flows per platform group.
EXTERNAL_P_CELLS = (
    "windows-x64/external/remote-ssd",
    "native/external/remote-ssd",
    "flatpak/external/remote-ssd",
)


def preserved_p_cells() -> tuple[str, ...]:
    """All preserved P flows in stable order."""
    return linux_video_p_cells() + EXTERNAL_P_CELLS


#: N/A boundaries: no standalone official-video surface exists on any column.
NA_COLUMNS = ("windows-x64", "native-x11", "native-wayland", "flatpak-x11", "flatpak-wayland")


def na_cells() -> tuple[str, ...]:
    """N/A boundary cells (official-video standalone is not exposed)."""
    return tuple(f"{column}/official-video/standalone" for column in NA_COLUMNS)


#: Prohibited backends/markers that must be absent from the production target
#: graph and every shipped artifact.
PROHIBITED_X_MARKERS = (
    "webview2",
    "webkitgtk-wry-runner",
    "system-cef",
    "runtime-cef-download",
    "unowned-browser",
)


def prohibited_x_markers() -> tuple[str, ...]:
    return PROHIBITED_X_MARKERS


#: Fault-injection families; every family must have passing evidence on every
#: mandatory G cell (host kill at idle/load/each command class, renderer
#: statuses and hang, GPU/utility faults, heartbeat loss, bad bundle/protocol/
#: sandbox/profile-lock, and retry-budget exhaustion).
FAULT_FAMILIES = (
    "host",
    "renderer",
    "gpu",
    "utility",
    "heartbeat",
    "bundle",
    "protocol",
    "sandbox",
    "profile-lock",
    "retry-budget",
)


def required_fault_keys() -> tuple[str, ...]:
    """All required fault-evidence keys (family:cell) in stable order."""
    return tuple(
        f"{family}:{cell}" for family in FAULT_FAMILIES for cell in mandatory_g_cells()
    )


#: Performance thresholds for every G cell on declared minimum/reference
#: hardware (see epic #110 behavior contract).
PERFORMANCE_THRESHOLDS: dict[str, float] = {
    "host_ready_s_cold_max": 5.0,
    "first_paint_s_after_open_max": 3.0,
    "surface_close_s_max": 2.0,
    "cpu_osr_fps_min": 30.0,
    "cpu_osr_soak_s": 60.0,
    "input_to_present_p95_ms_max": 100.0,
    "soak_minutes": 30.0,
    "soak_rss_growth_pct_max": 15.0,
    "orphan_processes_max": 0.0,
}

def performance_thresholds() -> dict[str, float]:
    return dict(PERFORMANCE_THRESHOLDS)


#: Manual-evidence topics required for the candidate (per G-cell group plus
#: official video, recovery, and rollback).
MANUAL_TOPICS = (
    "permissions",
    "ime",
    "accessibility",
    "cpu-fallback",
    "official-video",
    "recovery",
    "rollback",
)


def manual_topics() -> tuple[str, ...]:
    return MANUAL_TOPICS


class CandidateBlocked(Exception):
    """Raised when the release record does not satisfy the atomic gate."""

    def __init__(self, failures: Sequence[str]) -> None:
        super().__init__("; ".join(failures))
        self.failures = list(failures)


def _cell_status(cells: Mapping[str, Any], cell_id: str) -> str:
    entry = cells.get(cell_id)
    if not isinstance(entry, Mapping):
        return "<missing>"
    status = entry.get("status")
    return status if isinstance(status, str) else "<missing>"


def evaluate(report: Mapping[str, Any]) -> dict[str, Any]:
    """Evaluate one release record against the atomic gate.

    Returns ``{"passed": bool, "failures": [...], "counts": {...}}``.  A
    single failed mandatory cell (or any missing required evidence) blocks
    the whole Windows/Linux candidate.
    """

    failures: list[str] = []
    if not isinstance(report, Mapping):
        return {"passed": False, "failures": ["release record must be an object"], "counts": {}}

    cells = report.get("cells")
    faults = report.get("faults")
    perf = report.get("perf")
    manual = report.get("manual")
    forbidden = report.get("forbidden")

    # --- G cells: every mandatory cell must pass. ---
    if not isinstance(cells, Mapping):
        failures.append("release record is missing the cells matrix")
        cells = {}
    g_total = len(mandatory_g_cells())
    g_passed = 0
    for cell_id in mandatory_g_cells():
        status = _cell_status(cells, cell_id)
        if status == "pass":
            g_passed += 1
        else:
            failures.append(f"mandatory cell {cell_id} blocks the candidate (status={status})")

    # --- P flows: preserved paths must pass as preserved. ---
    p_total = len(preserved_p_cells())
    p_passed = 0
    for cell_id in preserved_p_cells():
        entry = cells.get(cell_id)
        status = _cell_status(cells, cell_id)
        kind = entry.get("kind") if isinstance(entry, Mapping) else None
        if status == "pass" and kind == "P":
            p_passed += 1
        else:
            failures.append(
                f"preserved flow {cell_id} blocks the candidate (kind={kind}, status={status})"
            )

    # --- N/A boundaries: must stay N/A with no backend. ---
    na_total = len(na_cells())
    na_ok = 0
    for cell_id in na_cells():
        entry = cells.get(cell_id)
        status = _cell_status(cells, cell_id)
        backend = entry.get("backend") if isinstance(entry, Mapping) else None
        if status == "na" and backend in (None, "none"):
            na_ok += 1
        else:
            failures.append(
                f"N/A boundary {cell_id} blocks the candidate (status={status}, backend={backend})"
            )

    # --- X backends: must be absent everywhere. ---
    x_total = len(prohibited_x_markers())
    x_ok = 0
    if not isinstance(forbidden, Mapping):
        failures.append("release record is missing the forbidden-backend evidence")
        forbidden = {}
    for marker in prohibited_x_markers():
        state = forbidden.get(marker)
        if state == "absent":
            x_ok += 1
        else:
            failures.append(f"prohibited backend {marker} blocks the candidate (state={state})")
    # A cell that claims an X backend passes is also a violation.
    for cell_id, entry in (cells.items() if isinstance(cells, Mapping) else []):
        if not isinstance(entry, Mapping):
            continue
        backend = str(entry.get("backend", "")).lower()
        for marker in prohibited_x_markers():
            if marker in backend and "forbidden" not in backend:
                failures.append(
                    f"cell {cell_id} selects prohibited backend {marker} and blocks the candidate"
                )

    # --- Fault injection: every family on every G cell must pass. ---
    fault_keys = required_fault_keys()
    f_total = len(fault_keys)
    f_passed = 0
    if not isinstance(faults, Mapping):
        failures.append("release record is missing the fault-injection evidence")
        faults = {}
    for key in fault_keys:
        entry = faults.get(key)
        status = entry.get("status") if isinstance(entry, Mapping) else None
        if status == "pass":
            f_passed += 1
        else:
            family, _, cell = key.partition(":")
            failures.append(
                f"fault {family} on {cell} blocks the candidate (status={status})"
            )

    # --- Performance: every threshold must hold. ---
    perf_failures = 0
    if not isinstance(perf, Mapping):
        failures.append("release record is missing the performance evidence")
        perf = {}
    else:
        t = PERFORMANCE_THRESHOLDS
        checks = (
            ("host_ready_s_cold", perf.get("host_ready_s_cold"), t["host_ready_s_cold_max"], "<="),
            ("first_paint_s_after_open", perf.get("first_paint_s_after_open"), t["first_paint_s_after_open_max"], "<="),
            ("surface_close_s", perf.get("surface_close_s"), t["surface_close_s_max"], "<="),
            ("cpu_osr_fps", perf.get("cpu_osr_fps"), t["cpu_osr_fps_min"], ">="),
            ("cpu_osr_soak_s", perf.get("cpu_osr_soak_s"), t["cpu_osr_soak_s"], ">="),
            ("input_to_present_p95_ms", perf.get("input_to_present_p95_ms"), t["input_to_present_p95_ms_max"], "<="),
            ("soak_rss_growth_pct", perf.get("soak_rss_growth_pct"), t["soak_rss_growth_pct_max"], "<="),
            ("orphan_processes", perf.get("orphan_processes"), t["orphan_processes_max"], "<="),
        )
        for name, value, bound, op in checks:
            if not isinstance(value, (int, float)):
                failures.append(f"perf {name} blocks the candidate (missing={value!r})")
                perf_failures += 1
            elif op == "<=" and not value <= bound:
                failures.append(f"perf {name}={value} exceeds threshold {bound} and blocks the candidate")
                perf_failures += 1
            elif op == ">=" and not value >= bound:
                failures.append(f"perf {name}={value} is below threshold {bound} and blocks the candidate")
                perf_failures += 1
        soak_minutes = perf.get("soak_minutes")
        if soak_minutes != t["soak_minutes"]:
            failures.append(
                f"perf soak_minutes={soak_minutes!r} must equal {t['soak_minutes']} and blocks the candidate"
            )
            perf_failures += 1

    # --- Manual evidence: every topic covered with evidence. ---
    m_total = len(manual_topics())
    m_covered = 0
    if not isinstance(manual, Mapping):
        failures.append("release record is missing the manual evidence")
        manual = {}
    for topic in manual_topics():
        entry = manual.get(topic)
        covered = entry.get("covered") if isinstance(entry, Mapping) else None
        evidence = entry.get("evidence") if isinstance(entry, Mapping) else None
        if covered is True and isinstance(evidence, str) and evidence.strip():
            m_covered += 1
        else:
            failures.append(
                f"manual evidence {topic} blocks the candidate (covered={covered})"
            )

    passed = not failures
    return {
        "passed": passed,
        "failures": failures,
        "counts": {
            "mandatory_cells_passed": g_passed,
            "mandatory_cells_total": g_total,
            "preserved_flows_passed": p_passed,
            "preserved_flows_total": p_total,
            "na_boundaries_ok": na_ok,
            "na_boundaries_total": na_total,
            "prohibited_absent": x_ok,
            "prohibited_total": x_total,
            "faults_passed": f_passed,
            "faults_total": f_total,
            "manual_covered": m_covered,
            "manual_total": m_total,
            "perf_violations": perf_failures,
        },
    }


def qualify(report: Mapping[str, Any]) -> dict[str, Any]:
    """Evaluate and raise :class:`CandidateBlocked` when the gate fails."""

    result = evaluate(report)
    if not result["passed"]:
        raise CandidateBlocked(result["failures"])
    gate_report = {
        "schema_version": SCHEMA_VERSION,
        "passed": True,
        "counts": result["counts"],
        "thresholds": dict(PERFORMANCE_THRESHOLDS),
        "atomic": "one failed mandatory cell blocks the complete Windows/Linux set",
        "rollback": "withdraw/stop the complete desktop set; install the last known-good complete release",
    }
    return json.loads(json.dumps(gate_report))


def example_report() -> dict[str, Any]:
    """Build a passing template release record."""

    cells: dict[str, Any] = {}
    for cell_id in mandatory_g_cells():
        cells[cell_id] = {"kind": "G", "status": "pass", "evidence": "automated-matrix"}
    for cell_id in preserved_p_cells():
        cells[cell_id] = {"kind": "P", "status": "pass", "evidence": "preserved-path"}
    for cell_id in na_cells():
        cells[cell_id] = {"kind": "N/A", "status": "na", "backend": "none"}
    faults: dict[str, Any] = {}
    for key in required_fault_keys():
        faults[key] = {"status": "pass", "trace": "fault-trace"}
    report = {
        "schema_version": SCHEMA_VERSION,
        "cef_version": "152.0.8+g1ce985c+chromium-152.0.7977.134",
        "chromium_version": "152.0.7977.134",
        "cells": cells,
        "faults": faults,
        "perf": {
            "host_ready_s_cold": 4.2,
            "first_paint_s_after_open": 2.1,
            "surface_close_s": 1.2,
            "cpu_osr_fps": 32.0,
            "cpu_osr_soak_s": 60.0,
            "input_to_present_p95_ms": 88.0,
            "soak_minutes": 30.0,
            "soak_rss_growth_pct": 9.0,
            "orphan_processes": 0,
        },
        "manual": {
            topic: {"covered": True, "evidence": f"{topic}-checklist"}
            for topic in manual_topics()
        },
        "forbidden": {marker: "absent" for marker in prohibited_x_markers()},
    }
    return json.loads(json.dumps(report))


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, help="path to a JSON release record")
    parser.add_argument("--output", type=Path, help="write the JSON gate report to a file")
    parser.add_argument("--example", action="store_true", help="emit a passing template record")
    parser.add_argument("--list-cells", action="store_true", help="list the matrix cell ids")
    parser.add_argument(
        "--self-check",
        action="store_true",
        help="prove the example passes and a single failed mandatory cell blocks",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if args.example:
        sys.stdout.buffer.write((json.dumps(example_report(), indent=2) + "\n").encode("utf-8"))
        return 0
    if args.list_cells:
        payload = {
            "mandatory_g_cells": list(mandatory_g_cells()),
            "preserved_p_cells": list(preserved_p_cells()),
            "na_cells": list(na_cells()),
            "prohibited_x_markers": list(prohibited_x_markers()),
            "fault_families": list(FAULT_FAMILIES),
            "required_fault_keys": len(required_fault_keys()),
            "performance_thresholds": dict(PERFORMANCE_THRESHOLDS),
            "manual_topics": list(manual_topics()),
        }
        sys.stdout.buffer.write((json.dumps(payload, indent=2) + "\n").encode("utf-8"))
        return 0
    if args.self_check:
        try:
            qualify(example_report())
        except CandidateBlocked as exc:
            print(f"qualify-release-candidate: self-check failed: {exc}", file=sys.stderr)
            return 2
        mutated = example_report()
        first = mandatory_g_cells()[0]
        mutated["cells"][first]["status"] = "fail"
        try:
            qualify(mutated)
        except CandidateBlocked:
            print("qualify-release-candidate: self-check passed (single failure blocks)")
            return 0
        print("qualify-release-candidate: self-check failed: mutated record passed", file=sys.stderr)
        return 2
    if args.report is None:
        print("qualify-release-candidate: error: --report, --example, --list-cells, or --self-check is required", file=sys.stderr)
        return 2
    try:
        record = json.loads(args.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        print(f"qualify-release-candidate: error: {exc}", file=sys.stderr)
        return 2
    try:
        gate_report = qualify(record)
    except CandidateBlocked as exc:
        for failure in exc.failures[:20]:
            print(f"qualify-release-candidate: blocked: {failure}", file=sys.stderr)
        if len(exc.failures) > 20:
            print(f"qualify-release-candidate: blocked: ... ({len(exc.failures)} total)", file=sys.stderr)
        return 1
    encoded = (json.dumps(gate_report, indent=2) + "\n").encode("utf-8")
    if args.output is not None:
        try:
            args.output.write_bytes(encoded)
        except OSError as exc:
            print(f"qualify-release-candidate: error: {exc}", file=sys.stderr)
            return 2
    sys.stdout.buffer.write(encoded)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
