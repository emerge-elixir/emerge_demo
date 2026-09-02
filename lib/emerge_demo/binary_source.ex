defmodule EmergeDemo.BinarySource do
  @moduledoc """
  CPU headless viewport used as a live RGBA8888 binary producer for the Video Interop tab.
  """

  use Emerge

  @width 640
  @height 420

  @spec dimensions() :: {pos_integer(), pos_integer()}
  def dimensions, do: {@width, @height}

  @impl Viewport
  def mount(opts) do
    {video_output_target, opts} = Keyword.pop!(opts, :video_output_target)

    defaults = [
      emerge_skia: [
        otp_app: :emerge_demo,
        backend: :headless,
        rendering_api: :raster,
        width: @width,
        height: @height,
        renderer_cache: [enabled: true],
        renderer_stats_log: true,
        headless: [
          mode: :binary,
          target: video_output_target,
          target_fps: 30,
          pixel_format: :rgba8888
        ]
      ]
    ]

    {:ok, Keyword.merge(defaults, opts)}
  end

  @impl Viewport
  def render do
    el(
      [
        width(fill()),
        height(fill()),
        padding(28),
        Background.gradient(color_rgb(16, 72, 70), color_rgb(27, 112, 94), 24)
      ],
      column([width(fill()), height(fill()), spacing(20)], [
        row([width(fill())], [
          el(
            [
              width(fill()),
              Font.size(30),
              Font.bold(),
              Font.color(color_rgb(255, 255, 255))
            ],
            text("Headless CPU source")
          ),
          el(
            [
              padding_each(7, 12, 7, 12),
              Background.color(color_rgba(255, 255, 255, 0.16)),
              Border.rounded(999),
              Font.size(13),
              Font.color(color_rgb(235, 255, 250))
            ],
            text("BINARY • RGBA8888")
          )
        ]),
        paragraph([width(fill()), Font.size(16), Font.color(color_rgb(211, 242, 235))], [
          text(
            "This scene is rendered by Skia's CPU raster backend into an owned RGBA8888 binary and imported by the Showcase renderer through VideoInterop."
          )
        ]),
        animated_validation_scene()
      ])
    )
  end

  defp animated_validation_scene do
    el(
      [
        width(fill()),
        height(fill()),
        padding(20),
        Background.color(color_rgba(255, 255, 255, 0.1)),
        Border.rounded(20),
        Border.width(1),
        Border.color(color_rgba(255, 255, 255, 0.2))
      ],
      row([width(fill()), height(fill()), spacing(24)], [
        validation_card("RENDER", "CPU", color_rgb(45, 212, 191), -12),
        validation_card("STORE", "Binary", color_rgb(34, 197, 94), 12),
        validation_card("IMPORT", "RGBA", color_rgb(250, 204, 21), -12)
      ])
    )
  end

  defp validation_card(title, detail, color, travel) do
    el(
      [
        width(fill()),
        height(px(142)),
        center_y(),
        padding(16),
        Background.color(color),
        Border.rounded(16),
        Border.shadow(offset: {0, 14}, blur: 28, size: 0, color: color_rgba(0, 0, 0, 0.22)),
        Animation.animate(
          [
            [Transform.move_y(travel), Transform.rotate(-3)],
            [Transform.move_y(-travel), Transform.rotate(3)],
            [Transform.move_y(travel), Transform.rotate(-3)]
          ],
          1_800,
          :ease_in_out,
          :loop
        )
      ],
      column([spacing(8)], [
        el([Font.size(12), Font.bold(), Font.color(color_rgba(15, 23, 42, 0.72))], text(title)),
        el([Font.size(20), Font.bold(), Font.color(color_rgb(255, 255, 255))], text(detail))
      ])
    )
  end
end
