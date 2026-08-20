# Native3D MLPL library migration contract

Status: frozen extraction baseline, 2026-08-19.

## Evidence baseline

This inventory reads `../demo-extensions` at commit
`62c0d1bc460678d09ed0e3b08388e09b151d42f8` without modifying it. The reusable
sources and native mlplunit acceptance suite were:

| File | SHA-256 |
|---|---|
| `lib/native3d/camera.mlpl` | `0ef966f6046f1112b8a7edd1ae83cc6770091cfb9d50854fb303098439e8b88c` |
| `lib/native3d/geometry.mlpl` | `7ac4e9cc756363cbc19b129c7931a10838d88895c4af356d8b54a9a4f030caa4` |
| `lib/native3d/app.mlpl` | `2d3f6806d6b7c0779e90afcf8093f58951c88bd5f6d92eea3dfde08931cee256` |
| `tests/test_native3d_library.mlpl` | `43a51eabae50fd1ed09e5abfdebf8ca592b8c11336b97b904f312dda34cd21a0` |

The baseline is evidence, not a live synchronization mechanism. Later peer
changes require an explicit contract review rather than silently changing this
library.

## Migration map

| Source/API | Destination | Responsibility | Capability |
|---|---|---|---|
| `camera.mlpl`: `u:n3d_clamp`, `u:n3d_vector_length`, `u:n3d_normalize` | `lib/native3d/camera.mlpl` | scalar/vector helpers | core MLPL |
| `u:n3d_camera_state`, `u:n3d_camera_defaults`, `u:n3d_camera_valid`, `u:n3d_camera_record`, `u:n3d_camera_restate` | same | stable camera state and renderer projection | core MLPL |
| `u:n3d_camera_reduce` | same | pointer orbit/pan/wheel reduction; unrelated events are no-ops | core MLPL |
| `u:n3d_pick_ray`, `u:n3d_ray_plane_hit` | same | viewport ray construction and generic plane intersection | core MLPL |
| `geometry.mlpl`: `u:n3d_valid_color`, `u:n3d_uniform_line_style` | `lib/native3d/geometry.mlpl` | RGBA/style validation and parallel arrays | core MLPL arrays |
| `u:n3d_lines`, `u:n3d_plane_grid` | same | validated bulk line records and generic XZ grid | core MLPL arrays |
| `app.mlpl`: `u:n3d_scene_command`, `u:n3d_transition` | `lib/native3d/app.mlpl` | headless command assembly and reducer/renderer composition | core MLPL callables/results |
| `u:n3d_on_event`, `u:n3d_run_app` | same | Port send, handler registration, and event loop | `extension.port.v1` |

The public prefix remains `u:n3d_`; changing it, record field names, error
records, callback order, event interpretation, numeric clamps, or left-to-right
Result propagation is an API change. `app.mlpl` remains the entry module and
includes camera then geometry in that order.

## Stable value contracts

- Camera state fields: `target`, `yaw`, `pitch`, `distance`, `fov`, `near`,
  `dragging`, `drag_mode`, `last_x`, and `last_y`. Renderer projection omits the
  four drag fields.
- Line scenes carry dense `positions [N,3]`, integer-valued `edges [M,2]`,
  `colors [M,4]`, `thicknesses [M]`, stable `ids [M]`, and
  `rotation_y_speed`. Invalid shapes, indices, colors, thickness, and non-finite
  rotation return typed `Err` values.
- A scene command has `op: "set_scene"`, every scene array, camera projection,
  non-negative integer `revision`, and application-owned `help` text.
- `n3d_transition` calls the application reducer first, renderer second, then
  command assembly; it returns `ok({state, command})` and propagates renderer or
  command errors.
- Picking uses physical-pixel coordinates with upper-left origin. Misses
  (parallel or behind the ray) are successful `{hit: 0, point, distance}`
  records, while malformed inputs are errors.

## Ownership boundary

This repository owns generic camera gestures, picking math, line/grid records,
scene command assembly, and generic callback/Port lifecycle. It does not own
cube geometry, board rules, Life evolution, model-file parsing, spectrum
processing, disk traversal, UI menus, application status/help policy, selection
rules, or revision policy.

Rust/native3d continues to own window creation, winit/wgpu execution, validated
native handles, event delivery, Port transport, and rendering. MLPL application
repositories own their domain state, reducer, renderer callback, and text.

The evidence found 27 application files using the helpers. Direct calls are
concentrated in `n3d_camera_reduce` (29), `n3d_camera_record` (18),
`n3d_clamp` (12), `n3d_lines` (9), `n3d_camera_state` (8), `n3d_pick_ray` (7),
`n3d_ray_plane_hit` (2), `n3d_plane_grid` (1), and `n3d_camera_defaults` (1).
Those consumers make preservation of the complete prefix surface preferable to
premature API cleanup.

## Acceptance migration

Step 006 must port the four named headless groups from
`test_native3d_library.mlpl`:

1. Camera orbit, zoom, pan, pointer-up, and unrelated-event no-op behavior.
2. Center pick-ray/plane hit plus parallel-ray miss behavior.
3. Style, line, and 2-by-3 grid shapes for all parallel arrays.
4. Generic reducer/renderer transition, revision, help text, operation spelling,
   and camera projection.

It must add negative coverage for malformed camera/pick records, zero vectors,
invalid color/thickness/indices/rotation, invalid revision, and renderer errors.
All of this runs without a window, GPU, extension library, or Port. Port-backed
`on_event`/`run_app` behavior is contract-only here and remains integration
coverage in `demo-extensions` until an injectable Port seam exists.

## Consumer adoption sequence

1. Implement the three modules here with the frozen API and headless tests.
2. Catalog `native3d` with all three ordered source files and capabilities
   `core.include.v1` plus `extension.port.v1`.
3. Install a pinned revision into an external-style fixture and run the ported
   headless suite solely against `vendor/swml/`.
4. In the separately authorized peer change, install into `demo-extensions`,
   replace direct `../../lib/native3d/...` includes with vendored paths, retain
   its native Port/runtime tests, and remove duplicates only after its full gate
   passes.

Blocker: none for extraction and headless testing. Live lifecycle execution
requires the already-shipped interpreted Port/native3d provider and is not
portable producer evidence. Compiled lifecycle parity remains an upstream/peer
concern and is not claimed by this library migration.
