# Emerge Demo

A demo application built with `Emerge` and `Solve`. It includes a Todo app and a Showcase app, so you can see how `Emerge` UI code and `Solve` state management fit together in a small Elixir project.

## Requirements

- Elixir `~> 1.19`
- Linux with a working Wayland session, or macOS 15+

### Platform Notes

- `Emerge` `~> 0.2.0` supports Linux and macOS.
- Linux: Ubuntu 24.04 or newer should work with the precompiled `emerge` binary.

## Run Locally

This starts the demo in dev mode with hot reloading enabled for files under `lib`.
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

If the precompiled `emerge` NIF does not load on your distro, rebuild `emerge` locally instead:

```bash
mix deps.clean --build emerge
EMERGE_SKIA_BUILD=1 mix deps.compile emerge
```

This requires a Rust toolchain plus the native graphics build dependencies for `emerge` on your platform.


## Test

```bash
mix test
```

## Use The App

- Open the menu in the top-left corner to switch between `Todo` and `Showcase`.
- `Todo` is the main end-to-end example.
- `Showcase` contains smaller focused examples of layout, text, assets, borders, nearby overlays, scroll, keys, and interaction.

## Project Layout

A good place to start is the top-level app selector.

`lib/emerge_demo.ex` is the viewport entrypoint. Its `render/0` function renders `EmergeDemo.AppSelector.View`, so that is the first layer of the app.

`lib/emerge_demo/app_selector/` contains a small `Solve` app that owns the active screen and decides whether the viewport shows `Todo` or `Showcase`.

From there, `lib/emerge_demo/todo/app.ex` is a good example of how a `Solve` app is assembled. It defines the Todo controller graph. Read that file first, then follow the controllers it wires together.

`lib/emerge_demo/todo/view.ex` shows the other side of that setup: it reads exposed state with `Solve.Lookup` and renders the Todo UI with `Emerge`.

`lib/emerge_demo/showcase/` follows the same broad pattern, but is organized as smaller focused examples instead of one app flow.

## Notes

- Linux renderer backend defaults to Wayland
- window title defaults to `Emerge Example`
- dev mode enables the `Emerge` code reloader for `lib`

## References

- [Emerge](https://hexdocs.pm/emerge)
- [Solve](https://hexdocs.pm/solve)
