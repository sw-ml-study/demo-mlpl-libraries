# Native3D MLPL helpers

Version `0.1.0`; public prefix `u:n3d_`.

The entry module `lib/native3d/app.mlpl` provides reusable orbit-camera and
picking math, validated bulk-line/grid records, headless reducer/renderer
transitions, and an optional Port-backed event lifecycle. Camera, geometry, and
transition tests run without a window, GPU, or extension. Calling
`u:n3d_on_event` or `u:n3d_run_app` requires `extension.port.v1` and a bound
native3d Port.

Applications own domain state, reducers, render callbacks, revision policy, and
help/status text. Native Rust owns windowing, wgpu rendering, handles, and Port
transport. See the [migration contract](native3d-migration.md) for every public
function, stable record shape, error boundary, and excluded application policy.
