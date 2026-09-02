defmodule EmergeDemo.PrimeSource do
  @moduledoc """
  Headless viewport used as a live DMA-BUF producer for the Showcase PRIME tab.
  """

  use Emerge

  @width 640
  @height 420

  @spec dimensions() :: {pos_integer(), pos_integer()}
  def dimensions, do: {@width, @height}

  @impl Viewport
  def mount(opts) do
    {video_output_target, opts} = Keyword.pop!(opts, :video_output_target)

    prime_opts =
      [max_in_flight: 3, on_backpressure: :drop_new]
      |> maybe_put_drm_node(EmergeDemo.Application.prime_drm_node())

    defaults = [
      emerge_skia: [
        otp_app: :emerge_demo,
        backend: :headless,
        rendering_api: EmergeDemo.Application.prime_source_rendering_api(),
        width: @width,
        height: @height,
        renderer_cache: [enabled: true],
        renderer_stats_log: true,
        headless: [
          mode: :prime,
          target: video_output_target,
          target_fps: 30,
          prime: prime_opts
        ]
      ]
    ]

    {:ok, Keyword.merge(defaults, opts)}
  end

  defp maybe_put_drm_node(opts, nil), do: opts
  defp maybe_put_drm_node(opts, drm_node), do: Keyword.put(opts, :drm_node, drm_node)

  @impl Viewport
  def render do
    el(
      [
        width(fill()),
        height(fill()),
        padding(28),
        Background.gradient(color_rgb(24, 36, 76), color_rgb(83, 50, 130), 24)
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
            text("Headless PRIME source")
          ),
          el(
            [
              padding_each(7, 12, 7, 12),
              Background.color(color_rgba(255, 255, 255, 0.16)),
              Border.rounded(999),
              Font.size(13),
              Font.color(color_rgb(235, 242, 255))
            ],
            text("DMA-BUF • ABGR8888")
          )
        ]),
        paragraph([width(fill()), Font.size(16), Font.color(color_rgb(218, 226, 249))], [
          text(
            "This animated scene is rendered offscreen by a second Emerge viewport. PRIME exports each frame as a DMA-BUF for direct import into the Showcase window."
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
        validation_card("RENDER", rendering_api_label(), color_rgb(69, 201, 183), -12),
        validation_card("EXPORT", "DMA-BUF", color_rgb(116, 153, 255), 12),
        validation_card("PRESENT", "Skia", color_rgb(227, 132, 255), -12)
      ])
    )
  end

  defp rendering_api_label do
    case EmergeDemo.Application.prime_source_rendering_api() do
      :opengl -> "OpenGL"
      :vulkan -> "Vulkan"
      _other -> "GPU"
    end
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
