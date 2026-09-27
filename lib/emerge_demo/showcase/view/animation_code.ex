defmodule EmergeDemo.Showcase.View.AnimationCode do
  @moduledoc false

  alias EmergeDemo.Showcase.View.CodeBlock

  @sources %{
    expansion: ~S"""
    row([], [
      el(
        [Animation.change([width(content())], 500, :linear)],
        text(if(expanded?, do: "Live ", else: "L"))
      ),
      el(
        [Animation.change([width(content())], 500, :linear)],
        text(if(expanded?, do: "Preview", else: "P"))
      )
    ])
    """,
    highlight: ~S"""
    steps = 180
    sweeps = 3
    fps = 60
    duration = div(steps * sweeps * 1000, fps)

    # 541 keyframes = 540 intervals at 60 Hz.
    keyframes = for frame <- 0..(steps * sweeps) do
      progress = rem(frame, steps) / steps
      direction = rem(div(frame, steps), sweeps) - 1
      position = -12 + 204 * progress

      stops = for stop <- 0..180 do
        alpha = Kernel.max(0, 1 - abs(stop - position) / 8)
        color_rgba(255, 255, 255, alpha)
      end

      angle = direction * 60 *
        Kernel.max(0, 1 - progress * 1.5)
      [Svg.color(gradient(stops, angle))]
    end

    source = AssetCatalog.template_cloud()
    el([
      width(px(200)), height(px(140)),
      Nearby.in_front(svg([
        width(fill()), height(fill()),
        Animation.animate(keyframes, duration, :linear, :loop)
      ], source))
    ], svg([
      width(fill()), height(fill()),
      Svg.color(color_rgb(43, 145, 203))
    ], source))
    """,
    sidebar: ~S"""
    row([width(fill()), height(fill())], [
      el([
        key(:sidebar),
        Animation.change(
          [width(px(if(open?, do: 150, else: 0)))],
          350,
          :ease_in_out
        ),
        height(fill()),
        Background.color(color_rgb(48, 64, 104))
      ], if open? do
        column([padding(14), spacing(16)], [
          text("Workspace"), text("Overview"),
          text("Projects"), text("Settings")
        ])
      else
        none()
      end),
      el([key(:workspace), width(fill()), padding(16)],
        text("Your workspace"))
    ])
    """,
    accordion: ~S"""
    column([width(fill()), spacing(12)], [
      el([key(:heading)], text("Animation details")),
      el([
        key(:details), width(fill()),
        Animation.change([height(content())], 450, :ease_in_out)
      ], if open? do
        paragraph([width(fill()), padding(14)], [
          text("Content can grow, wrap, or disappear. " <>
            "Emerge animates the resolved height, " <>
            "and siblings move with it.")
        ])
      else
        none()
      end),
      el([key(:following)], text("↑ This row follows the content height"))
    ])
    """,
    notification: ~S"""
    # Keep this inside a stable parent; toggle visible?.
    if visible? do
      el([
        key(:notification),
        Animation.animate_enter([
          [Transform.move_y(24), Transform.alpha(0)],
          [Transform.move_y(0), Transform.alpha(1)]
        ], 350, :ease_out),
        Animation.animate_exit([
          [Transform.move_y(0), Transform.alpha(1)],
          [Transform.move_y(24), Transform.alpha(0)]
        ], 300, :ease_in),
        padding(16), Border.rounded(10),
        Background.color(color_rgb(39, 105, 94))
      ], text("Changes saved"))
    else
      none()
    end
    """,
    glow: ~S"""
    positions = [
      {0, -3}, {3, -3}, {3, 0}, {3, 3}, {0, 3},
      {-3, 3}, {-3, 0}, {-3, -3}, {0, -3}
    ]

    keyframes = Enum.map(positions, fn offset ->
      [Border.shadow(
        offset: offset, blur: 12, size: 2,
        color: color_rgb(43, 145, 203)
      )]
    end)

    el([
      padding(18), Border.rounded(10),
      Background.color(color_rgb(20, 26, 40)),
      Animation.animate(keyframes, 2000, :linear, :loop)
    ], text("Highlighted"))
    """
  }

  @snippets Map.new(@sources, fn {id, source} -> {id, CodeBlock.compile(source)} end)

  def snippet(id), do: Map.fetch!(@snippets, id)
  def source(id), do: snippet(id).source
  def layout(id), do: CodeBlock.layout(snippet(id))
end
