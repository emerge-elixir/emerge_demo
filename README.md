# Emerge Demo

A demo application built with `Emerge` and `Solve`. It includes a Todo app and a Showcase app, so you can see how `Emerge` UI code and `Solve` state management fit together in a small Elixir project.

## Requirements

- Elixir `~> 1.19`
- Linux with a working Wayland session and hardware Vulkan driver, or macOS 15+
- A Rust toolchain plus the native graphics build dependencies for `emerge`
- FFmpeg 9 development libraries for `membrane_video_transcode` (`brew install ffmpeg` on macOS)
- Sibling checkouts at `../emerge` and `../membrane_video_transcode`

## Run Locally

This checkout uses Wayland Vulkan on Linux and the macOS raster renderer on macOS. It starts in dev mode with hot reloading enabled for files under `lib`.

VideoInterop 0.1.2 includes the macOS portability fixes and is fetched from Hex and crates.io; no local VideoInterop checkout or Cargo patch is needed. DMA-BUF/VAAPI validation remains Linux-only.

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

The demo resolves `video_interop` 0.1.2 and `membrane_video_interop` 0.1 from Hex.
The local Emerge and transcode checkouts use the same published frame contract.

## Test

```bash
mix test
```

The macOS configuration enables the in-process NIF for the headless CPU producer automatically.
The desktop window uses the separate macOS host, which accepts owned RGBA8888 video frames.

## Use The App

- Open the menu in the top-left corner to switch between `Todo` and `Showcase`.
- `Todo` is the main end-to-end example.
- `Showcase` contains smaller focused examples of layout, text, assets, borders, nearby overlays, scroll, keys, interaction, and VideoInterop.
- The `Video Interop` tab compares five Membrane paths: standard looping H.264 playback decoded to owned RGBA8888, separate VAAPI-decoded H.264 and H.265 NV12 DMA-BUF streams, a GPU renderer DMA-BUF stream, and a CPU raster owned-binary stream.
- The bundled H.264 and H.265 clips are derived from *Big Buck Bunny* under CC BY 3.0; attribution and conversion details are in [`priv/video/README.md`](priv/video/README.md).

## Project Layout

A good place to start is the top-level app selector.

`lib/emerge_demo.ex` is the viewport entrypoint. Its `render/1` function renders `EmergeDemo.AppSelector.View`, so that is the first layer of the app.

`lib/emerge_demo/app_selector/` contains a small `Solve` app that owns the active screen and decides whether the viewport shows `Todo` or `Showcase`.

From there, `lib/emerge_demo/todo/app.ex` is a good example of how a `Solve` app is assembled. It defines the Todo controller graph. Read that file first, then follow the controllers it wires together.

`lib/emerge_demo/todo/view.ex` shows the other side of that setup: it reads exposed state with `Solve.Lookup` and renders the Todo UI with `Emerge`.

`lib/emerge_demo/showcase/` follows the same broad pattern, but is organized as smaller focused examples instead of one app flow.

## Video Interop Validation

The tab keeps the standard bundled-file branch (`Membrane.File.Source` → `Membrane.H264.Parser` → `Membrane.H264.FFmpeg.Decoder` → RGBA conversion → real-time playback) and adds separate paced hardware branches through `Membrane.H264.Decoder` and `Membrane.H265.Decoder`. Both emit leased NV12 DMA-BUF frames with sync-file fences. It also runs the existing CPU RGBA8888 binary and GPU renderer DMA-BUF producers. The GPU producer and main renderer APIs are independently selectable for the required four-way matrix:

```bash
EMERGE_DEMO_PRIME_SOURCE_RENDERING_API=opengl \
EMERGE_DEMO_MAIN_RENDERING_API=opengl \
mix run --no-halt
```

Video Interop starts automatically with no enable flag. Each stream reports its own status;
unsupported hardware or a failed decoder shows FAILED without stopping the other streams.
On macOS, the CPU raster producer and software-decoded H.264 stream work with the raster window;
Linux-only GPU/VAAPI paths report failure.

Use `opengl` or `vulkan` for each Linux API variable, or `raster` for the main renderer.
On multi-GPU systems, set `EMERGE_DEMO_PRIME_DRM_NODE` to the allocation node, such as
`/dev/dri/renderD128`; the VAAPI decoder uses that node and defaults to `/dev/dri/renderD128`.

Run the fresh-process candidate matrix smoke with byte-exact solid-frame, animated replacement, hide/show, reconnect, shutdown, FD, and steady-RSS checks:

```bash
EMERGE_DEMO_PRIME_DRM_NODE=/dev/dri/renderD128 ./scripts/prime-matrix.sh
```

A single route can be selected with `./scripts/prime-matrix.sh <producer-api> <main-api>`. For the five-minute 30 FPS soak portion, set `EMERGE_DEMO_PRIME_SOAK_FRAMES=9000 EMERGE_DEMO_PRIME_REQUIRE_RATE=1`. The harness takes `/tmp/emerge-performance.lock` before starting any route.

## Notes

- The main window uses Wayland Vulkan on Linux and macOS raster on macOS.
- The window title defaults to `Emerge Example`.
- Dev mode enables the `Emerge` code reloader for `lib`.

## References

- [Emerge](https://hexdocs.pm/emerge)
- [Solve](https://hexdocs.pm/solve)
