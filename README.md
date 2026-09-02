# Emerge Demo

A demo application built with `Emerge` and `Solve`. It includes a Todo app and a Showcase app, so you can see how `Emerge` UI code and `Solve` state management fit together in a small Elixir project.

## Requirements

- Elixir `~> 1.19`
- Linux with a working Wayland session and hardware Vulkan driver
- A Rust toolchain plus the native graphics build dependencies for `emerge`
- Sibling checkouts at `../emerge-headless` and `../video_interop`

## Run Locally

This checkout builds the local Emerge NIF with Wayland Vulkan enabled and starts the demo in dev mode with hot reloading enabled for files under `lib`.

```bash
mix deps.get
iex -S mix
```

If you use `mise`, install the exact Erlang/OTP and Elixir versions pinned in `mise.toml` first:

```bash
mise install
```

### Hot Code Reload

Dev mode uses `file_system` to watch files under `lib` and trigger hot code reload.

- Linux: install `inotify-tools` so the watcher backend can run.
- macOS: hot reload uses the native FSEvents watcher. No separate `inotify`-style package is needed, but Xcode or the Command Line Tools should be installed.

The demo uses the sibling `video_interop` checkout directly; no `VIDEO_INTEROP_PATH` environment variable is required.

## Test

```bash
mix test
```

## Use The App

- Open the menu in the top-left corner to switch between `Todo` and `Showcase`.
- `Todo` is the main end-to-end example.
- `Showcase` contains smaller focused examples of layout, text, assets, borders, nearby overlays, scroll, keys, interaction, and VideoInterop.
- The `Video Interop` tab compares two animated headless viewports: a GPU producer imported from a DMA-BUF and a CPU raster producer imported from an owned RGBA8888 binary.

## Project Layout

A good place to start is the top-level app selector.

`lib/emerge_demo.ex` is the viewport entrypoint. Its `render/1` function renders `EmergeDemo.AppSelector.View`, so that is the first layer of the app.

`lib/emerge_demo/app_selector/` contains a small `Solve` app that owns the active screen and decides whether the viewport shows `Todo` or `Showcase`.

From there, `lib/emerge_demo/todo/app.ex` is a good example of how a `Solve` app is assembled. It defines the Todo controller graph. Read that file first, then follow the controllers it wires together.

`lib/emerge_demo/todo/view.ex` shows the other side of that setup: it reads exposed state with `Solve.Lookup` and renders the Todo UI with `Emerge`.

`lib/emerge_demo/showcase/` follows the same broad pattern, but is organized as smaller focused examples instead of one app flow.

## Video Interop Validation

The tab always uses a CPU RGBA8888 binary producer. The GPU DMA-BUF producer and main renderer APIs are independently selectable for the required four-way matrix:

```bash
EMERGE_DEMO_PRIME_VALIDATION=1 \
EMERGE_DEMO_PRIME_SOURCE_RENDERING_API=opengl \
EMERGE_DEMO_MAIN_RENDERING_API=opengl \
mix run --no-halt
```

Use `opengl` or `vulkan` for each API variable. On multi-GPU systems, also set `EMERGE_DEMO_PRIME_DRM_NODE` to the exact allocation node, such as `/dev/dri/renderD128`. VideoInterop validation remains disabled by default until the full five-minute, synchronization-validation, delayed-fence, resize/restart, fault, and byte-equality acceptance matrix passes.

Run the fresh-process candidate matrix smoke with byte-exact solid-frame, animated replacement, hide/show, reconnect, shutdown, FD, and steady-RSS checks:

```bash
EMERGE_DEMO_PRIME_DRM_NODE=/dev/dri/renderD128 ./scripts/prime-matrix.sh
```

A single route can be selected with `./scripts/prime-matrix.sh <producer-api> <main-api>`. For the five-minute 30 FPS soak portion, set `EMERGE_DEMO_PRIME_SOAK_FRAMES=9000 EMERGE_DEMO_PRIME_REQUIRE_RATE=1`. The harness takes `/tmp/emerge-performance.lock` before starting any route.

## Notes

- The main window explicitly uses the Wayland Vulkan renderer.
- The window title defaults to `Emerge Example`.
- Dev mode enables the `Emerge` code reloader for `lib`.

## References

- [Emerge](https://hexdocs.pm/emerge)
- [Solve](https://hexdocs.pm/solve)
