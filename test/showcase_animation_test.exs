defmodule EmergeDemo.Showcase.AnimationTest do
  use ExUnit.Case, async: false
  use Emerge.UI

  alias EmergeDemo.Showcase.{Animation, App, View}
  alias EmergeDemo.Showcase.View.Animation, as: AnimationPage
  alias EmergeDemo.Showcase.View.AnimationCode

  @examples [:expansion, :highlight, :sidebar, :accordion, :notification, :glow]
  @fields [:expanded?, :sidebar_open?, :details_open?, :notification_visible?]

  test "demo controls toggle independently, reverse, and ignore unknown fields" do
    initial = Animation.init(%{}, %{})
    assert Animation.expose(initial, %{}, %{}) == Map.new(@fields, &{&1, false})

    for field <- @fields do
      toggled = Animation.toggle(field, initial)
      assert toggled == Map.put(initial, field, true)
      assert Animation.toggle(field, toggled) == initial
    end

    assert Animation.toggle(:unknown, initial) == initial
  end

  test "the registered tab has six side-by-side code/demo pairs and working controls" do
    start_supervised!({App, []})
    pages = Solve.Lookup.solve(App, :pages)
    {pid, message} = Solve.Lookup.event(pages, :set_page, :animation)
    send(pid, message)
    assert_receive %Solve.Message{} = update
    Solve.Lookup.handle_message(update)

    tree = View.layout()
    nodes = nodes(tree)
    assert Enum.any?(nodes, &(&1.attrs[:content] == "Live demos + highlighted Elixir"))
    refute Enum.any?(nodes, &Map.has_key?(&1.attrs, :on_mouse_enter))

    copy = nodes |> Enum.filter(&(&1.type == :text)) |> Enum.map_join("\n", & &1.attrs.content)
    refute copy =~ ~r/\b(?:Goat|slides?|User Interface|User Interaction)\b/
    assert copy =~ "Expanding labels"

    for id <- @examples do
      section = Enum.find(nodes, &(&1.key == {:animation, id}))
      assert section

      assert [_title, _description, %{children: [%{type: :row, children: [code, demo]}]}] =
               section.children

      assert code == AnimationCode.layout(id)
      assert demo.type == :column
    end

    button =
      Enum.find(nodes, &match?({_pid, {:solve_event, :toggle, :expanded?}}, &1.attrs[:on_press]))

    {pid, message} = button.attrs.on_press
    send(pid, message)
    assert_receive %Solve.Message{} = update
    Solve.Lookup.handle_message(update)
    assert Solve.Lookup.solve(App, :animation).expanded?
    assert Enum.any?(nodes(View.layout()), &(&1.attrs[:content] == "Live "))
  end

  test "the complete page uploads and patches every toggle in a narrow viewport" do
    start_supervised!({App, []})
    dispatch(:pages, :set_page, :animation)
    renderer = start_renderer(980, 800)
    {state, _assigned} = EmergeSkia.upload_tree(renderer, View.layout())
    assert_receive {:emerge_skia_frame, %VideoInterop.Frame{}}, 1_000

    Enum.reduce(@fields ++ @fields, state, fn field, state ->
      dispatch(:animation, :toggle, field)
      {state, _assigned} = EmergeSkia.patch_tree(renderer, state, View.layout())
      assert_receive {:emerge_skia_frame, %VideoInterop.Frame{}}, 1_000
      state
    end)

    assert {:ok, <<137, "PNG", _rest::binary>>} = EmergeSkia.render_to_png(renderer)
  end

  test "label expansion retains identity and animates intrinsic width on both text nodes" do
    collapsed = AnimationPage.text_expansion(false)
    expanded = AnimationPage.text_expansion(true)

    assert Enum.map(collapsed.children, & &1.key) == [:first_word, :second_word]
    assert Enum.map(expanded.children, & &1.key) == [:first_word, :second_word]
    assert Enum.map(collapsed.children, &hd(&1.children).attrs.content) == ["L", "P"]
    assert Enum.map(expanded.children, &hd(&1.children).attrs.content) == ["Live ", "Preview"]

    for node <- collapsed.children ++ expanded.children do
      assert node.attrs.width == :content
      assert node.attrs.animate_change == %{width: %{duration: 500, curve: :linear}}
    end
  end

  test "sidebar and accordion animate retained layout targets in both directions" do
    for open? <- [false, true] do
      [sidebar, workspace] = AnimationPage.sidebar(open?).children
      assert sidebar.key == :sidebar
      assert sidebar.attrs.width == {:px, if(open?, do: 150, else: 0)}
      assert sidebar.attrs.animate_change.width == %{duration: 350, curve: :ease_in_out}
      assert workspace.attrs.width == :fill

      [_heading, details, _following_row] = AnimationPage.accordion(open?).children
      assert details.key == :details
      assert details.attrs.height == :content
      assert details.attrs.animate_change.height == %{duration: 450, curve: :ease_in_out}
      assert hd(details.children).type == if(open?, do: :paragraph, else: :none)
    end
  end

  test "notification is actually mounted/removed and has both lifecycle animations" do
    refute Enum.any?(nodes(AnimationPage.notification(false)), &(&1.key == :notification))
    notification = Enum.find(nodes(AnimationPage.notification(true)), &(&1.key == :notification))
    assert notification.attrs.animate_enter.duration == 350
    assert notification.attrs.animate_exit.duration == 300
    assert notification.attrs.animate_exit.repeat == :once
  end

  test "highlight sweep uses exactly 60 Hz intervals and seamless transparent boundaries" do
    highlight = AnimationPage.svg_highlight()
    assert [in_front: overlay] = highlight.nearby
    assert overlay.attrs.image_src == hd(highlight.children).attrs.image_src

    assert %{repeat: :loop, curve: :linear, duration: 9000, keyframes: keyframes} =
             overlay.attrs.animate

    assert length(keyframes) == 541
    assert (length(keyframes) - 1) * 1000 == overlay.attrs.animate.duration * 60
    assert hd(keyframes) == List.last(keyframes)

    for keyframe <- keyframes do
      assert %{svg_color: {:color_gradient, stops, _angle}} = keyframe
      assert length(stops) == 181
    end

    for {frame, index} <- Enum.with_index(keyframes), rem(index, 180) in [0, 179] do
      assert Enum.all?(elem(frame.svg_color, 1), &match?({:color_rgba, {255, 255, 255, 0}}, &1))
    end

    # Adjacent samples move the band rather than flashing between sparse stops.
    assert Enum.any?(keyframes, fn frame ->
             Enum.any?(elem(frame.svg_color, 1), fn {:color_rgba, {_, _, _, alpha}} ->
               alpha > 0
             end)
           end)

    for [left, right] <- Enum.chunk_every(keyframes, 2, 1, :discard) do
      for {{:color_rgba, {_, _, _, a}}, {:color_rgba, {_, _, _, b}}} <-
            Enum.zip(elem(left.svg_color, 1), elem(right.svg_color, 1)) do
        assert abs(a - b) <= 37
      end
    end
  end

  test "orbiting highlight follows a closed shadow path" do
    assert %{repeat: :loop, keyframes: shadows} = AnimationPage.orbiting_glow().attrs.animate
    assert hd(shadows) == List.last(shadows)
  end

  test "highlight recipe describes the exact animation used by the demo" do
    {recipe, _binding} =
      Code.eval_string(
        "use Emerge.UI\nalias EmergeDemo.Showcase.AssetCatalog\n" <>
          AnimationCode.source(:highlight)
      )

    assert recipe.nearby[:in_front].attrs.animate ==
             AnimationPage.svg_highlight().nearby[:in_front].attrs.animate
  end

  test "recipes execute in both states and encode as valid UI trees" do
    for id <- @examples, enabled? <- [false, true] do
      {tree, _binding} =
        Code.eval_string(
          "use Emerge.UI\nalias EmergeDemo.Showcase.AssetCatalog\n" <> AnimationCode.source(id),
          expanded?: enabled?,
          open?: enabled?,
          visible?: enabled?
        )

      assert {<<"EMRG", _rest::binary>>, _state, _assigned} =
               Emerge.Engine.encode_full(Emerge.Engine.diff_state_new(), el([], tree))
    end
  end

  test "highlighted recipes retain source and all examples render without a display server" do
    for id <- @examples do
      code = AnimationCode.layout(id)
      [_label, highlighted, _note] = code.children
      source = AnimationCode.source(id)
      assert {:ok, _ast} = Code.string_to_quoted(source)

      rendered_source =
        highlighted.children
        |> Enum.map(fn line ->
          nodes(line)
          |> Enum.filter(&(&1.type == :text))
          |> Enum.map_join(& &1.attrs.content)
          |> String.replace("\u200B", "")
        end)
        |> Enum.join("\n")

      assert rendered_source == String.trim(source)
    end

    demos = [
      AnimationPage.text_expansion(false),
      AnimationPage.text_expansion(true),
      AnimationPage.svg_highlight(),
      AnimationPage.sidebar(false),
      AnimationPage.sidebar(true),
      AnimationPage.accordion(false),
      AnimationPage.accordion(true),
      AnimationPage.notification(false),
      AnimationPage.notification(true),
      AnimationPage.orbiting_glow()
    ]

    renderer = start_renderer(440, 240)

    for demo <- demos do
      EmergeSkia.upload_tree(renderer, el([width(fill()), height(fill())], demo))
      assert_receive {:emerge_skia_frame, %VideoInterop.Frame{}}, 1_000
      assert {:ok, <<137, "PNG", _rest::binary>>} = EmergeSkia.render_to_png(renderer)
    end
  end

  defp dispatch(controller, event, payload) do
    controller = Solve.Lookup.solve(App, controller)
    {pid, message} = Solve.Lookup.event(controller, event, payload)
    send(pid, message)
    assert_receive %Solve.Message{} = update
    Solve.Lookup.handle_message(update)
  end

  defp start_renderer(width, height) do
    {:ok, renderer} =
      EmergeSkia.start(
        otp_app: :emerge_demo,
        backend: :headless,
        rendering_api: :raster,
        width: width,
        height: height,
        headless: [target: self(), pixel_format: :rgba8888]
      )

    on_exit(fn -> EmergeSkia.stop(renderer) end)
    renderer
  end

  defp nodes(node) do
    [node | Enum.flat_map(node.children ++ Keyword.values(node.nearby), &nodes/1)]
  end
end
