#!/usr/bin/env python3
"""Regenerate propertyiq/skills/chart-qa/piq-style-quickref.md from spec.yaml.

Usage:
    # From local propiq-docs checkout:
    python regen_quickref.py /path/to/propiq-docs/charts/spec.yaml /path/to/propiq-docs/tokens.yaml

    # Fetch from GitHub (default when no args):
    python regen_quickref.py

Outputs markdown to stdout. CI compares output with committed piq-style-quickref.md.
"""

import sys
import tempfile
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    print("Error: pyyaml required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


TOKEN_REF_PATTERN = r"^\$tokens\.([a-zA-Z0-9_.]+)$"


def _resolve_tokens(node: Any, tokens: dict) -> Any:
    """Recursively resolve $tokens references."""
    import re
    if isinstance(node, dict):
        return {k: _resolve_tokens(v, tokens) for k, v in node.items()}
    if isinstance(node, list):
        return [_resolve_tokens(item, tokens) for item in node]
    if isinstance(node, str):
        match = re.match(TOKEN_REF_PATTERN, node)
        if match:
            path = match.group(1).split(".")
            value = tokens
            for key in path:
                if not isinstance(value, dict) or key not in value:
                    return node  # leave unresolved
                value = value[key]
            return value
    return node


def _fetch_from_github() -> tuple[str, str]:
    """Fetch spec.yaml and tokens.yaml from propiq-docs/main."""
    import urllib.request

    base = "https://raw.githubusercontent.com/property-iq/propiq-docs/main"
    tmp = tempfile.mkdtemp()

    for name in ("charts/spec.yaml", "tokens.yaml"):
        url = f"{base}/{name}"
        dest = Path(tmp) / Path(name).name
        try:
            urllib.request.urlretrieve(url, dest)
        except Exception as e:
            print(f"Error fetching {url}: {e}", file=sys.stderr)
            sys.exit(1)

    return str(Path(tmp) / "spec.yaml"), str(Path(tmp) / "tokens.yaml")


def _format_values(values: dict) -> str:
    """Format a values dict as inline text."""
    if not values:
        return ""
    pairs = [f"{k}: `{v}`" for k, v in values.items()]
    return " — " + ", ".join(pairs)


def _rule_line(rule: dict) -> str:
    """Generate a single quickref line for a rule."""
    rule_id = rule["id"]
    name = rule.get("name", "")
    description = rule.get("rule", rule.get("verify", "")).strip().replace("\n", " ")
    values = rule.get("values", {})
    values_str = _format_values(values)

    if len(description) > 150:
        description = description[:147] + "..."

    return f"- **{rule_id}** `{name}`{values_str}: {description}"


def generate_quickref(spec: dict) -> str:
    """Generate quickref markdown from resolved spec dict."""
    lines = [
        "# PIQ-STYLE Quick Reference",
        "",
        "> **Auto-generated from [spec.yaml](https://github.com/property-iq/propiq-docs/blob/main/charts/spec.yaml).** Do not hand-edit.",
        f"> Regenerate with: `python scripts/regen_quickref.py`",
        f">",
        f"> Spec version: {spec.get('spec_version', 'unknown')} | Last reviewed: {spec.get('last_reviewed', 'unknown')}",
        "",
        "---",
        "",
    ]

    # Contexts summary
    contexts = spec.get("contexts", {})

    if "static" in contexts:
        static = contexts["static"]
        lines.append("## Static Context (PNG rendering)")
        lines.append("")
        canvas = static.get("canvas_px", [])
        if canvas:
            lines.append(f"- Canvas: {canvas[0]}x{canvas[1]}px, aspect ratio {static.get('aspect_ratio', '')}")
        typo = static.get("typography", {})
        if typo:
            for elem, vals in typo.items():
                sizes = vals.get("font_sizes_px", vals.get("font_size_range_px", [vals.get("font_size_px")]))
                weight = vals.get("font_weight", "")
                if isinstance(sizes, list):
                    sizes_str = "/".join(str(s) for s in sizes if s)
                else:
                    sizes_str = str(sizes)
                lines.append(f"- {elem}: {sizes_str}px, weight {weight}")
        frame = static.get("frame", {})
        if frame:
            lines.append(f"- Accent bar: {frame.get('accent_bar_height_px', '')}px, color {frame.get('accent_bar_color', '')}")
        lines.append(f"- Line width: {static.get('line_width_px', '')}px")
        lines.append(f"- Benchmark dash: {static.get('benchmark_dash', '')}")
        lines.append(f"- Max Y ticks: {static.get('max_ticks_y', '')}")
        forbidden = static.get("forbidden_in_config", [])
        if forbidden:
            lines.append(f"- Forbidden in config: {', '.join(forbidden)}")
        lines.append("")

    if "dynamic" in contexts:
        dynamic = contexts["dynamic"]
        for vp_name in ("desktop", "mobile"):
            vp = dynamic.get("viewports", {}).get(vp_name)
            if not vp:
                continue
            lines.append(f"## Dynamic Context — {vp_name.title()}")
            lines.append("")
            ar = vp.get("aspect_ratio", "")
            if ar:
                lines.append(f"- Aspect ratio: {ar}")
            bp = vp.get("breakpoint_min_px", vp.get("breakpoint_max_px"))
            if bp:
                qualifier = "min" if "breakpoint_min_px" in vp else "max"
                lines.append(f"- Breakpoint: {qualifier} {bp}px")
            typo = vp.get("typography", {})
            if typo:
                for elem, vals in typo.items():
                    size = vals.get("font_size_px", "")
                    weight = vals.get("font_weight", "")
                    lines.append(f"- {elem}: {size}px, weight {weight}")
            scales = vp.get("scales", {})
            if scales:
                for k, v in scales.items():
                    lines.append(f"- {k}: {v}")
            lines.append(f"- Legend: position {vp.get('legend_position', '')}")
            lines.append("")

    # Universal rules
    rules = spec.get("rules", [])
    if rules:
        lines.append("## Universal Rules")
        lines.append("")
        for rule in rules:
            lines.append(_rule_line(rule))
        lines.append("")

    # Per-intent rules
    intents = spec.get("intents", {})
    if intents:
        for intent_key, intent_data in intents.items():
            canonical = intent_data.get("canonical_name", intent_key)
            runtime_id = intent_data.get("runtime_id", "")
            header = f"## {canonical}"
            if runtime_id and runtime_id != canonical:
                header += f" (runtime: `{runtime_id}`)"
            lines.append(header)
            lines.append("")
            lines.append(f"- Chart type: `{intent_data.get('chart_type', '')}`")
            if intent_data.get("index_axis"):
                lines.append(f"- Index axis: `{intent_data['index_axis']}`")
            lines.append("")
            for rule in intent_data.get("rules", []):
                lines.append(_rule_line(rule))
            lines.append("")

    # Format assignments
    assignments = spec.get("format_assignments", {})
    if assignments:
        lines.append("## Format Assignments")
        lines.append("")
        for metric, fmt in assignments.items():
            lines.append(f"- `{metric}`: {fmt}")
        lines.append("")

    # Deprecated
    deprecated = spec.get("deprecated", [])
    if deprecated:
        lines.append("## Deprecated Intents")
        lines.append("")
        for item in deprecated:
            name = item.get("canonical_name", "unknown")
            date = item.get("deprecated_at", "")
            lines.append(f"- **{name}**: deprecated {date}")
        lines.append("")

    return "\n".join(lines)


def main() -> None:
    if len(sys.argv) >= 3:
        spec_path, tokens_path = sys.argv[1], sys.argv[2]
    elif len(sys.argv) == 1:
        print("No local paths provided — fetching from GitHub...", file=sys.stderr)
        spec_path, tokens_path = _fetch_from_github()
    else:
        print(
            f"Usage: {sys.argv[0]} [spec.yaml tokens.yaml]",
            file=sys.stderr,
        )
        sys.exit(1)

    for p in (spec_path, tokens_path):
        if not Path(p).exists():
            print(f"Error: {p} not found", file=sys.stderr)
            sys.exit(1)

    tokens = yaml.safe_load(Path(tokens_path).read_text())
    spec_raw = yaml.safe_load(Path(spec_path).read_text())
    spec = _resolve_tokens(spec_raw, tokens)

    print(generate_quickref(spec))


if __name__ == "__main__":
    main()
