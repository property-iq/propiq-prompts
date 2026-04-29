# PIQ-STYLE Quick Reference

> **Auto-generated from [spec.yaml](https://github.com/property-iq/propiq-docs/blob/main/charts/spec.yaml).** Do not hand-edit.
> Regenerate with: `python scripts/regen_quickref.py`
>
> Spec version: 2026.04.29 | Last reviewed: 2026-04-29

---

## Static Context (PNG rendering)

- Canvas: 1600x1000px, aspect ratio 16:10
- title: 52/44/38px, weight 500
- subtitle: 42/36/32px, weight 300
- ticks: 32/36px, weight 300
- footnote: 24px, weight 300
- legend: 32px, weight 
- branding: 22px, weight 400
- Accent bar: 12px, color #CEAD63
- Line width: 7px
- Benchmark dash: [12, 8]
- Max Y ticks: 5
- Forbidden in config: callback_functions, gradient_fills, animations, tooltips

## Dynamic Context — Desktop

- Aspect ratio: 16:9
- Breakpoint: min 641px
- title: 20px, weight 500
- subtitle: 18px, weight 300
- ticks: 12px, weight 300
- axis_title: 14px, weight 200
- legend: 14px, weight 300
- tooltip_title: 16px, weight 250
- tooltip_body: 15px, weight 250
- x_max_ticks_default: 6
- y_max_ticks_default: 7
- y_tick_padding: 8
- Legend: position top

## Dynamic Context — Mobile

- Aspect ratio: 5:3
- Breakpoint: max 640px
- title: 11px, weight 600
- subtitle: 8px, weight 300
- ticks: 9px, weight 300
- legend: 8px, weight 300
- axis_title: 10px, weight 
- default_max_ticks: 3
- y_tick_padding: 1
- Legend: position bottom

## Universal Rules

- **U001** `opaque_background`: Canvas background must equal $tokens.brand.chart_background (#1a1a1a for dark theme). Never transparent. In static mode, achieved via the customCan...
- **U002** `single_series_uses_gold`: When only one non-regression dataset exists, suppress benchmark styling and color the series with $tokens.brand.gold_accent (#CEAD63). White-dashed...
- **U003** `y_axis_grid_subtle`: Y-axis grid lines are visible, subtle, 1px width. Dark theme colour #333333. X-axis grid lines are always hidden.
- **U004** `no_currency_in_tick_labels`: Currency belongs in the subtitle, not in tick labels. Tick labels use compact K/M/B notation for values >=1000. No AED prefix ever appears in tick ...
- **U005** `font_family_inter`: All text elements in chart configs use $tokens.brand.font_family ("Inter"). No other font families permitted.
- **U006** `line_tension`: Line charts use tension 0.35 for smooth curves.
- **U007** `benchmark_styling`: Benchmark / Dubai Market series: white color (dark theme), dashed [12, 8], order 1 (drawn behind data), no fill. Line width 3.5px (web) or 7px (sta...
- **D001** `tick_font_size_dynamic` — desktop: `12`, mobile: `9`: ChartStyle.font("ticks")["size"] == 12 for web context; ChartStyle.font("ticks", "mobile")["size"] == 9 for mobile.
- **D002** `legend_visibility_default`: Legend visible for multi-dataset charts by default (base.yaml plugins.legend.display: true). Single-dataset hbar overrides to hidden — see I001. Si...
- **D003** `animation_config` — duration_ms: `800`, easing: `easeOutQuart`: Animation duration 800ms, easing easeOutQuart. Static mode disables all animations.
- **D004** `tooltip_config` — corner_radius: `8`, padding: `12`, border_width: `1`: Tooltips enabled. Mode: index, intersect: false. Background rgba(0,0,0,0.85), border $tokens.brand.gold_accent, corner radius 8px, padding 12px. St...
- **S001** `static_no_callbacks`: Chart.js config sent to charts-img must contain zero callback functions. json.dumps(config) must succeed without serialization errors.
- **S002** `static_no_gradients`: Gradient fills are replaced with solid borderColor in static mode. No "function(context)" strings for createGradient in static configs.
- **S003** `static_title_in_frame`: Title and subtitle are rendered in the HTML frame by charts-img, not by the Chart.js title plugin. options.plugins.title.display must be false in s...

## horizontal_bar (runtime: `hbar`)

- Chart type: `bar`
- Index axis: `y`

- **I001** `hbar_legend_hidden`: Legend always hidden — single dataset, label is in the title.
- **I002** `hbar_y_min_width`: Y-axis (category axis) needs adequate width for area/building names. Minimum 90px effective width.
- **I003** `hbar_value_axis_ticks` — desktop: `10`, mobile: `6`: 
- **I004** `hbar_hover_color`: Hover background: rgba(255, 255, 255, 0.8) — softened white, not solid #ffffff.
- **I005** `hbar_bar_style`: No rounded bar corners (border_radius: 0). Bar alpha 0.75. Border width 0.

## trendline (runtime: `trend`)

- Chart type: `line`

- **I010** `trendline_points_hidden`: pointRadius: 0 — points hidden by default, visible on hover only.
- **I011** `trendline_benchmark_styling`: Multi-series: benchmark series renders white dashed [12,8], order 1, no fill. Single-series suppresses benchmark — see U002. Line width 3.5px (web)...
- **I012** `trendline_x_max_ticks` — desktop: `12`, mobile: `3`: ChartStyle.max_ticks("x", "trendline") == 12.
- **I013** `trendline_legend_style`: Legend uses line point style (not box). Box width 30, height 1, padding 16.

## scatter

- Chart type: `scatter`

- **I020** `scatter_point_radius_range` — min_radius: `4`, max_radius: `14`, min_txn_threshold: `5`, max_txn_threshold: `200`: Point radius 4-14px desktop, scaled by transaction count confidence (min threshold 5, max threshold 200 transactions). Mobile: max 1.5px.
- **I021** `scatter_max_labeled_points` — max_labeled: `25`: Maximum 25 labeled data points. IQR-based outlier removal applied before labeling.
- **I022** `scatter_interaction_mode`: Interaction mode: "point" (not "index" like other charts).
- **I023** `scatter_layout_padding` — top: `10`, right: `80`, bottom: `60`, left: `20`: 

## quadrant

- Chart type: `scatter`

- **I030** `quadrant_colors` — q1: `#4CAF50`, q2: `#CEAD63`, q3: `#E57373`, q4: `#475151`: 
- **I031** `quadrant_trend_line`: Regression/trend lines: 3px width, dashed [8,4], 0.7 opacity (dark theme).

## matrix

- Chart type: `scatter`

- **I040** `matrix_aspect_ratio`: 4:3 (narrower than standard 5:3 used by other charts).
- **I041** `matrix_quadrant_labels_mobile`: Quadrant labels hidden on mobile. ChartViewer removes them entirely on viewports <= 640px.
- **I042** `matrix_median_lines` — desktop_font_size: `12`, mobile_font_size: `7`, border_width: `2`, mobile_border_width: `1`: Median reference lines: border_width 1, label font 7px on mobile (12px desktop), position start.
- **I043** `matrix_point_config` — base_radius: `6`, callout_radius: `9`: 

## box_plot (runtime: `boxplot`)

- Chart type: `box`

- **I050** `box_plot_legend_visible`: Legend visible — follows D002 default (no intent override in base.yaml for boxplot legend.display). Resolves former contradiction between §4.4 and ...
- **I051** `box_plot_thin_bars`: barPercentage: 0.4 — thin bars for clear distribution display.
- **I052** `box_plot_hover_color`: Hover background: rgba(255, 255, 255, 0.8) — softened white.

## data_table (runtime: `table`)

- Chart type: `table`

- **I060** `data_table_typography`: Header text: $tokens.text.muted color, medium weight. Body text: $tokens.text.body color. Numeric cells use monospace rendering for alignment.
- **I061** `data_table_semantic_colors`: Percentage deltas use $tokens.brand.positive_change (#27AE60) for positive values and $tokens.brand.negative_change (#E74C3C) for negative values.

## Format Assignments

- `sale_price_psm`: aed
- `sale_price_median`: aed_compact
- `sale_price_avg_psm`: aed
- `sale_value_total`: aed_compact
- `sale_count`: number
- `sale_price_psm_growth`: growth
- `sale_price_psm_growth_yoy`: growth
- `sale_count_growth_yoy`: growth
- `rent_price_psm_growth_yoy`: growth
- `yield_gross_growth_yoy`: growth
- `yield_gross`: percent
- `rent_price_psm`: aed
- `rent_annual`: aed_compact
- `rent_count`: number
- `unit_size_avg`: number

## Deprecated Intents

- **heatmap**: deprecated 2026-04-29
- **dual_axis**: deprecated 2026-04-15

