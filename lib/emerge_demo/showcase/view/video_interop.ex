defmodule EmergeDemo.Showcase.View.VideoInterop do
  @moduledoc false

  use Emerge.UI

  def layout(%{dma_buf: dma_buf, binary: binary}) do
    column([width(fill()), spacing(18)], [
      intro_card(),
      wrapped_row([width(fill()), spacing_xy(16, 16)], [
        stream_card(
          "GPU DMA-BUF",
          "ABGR8888 • explicit synchronization",
          "The GPU producer exports a linear DMA-BUF and synchronization fence for direct import.",
          dma_buf
        ),
        stream_card(
          "CPU binary",
          "RGBA8888 • owned storage",
          "The raster producer emits an owned RGBA8888 binary that the target renderer imports.",
          binary
        )
      ]),
      validation_steps()
    ])
  end

  def layout(_targets) do
    layout(%{dma_buf: {:starting, nil}, binary: {:starting, nil}})
  end

  defp intro_card do
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
            text("Live VideoInterop paths")
          ),
          paragraph([width(fill()), Font.size(14), Font.color(color_rgb(82, 96, 126))], [
            text(
              "Two headless Emerge viewports send the same kind of animated UI through VideoInterop: one uses leased GPU DMA-BUF storage and the other uses an owned CPU RGBA8888 binary."
            )
          ])
        ]),
        badge("2 STREAMS", color_rgb(220, 252, 231), color_rgb(22, 101, 52))
      ]
    )
  end

  defp stream_card(title, format, detail, {status, target}) do
    column(
      [
        width(px(470)),
        padding(14),
        spacing(10),
        Background.color(color_rgb(252, 252, 253)),
        Border.rounded(16),
        Border.width(1),
        Border.color(color_rgb(225, 228, 236))
      ],
      [
        row([width(fill()), spacing(10)], [
          column([width(fill()), spacing(3)], [
            el([Font.size(16), Font.bold(), Font.color(color_rgb(35, 42, 56))], text(title)),
            el([Font.size(12), Font.color(color_rgb(92, 101, 122))], text(format))
          ]),
          status_badge(status)
        ]),
        video_panel(target),
        paragraph([width(fill()), Font.size(12), Font.color(color_rgb(100, 107, 121))], [
          text(detail)
        ])
      ]
    )
  end

  defp video_panel(target) when is_atom(target) do
    el(
      [
        width(fill()),
        height(px(280)),
        padding(8),
        Background.color(color_rgb(14, 20, 36)),
        Border.rounded(12)
      ],
      video(
        [
          width(fill()),
          height(fill()),
          image_fit(:contain),
          Background.color(color_rgb(5, 9, 18)),
          Border.rounded(8)
        ],
        target
      )
    )
  end

  defp video_panel(_target) do
    el(
      [
        width(fill()),
        height(px(280)),
        center_x(),
        center_y(),
        padding(20),
        Background.color(color_rgb(14, 20, 36)),
        Border.rounded(12),
        Font.size(13),
        Font.color(color_rgb(190, 199, 220))
      ],
      text("Waiting for the headless renderer…")
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

  defp status_badge(_status),
    do: badge("WAITING", color_rgb(224, 242, 254), color_rgb(3, 105, 161))

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

  defp validation_steps do
    wrapped_row([width(fill()), spacing_xy(12, 12)], [
      step_card(
        "1",
        "Render on the GPU",
        "OpenGL or Vulkan renders into exportable linear ABGR8888 storage."
      ),
      step_card(
        "2",
        "Render on the CPU",
        "Skia raster renders directly into an owned RGBA8888 binary."
      ),
      step_card(
        "3",
        "Transport both",
        "Separate Membrane VideoInterop branches retain the latest frame from each producer."
      ),
      step_card(
        "4",
        "Import by target",
        "The main viewport consumes both frame types through atom video targets."
      )
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
