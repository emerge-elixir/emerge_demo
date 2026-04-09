# Emerge Demo

This is the standalone demo app for `Emerge`.
Demo repo: https://github.com/emerge-elixir/emerge_demo

It combines a realistic Todo app with a broader Showcase so you can inspect both stateful application structure and focused examples of individual `Emerge` features.

## Included screens

- `Todo` for inline editing, filtering, focus handling, and per-item editor state
- `Showcase` for focused feature demos:
  - `Layout`
  - `Text`
  - `Assets`
  - `Borders`
  - `Nearby`
  - `Scroll`
  - `Keys`
  - `Interaction`

## What this example demonstrates

- an `Emerge` viewport shell (`EmergeDemo`)
- multiple `Solve` apps (`Todo`, `Showcase`, and app selection)
- app-level screen switching
- collection controllers for per-item Todo editing
- focus styling and `focus_on_mount()` for inline editing
- hover code previews in Showcase
- startup font assets and runtime path allowlisting
- keyed vs unkeyed UI behavior
- keyboard, pointer, scroll, nearby, transform, and soft-keyboard demos

## Run

```bash
mix deps.get
iex -S mix
```

This starts the demo in dev mode with hot reloading enabled for files under `lib`.

## Test

```bash
mix test
```

## What to try

- switch between `Todo` and `Showcase`
- edit a Todo inline and watch focus move with `focus_on_mount()`
- open `Assets` and compare static, runtime, and blocked sources
- open `Keys` and compare keyed vs unkeyed behavior
- open `Interaction` and try the soft keyboard and focused key listener
- hover Showcase examples to inspect the simplified code previews

## Runtime notes

- renderer backend defaults to Wayland
- window title defaults to `Emerge Example`
- dev mode enables the `Emerge` code reloader for `lib`
- Showcase config includes startup-loaded font assets and runtime path allowlisting

## Project structure

- `lib/emerge_demo.ex` - viewport entrypoint and renderer config
- `lib/emerge_demo/application.ex` - app supervision tree
- `lib/emerge_demo/todo/` - Todo app, controllers, and views
- `lib/emerge_demo/showcase/` - Showcase app, controllers, views, and asset catalog
- `lib/emerge_demo/app_selector/` - screen selection shell

## More docs

For the `Emerge` library, see https://github.com/emerge-elixir/emerge and https://hexdocs.pm/emerge.
