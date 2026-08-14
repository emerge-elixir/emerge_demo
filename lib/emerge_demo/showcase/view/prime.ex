defmodule EmergeDemo.Showcase.View.Prime do
  @moduledoc false

  use Emerge.UI

  alias EmergeSkia.VideoTarget

  def layout({{:error, reason}, _target}) do
    column([width(fill()), spacing(18)], [
      intro_card({:error, reason}),
      unavailable_panel("PRIME setup failed: #{format_reason(reason)}")
    ])
  end

  def layout({status, %VideoTarget{} = target}) do
    column([width(fill()), spacing(18)], [
      intro_card(status),
      el(
        [
          width(fill()),
          height(px(360)),
          padding(18),
          Background.color(color_rgb(14, 20, 36)),
          Border.rounded(18),
          Border.width(1),
          Border.color(color_rgb(44, 57, 88)),
          Border.shadow(offset: {0, 16}, blur: 36, size: 0, color: color_rgba(15, 23, 42, 0.2))
        ],
        video(
          [
            width(fill()),
            height(fill()),
            image_fit(:contain),
            Background.color(color_rgb(5, 9, 18)),
            Border.rounded(12)
          ],
          target
        )
      ),
      validation_steps()
    ])
  end

  def layout(_target) do
    column([width(fill()), spacing(18)], [
      intro_card(:starting),
      unavailable_panel("Waiting for the window renderer and PRIME video target…")
    ])
  end

  defp intro_card(status) do
    row(
      [
        width(fill()),
        padding(18),
        spacing(16),
        Background.color(color_rgb(245, 248, 255)),
        Border.rounded(14),
        Border.width(1),
        Border.color(color_rgb(214, 223, 244))
      ],
      [
        column([width(fill()), spacing(6)], [
          el(
            [Font.size(18), Font.bold(), Font.color(color_rgb(31, 44, 74))],
            text("Live zero-copy validation")
          ),
          paragraph([width(fill()), Font.size(14), Font.color(color_rgb(82, 96, 126))], [
            text(
              "A second headless viewport exports its animated scene as DMA-BUFs. This tab imports those buffers into a renderer-owned video target and presents them in the main Wayland viewport."
            )
          ])
        ]),
        status_badge(status)
      ]
    )
  end

  defp status_badge(:streaming),
    do: badge("STREAMING", color_rgb(220, 252, 231), color_rgb(22, 101, 52))

  defp status_badge(:waiting),
    do: badge("WAITING", color_rgb(224, 242, 254), color_rgb(3, 105, 161))

  defp status_badge(:starting),
    do: badge("STARTING", color_rgb(254, 249, 195), color_rgb(133, 77, 14))

  defp status_badge({:error, _reason}),
    do: badge("FAILED", color_rgb(254, 226, 226), color_rgb(153, 27, 27))

  defp badge(label, background, foreground) do
    el(
      [
        padding_each(7, 11, 7, 11),
        Background.color(background),
        Border.rounded(999),
        Font.size(12),
        Font.bold(),
        Font.color(foreground)
      ],
      text(label)
    )
  end

  defp format_reason(reason) do
    inspect(reason, limit: 8, printable_limit: 320)
  end

  defp unavailable_panel(message) do
    el(
      [
        width(fill()),
        height(px(260)),
        center_x(),
        center_y(),
        padding(24),
        Background.color(color_rgb(250, 250, 252)),
        Border.rounded(18),
        Border.width(1),
        Border.color(color_rgb(225, 228, 235)),
        Font.size(15),
        Font.color(color_rgb(103, 110, 126))
      ],
      text(message)
    )
  end

  defp validation_steps do
    wrapped_row([width(fill()), spacing_xy(12, 12)], [
      step_card(
        "1",
        "Headless render",
        "OpenGL or Vulkan renders the second viewport offscreen."
      ),
      step_card(
        "2",
        "PRIME export",
        "The producer exports a linear ABGR8888 DMA-BUF descriptor."
      ),
      step_card(
        "3",
        "Direct connection",
        "Emerge transfers canonical frames into the main renderer."
      ),
      step_card("4", "Lease retirement", "Producer buffers retire only after GPU consumption.")
    ])
  end

  defp step_card(number, title, detail) do
    column(
      [
        width(px(230)),
        padding(14),
        spacing(7),
        Background.color(color_rgb(252, 252, 253)),
        Border.rounded(12),
        Border.width(1),
        Border.color(color_rgb(228, 230, 236))
      ],
      [
        row([spacing(8)], [
          badge(number, color_rgb(232, 238, 255), color_rgb(52, 76, 145)),
          el([Font.size(14), Font.bold(), Font.color(color_rgb(35, 42, 56))], text(title))
        ]),
        paragraph([width(fill()), Font.size(12), Font.color(color_rgb(100, 107, 121))], [
          text(detail)
        ])
      ]
    )
  end
end
