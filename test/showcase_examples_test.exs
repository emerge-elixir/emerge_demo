defmodule EmergeDemo.Showcase.ExamplesTest do
  use ExUnit.Case, async: false

  alias EmergeDemo.Showcase.{App, AssetCatalog, View}
  alias EmergeDemo.Showcase.View.CodeBlock

  @pages [
    layout: 14,
    text: 6,
    assets: 10,
    borders: 7,
    nearby: 4,
    scroll: 4,
    keys: 2,
    interaction: 13,
    animation: 6,
    video_interop: 5
  ]

  setup do
    start_supervised!({App, []})
    :ok
  end

  for {page, count} <- @pages do
    test "#{page} exposes #{count} highlighted code/demo pairs without hovering" do
      page = unquote(page)
      select_page(page)
      tree = View.layout(video_targets())
      examples = examples(tree, page)
      assert length(examples) == unquote(count)
      assert Enum.uniq_by(examples, & &1.key) == examples
      assert Solve.controller_pid(App, :code_hover) == nil

      for node <- nodes(tree) do
        refute node.attrs[:content] in [
                 "ELIXIR",
                 "TRY IT",
                 "Read the code. Try it. Observe what changes."
               ]
      end

      for example <- examples do
        assert [title, explanation, pair] = example.children
        assert title.attrs.font_size == 20
        assert explanation.type == :paragraph
        assert pair.attrs.scrollbar_x
        assert [%{children: [code_slot, demo_slot]} = content] = pair.children
        assert content.attrs.width == {:max, {:px, 1120}, :fill}

        if example.key == {:interaction, :virtual_keyboard} do
          assert content.type == :column
          assert code_slot.attrs.width == :fill
          assert demo_slot.attrs.width == :fill
        else
          assert content.type == :row
          assert code_slot.attrs.width == {:fill, 2}
          assert demo_slot.attrs.width == {:fill, 3}
        end

        assert [code] = code_slot.children
        assert [_demo, _controls] = demo_slot.children
        assert {:ok, _quoted} = Code.string_to_quoted(code_source(code))
        assert Enum.any?(nodes(code), &Map.has_key?(&1.attrs, :font_color))

        for node <- [example, pair, content, code_slot, code] do
          refute Map.has_key?(node.attrs, :on_mouse_enter)
          refute Map.has_key?(node.attrs, :on_mouse_leave)
          assert node.nearby == []
        end
      end

      for width <- [840, 1440] do
        renderer = start_renderer(width)
        EmergeSkia.upload_tree(renderer, tree)
        assert_receive {:emerge_skia_frame, %VideoInterop.Frame{coded_width: ^width}}, 3_000
        assert {:ok, <<137, "PNG", _rest::binary>>} = EmergeSkia.render_to_png(renderer)
        assert :ok = EmergeSkia.stop(renderer)
      end
    end
  end

  test "the Showcase title clears the app selector and navigation at narrow and wide widths" do
    alias EmergeDemo.AppSelector

    start_supervised!({AppSelector.App, []})
    selector = Solve.Lookup.solve(AppSelector.App, :screens)
    send_event(Solve.Lookup.event(selector, :set_screen, :showcase), :screens)

    for menu_open? <- [false, true] do
      selector = Solve.Lookup.solve(AppSelector.App, :screens)

      if selector.menu_open? != menu_open? do
        send_event(Solve.Lookup.event(selector, :toggle_menu), :screens)
      end

      for width <- [640, 840, 1440] do
        {binary, _state, assigned} =
          Emerge.Engine.encode_full(Emerge.Engine.diff_state_new(), AppSelector.View.layout())

        native = EmergeSkia.Native.tree_new()
        assert {:ok, _changed} = EmergeSkia.Native.tree_upload(native, binary)
        assert {:ok, boxes} = EmergeSkia.Native.tree_layout(native, width * 1.0, 900.0, 1.0)
        frames = Map.new(boxes, fn {<<id::64>>, x, y, w, h} -> {id, {x, y, w, h}} end)

        [showcase] = assigned.children
        title = Enum.find(nodes(showcase), &(&1.attrs[:content] == "Showcase"))
        menu_button = event_node(assigned, :on_press, :toggle_menu)
        {tx, ty, _tw, th} = frames[title.id]
        {mx, my, mw, mh} = frames[menu_button.id]

        assert tx >= mx + mw + 12, "selector overlaps the title at width #{width}"
        assert ty >= my
        assert ty + th <= my + mh

        tabs =
          Enum.filter(nodes(showcase), fn node ->
            match?({_pid, {:solve_event, :set_page, _page}}, node.attrs[:on_press])
          end)

        assert length(tabs) == length(@pages)

        for tab <- tabs do
          {_x, y, _w, _h} = frames[tab.id]
          assert y >= my + mh + 12, "navigation overlaps the header at width #{width}"
        end
      end
    end
  end

  test "multi-row asset and border comparisons stay inside their example at both widths" do
    for {page, view} <- [borders: View.Borders, assets: View.Assets], width <- [1120, 1440] do
      {binary, _state, assigned} =
        Emerge.Engine.encode_full(Emerge.Engine.diff_state_new(), view.layout())

      native = EmergeSkia.Native.tree_new()
      assert {:ok, _changed} = EmergeSkia.Native.tree_upload(native, binary)
      assert {:ok, boxes} = EmergeSkia.Native.tree_layout(native, width * 1.0, 20_000.0, 1.0)
      frames = Map.new(boxes, fn {<<id::64>>, x, y, w, h} -> {id, {x, y, w, h}} end)

      for example <- examples(assigned, page) do
        {_x, y, _w, h} = frames[example.id]

        cards =
          Enum.filter(nodes(example), fn node ->
            node.type in [:el, :column] and
              (node.attrs[:width] in [{:px, 118}, {:px, 220}, {:px, 228}, {:px, 300}, {:px, 320}] or
                 node.attrs[:width] == {:min, {:px, 280}, :fill})
          end)

        for card <- cards do
          {_cx, cy, _cw, ch} = frames[card.id]

          assert cy + ch <= y + h + 1,
                 "#{inspect(example.key)} clips a comparison card at width #{width}"
        end
      end
    end
  end

  test "all transformed hit targets and their backdrops fit inside the example" do
    for width <- [744, 1120, 1232, 1392] do
      {assigned, frames} = native_layout(View.Interaction.layout(), width)

      example =
        Enum.find(
          examples(assigned, :interaction),
          &(&1.key == {:interaction, :transformed_hit_testing})
        )

      [_title, _explanation, pair] = example.children
      {_px, py, _pw, ph} = frames[pair.id]

      cards =
        Enum.filter(nodes(example), fn node ->
          node.type == :column and node.attrs[:width] == {:min, {:px, 238}, :fill}
        end)

      assert length(cards) == 3

      for card <- cards do
        {_x, y, _w, h} = frames[card.id]
        assert y + h <= py + ph + 1, "transformed card is clipped at width #{width}"
      end

      scaled = event_node(example, :on_mouse_down, :scaled_down)
      assert scaled.attrs.scale == 1.18
      {_x, y, _w, h} = frames[scaled.id]
      painted_bottom = y + h + h * (scaled.attrs.scale - 1) / 2
      assert painted_bottom <= py + ph
    end

    tree = View.Interaction.layout()
    send_event(event_node(tree, :on_mouse_down, :scaled_down).attrs.on_mouse_down, :interaction)
    send_event(event_node(tree, :on_mouse_up, :scaled_up).attrs.on_mouse_up, :interaction)

    assert %{scaled_down_count: 1, scaled_up_count: 1} =
             Solve.Lookup.solve(App, :interaction).transformed
  end

  test "the keyboard follows its code at full width without wrapping key rows" do
    for shifted? <- [false, true] do
      keyboard = Solve.Lookup.solve(App, :soft_keyboard)

      if keyboard.shift_active? != shifted? do
        send_event(Solve.Lookup.event(keyboard, :toggle_shift), :soft_keyboard)
      end

      for width <- [744, 1120, 1232, 1392] do
        {assigned, frames} = native_layout(View.Interaction.layout(), width)

        example =
          Enum.find(
            examples(assigned, :interaction),
            &(&1.key == {:interaction, :virtual_keyboard})
          )

        [_title, _explanation, pair] = example.children
        assert [%{type: :column, children: [code, demo]}] = pair.children
        {cx, cy, cw, ch} = frames[code.id]
        {dx, dy, dw, dh} = frames[demo.id]
        assert cx == dx
        assert cw == dw
        assert dy >= cy + ch + 24

        key_rows =
          Enum.filter(nodes(demo), fn node ->
            node.type == :wrapped_row and
              Enum.any?(node.children, &match?({:soft_key, _}, &1.key))
          end)

        assert length(key_rows) == 5

        for row <- key_rows do
          key_frames = Enum.map(row.children, &Map.fetch!(frames, &1.id))
          row_tops = Enum.map(key_frames, &elem(&1, 1))

          assert Enum.max(row_tops) - Enum.min(row_tops) < 1,
                 "keyboard row wraps at width #{width}"

          for {kx, ky, kw, kh} <- key_frames do
            assert kx >= dx
            assert kx + kw <= dx + dw
            assert ky + kh <= dy + dh
          end
        end
      end
    end
  end

  test "real hover and input events still reach their controllers without changing the code" do
    select_page(:interaction)
    tree = View.layout()
    before_sources = sources(tree, :interaction)
    renderer = start_renderer(1200)
    {state, _assigned} = EmergeSkia.upload_tree(renderer, tree)
    assert_receive {:emerge_skia_frame, %VideoInterop.Frame{}}, 3_000

    hover = event_node(tree, :on_mouse_enter, :manual_hover_enter)
    send_event(hover.attrs.on_mouse_enter, :interaction)
    assert Solve.Lookup.solve(App, :interaction).manual_hover?

    input = event_node(tree, :on_change, :changed)
    {pid, {:solve_event, :changed}} = input.attrs.on_change
    send_event({pid, {:solve_event, :changed, "A walkthrough input"}}, :text_input)
    assert Solve.Lookup.solve(App, :text_input).value == "A walkthrough input"

    next = View.layout()
    assert sources(next, :interaction) == before_sources
    assert {_state, _assigned} = EmergeSkia.patch_tree(renderer, state, next)
    assert_receive {:emerge_skia_frame, %VideoInterop.Frame{}}, 3_000
  end

  test "keyed examples still reorder live state while code stays visible" do
    select_page(:keys)
    tree = View.layout()
    before = Solve.Lookup.solve(App, :keys).scroll_items
    button = event_node(tree, :on_press, :rotate_scroll_items)
    send_event(button.attrs.on_press, :keys)
    after_items = Solve.Lookup.solve(App, :keys).scroll_items
    assert after_items != before
    assert Enum.sort(after_items) == Enum.sort(before)
    assert sources(View.layout(), :keys) == sources(tree, :keys)
  end

  test "video statuses and target identities survive the shared example layout" do
    select_page(:video_interop)
    targets = video_targets()
    tree = View.layout(targets)
    assert length(Enum.filter(nodes(tree), &(&1.type == :video))) == 5

    failed = %{targets | h264_dmabuf: {{:error, :dma_buf_requires_linux}, :h264_dmabuf_playback}}
    next = View.layout(failed)
    assert length(Enum.filter(nodes(next), &(&1.type == :video))) == 4

    assert Enum.any?(
             nodes(next),
             &(&1.attrs[:content] == "Stream failed: DMA-BUF requires Linux.")
           )

    assert sources(next, :video_interop) == sources(tree, :video_interop)
  end

  test "static snippets format and highlight once, retaining their Elixir source" do
    require CodeBlock

    snippet =
      CodeBlock.snippet(~S"""
      el([width(fill())], text("Hello <world>"))
      """)

    assert %CodeBlock{} = snippet
    assert code_source(snippet.tree) == snippet.source
    assert snippet.source =~ "Hello <world>"
    assert CodeBlock.layout(snippet) == snippet.tree
  end

  defp select_page(page) do
    pages = Solve.Lookup.solve(App, :pages)

    if pages.current != page do
      send_event(Solve.Lookup.event(pages, :set_page, page), :pages)
    end
  end

  defp send_event({pid, message}, controller) do
    send(pid, message)

    assert_receive %Solve.Message{payload: %Solve.Update{controller_name: ^controller}} = update,
                   1_000

    Solve.Lookup.handle_message(update)
  end

  defp event_node(tree, attr, event) do
    Enum.find(nodes(tree), fn node ->
      case node.attrs[attr] do
        {_pid, {:solve_event, ^event}} -> true
        _other -> false
      end
    end) || flunk("missing #{attr} event #{event}")
  end

  defp examples(tree, page) do
    Enum.filter(nodes(tree), fn node ->
      match?({^page, _example}, node.key)
    end)
  end

  defp sources(tree, page) do
    Enum.map(examples(tree, page), fn example ->
      [_title, _explanation, %{children: [%{children: [code_slot, _demo]}]}] = example.children
      [code] = code_slot.children
      code_source(code)
    end)
  end

  defp code_source(tree) do
    Enum.map_join(tree.children, "\n", fn line ->
      line
      |> nodes()
      |> Enum.filter(&(&1.type == :text))
      |> Enum.map_join(& &1.attrs.content)
      |> String.replace("\u200B", "")
    end)
  end

  defp native_layout(tree, width) do
    {binary, _state, assigned} = Emerge.Engine.encode_full(Emerge.Engine.diff_state_new(), tree)
    native = EmergeSkia.Native.tree_new()
    assert {:ok, _changed} = EmergeSkia.Native.tree_upload(native, binary)
    assert {:ok, boxes} = EmergeSkia.Native.tree_layout(native, width * 1.0, 20_000.0, 1.0)
    frames = Map.new(boxes, fn {<<id::64>>, x, y, w, h} -> {id, {x, y, w, h}} end)
    {assigned, frames}
  end

  defp start_renderer(width) do
    {:ok, renderer} =
      EmergeSkia.start(
        otp_app: :emerge_demo,
        backend: :headless,
        rendering_api: :raster,
        width: width,
        height: 900,
        assets: AssetCatalog.renderer_assets_config(),
        headless: [target: self(), pixel_format: :rgba8888]
      )

    on_exit(fn -> EmergeSkia.stop(renderer) end)
    renderer
  end

  defp video_targets do
    %{
      dma_buf: {:streaming, :headless_prime_validation},
      binary: {:streaming, :headless_binary_validation},
      h264: {:streaming, :h264_file_playback},
      h264_dmabuf: {:streaming, :h264_dmabuf_playback},
      h265_dmabuf: {:streaming, :h265_dmabuf_playback}
    }
  end

  defp nodes(node),
    do: [node | Enum.flat_map(node.children ++ Keyword.values(node.nearby), &nodes/1)]
end
