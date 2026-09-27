defmodule EmergeDemo.Showcase.View.Scroll do
  use Emerge.UI

  alias EmergeDemo.Showcase.View.{CodeBlock, Example}
  require CodeBlock

  # Page composition

  def layout do
    column([width(fill()), spacing(28)], [
      single_axis_section(),
      advanced_scroll_section()
    ])
  end

  # Page sections

  defp single_axis_section do
    column([width(fill()), spacing(16)], [
      Example.heading("First, give the content a boundary"),
      Example.prose(
        "Scrolling needs both overflow and a bounded viewport. Give a long list a fixed height, or a long row a fixed width, then choose the axis."
      ),
      Example.layout(
        "Vertical overflow",
        "Bound the panel height and let a longer list continue below the fold.",
        {:scroll, :vertical},
        vertical_scroll_code(),
        vertical_scroll_example()
      ),
      Example.layout(
        "Horizontal overflow",
        "Keep chips on one line so overflow moves sideways instead of wrapping.",
        {:scroll, :horizontal},
        horizontal_scroll_code(),
        horizontal_scroll_example()
      )
    ])
  end

  defp advanced_scroll_section do
    column([width(fill()), spacing(16)], [
      Example.heading("More content, more than one boundary"),
      Example.prose(
        "A canvas may overflow in both directions. A nested list may need its own scroll position. Try each region separately and notice which one consumes the movement."
      ),
      Example.layout(
        "Both axes",
        "Scroll the oversized canvas horizontally and vertically inside the same bounded frame.",
        {:scroll, :both_axes},
        both_axes_scroll_code(),
        both_axes_scroll_example()
      ),
      Example.layout(
        "Nested vertical scroll",
        "Scroll inside the nested panel first, then keep scrolling the outer section once the inner list reaches its limit.",
        {:scroll, :nested},
        nested_scroll_code(),
        nested_scroll_example()
      )
    ])
  end

  # Page-specific helpers

  defp vertical_scroll_example do
    el(
      [
        width(fill()),
        height(px(180)),
        padding(12),
        scrollbar_y(),
        Background.color(panel_bg()),
        Border.rounded(12)
      ],
      column([spacing(8)], Enum.map(1..12, &scroll_item("Item #{&1}")))
    )
  end

  defp horizontal_scroll_example do
    el(
      [
        width(min(px(360), fill())),
        height(px(92)),
        padding(10),
        scrollbar_x(),
        Background.color(panel_bg()),
        Border.rounded(12)
      ],
      row([spacing(10)], Enum.map(horizontal_chip_labels(), &scroll_chip/1))
    )
  end

  defp both_axes_scroll_example do
    el(
      [
        width(min(px(320), fill())),
        height(px(200)),
        padding(12),
        scrollbar_x(),
        scrollbar_y(),
        Background.color(panel_bg()),
        Border.rounded(12)
      ],
      el(
        [
          width(px(640)),
          height(px(360)),
          padding(18),
          Background.color(canvas_surface()),
          Border.rounded(16),
          Border.width(1),
          Border.color(canvas_border())
        ],
        column([spacing(14)], [
          el([Font.size(18), Font.color(canvas_title_text())], text("Oversized canvas")),
          row([spacing(12)], [
            canvas_block(px(180), px(110), canvas_block_surface()),
            canvas_block(px(220), px(110), canvas_block_outline_surface())
          ]),
          row([spacing(12)], [
            canvas_block(px(280), px(140), canvas_block_surface()),
            canvas_block(px(240), px(140), canvas_block_outline_surface())
          ])
        ])
      )
    )
  end

  defp nested_scroll_example do
    el(
      [
        width(fill()),
        height(px(260)),
        padding(12),
        scrollbar_y(),
        Background.color(panel_bg()),
        Border.rounded(12)
      ],
      column([spacing(12)], [
        nested_outer_item("Outer item 1"),
        nested_outer_item("Outer item 2"),
        el(
          [
            width(fill()),
            height(px(140)),
            padding(10),
            scrollbar_y(),
            Background.color(nested_panel_bg()),
            Border.rounded(12),
            Border.width(1),
            Border.color(nested_panel_border())
          ],
          column([spacing(10)], [
            el(
              [Font.size(12), Font.color(nested_label_text()), Font.bold()],
              text("Nested list")
            ),
            column([spacing(8)], Enum.map(1..8, &nested_inner_item("Nested item #{&1}")))
          ])
        ),
        nested_outer_item("Outer item 3"),
        nested_outer_item("Outer item 4"),
        nested_outer_item("Outer item 5")
      ])
    )
  end

  defp vertical_scroll_code do
    CodeBlock.snippet(~S"""
    el([height(px(180)), scrollbar_y()],
      column([spacing(8)],
        Enum.map(1..12, fn i -> text("Item #{i}") end)
      )
    )
    """)
  end

  defp horizontal_scroll_code do
    CodeBlock.snippet(~S"""
    el([width(min(px(360), fill())), height(px(92)), scrollbar_x()],
      row([spacing(10)],
        Enum.map(["Design", "Docs", "Layout", "Rendering", "Events", "Assets", "More"], fn label ->
          el([padding(12)], text(label))
        end)
      )
    )
    """)
  end

  defp both_axes_scroll_code do
    CodeBlock.snippet(~S"""
    el([width(min(px(320), fill())), height(px(200)), scrollbar_x(), scrollbar_y()],
      el([width(px(640)), height(px(360))],
        text("Oversized canvas")
      )
    )
    """)
  end

  defp nested_scroll_code do
    CodeBlock.snippet(~S"""
    el([height(px(260)), scrollbar_y()],
      column([spacing(12)], [
        text("Outer item 1"),
        text("Outer item 2"),
        el([height(px(140)), scrollbar_y()],
          column([spacing(8)],
            Enum.map(1..10, fn i -> text("Nested item #{i}") end)
          )
        ),
        text("Outer item 3")
      ])
    )
    """)
  end

  # Generic elements

  defp scroll_item(label) do
    el(
      [
        padding_each(10, 12, 10, 12),
        Background.color(scroll_item_bg()),
        Border.rounded(10),
        Font.size(12),
        Font.color(scroll_item_text())
      ],
      text(label)
    )
  end

  defp scroll_chip(label) do
    el(
      [
        padding_each(6, 10, 6, 10),
        Background.color(scroll_chip_bg()),
        Border.rounded(999),
        Border.width(1),
        Border.color(scroll_chip_border()),
        Font.size(12),
        Font.color(scroll_chip_text())
      ],
      text(label)
    )
  end

  defp nested_outer_item(label), do: scroll_item(label)

  defp nested_inner_item(label) do
    el(
      [
        padding_each(8, 10, 8, 10),
        Background.color(nested_item_bg()),
        Border.rounded(10),
        Font.size(12),
        Font.color(nested_item_text())
      ],
      text(label)
    )
  end

  defp canvas_block(width_value, height_value, surface) do
    el(
      [
        width(width_value),
        height(height_value),
        Background.color(surface),
        Border.rounded(12),
        Border.width(1),
        Border.color(canvas_border())
      ],
      none()
    )
  end

  # Palette

  defp horizontal_chip_labels do
    ["Design", "Docs", "Layout", "Animation", "Events", "Rendering", "Testing"]
  end

  defp panel_bg, do: color_rgb(31, 38, 54)
  defp canvas_surface, do: color_rgb(245, 247, 251)
  defp canvas_block_surface, do: color_rgb(226, 231, 240)
  defp canvas_block_outline_surface, do: color_rgb(251, 252, 254)
  defp canvas_border, do: color_rgb(199, 207, 220)
  defp canvas_title_text, do: color_rgb(31, 38, 54)
  defp scroll_item_bg, do: color_rgb(56, 66, 90)
  defp scroll_item_text, do: color_rgb(255, 255, 255)
  defp scroll_chip_bg, do: color_rgb(245, 247, 251)
  defp scroll_chip_border, do: color_rgb(199, 207, 220)
  defp scroll_chip_text, do: color_rgb(31, 38, 54)
  defp nested_panel_bg, do: color_rgb(248, 250, 255)
  defp nested_panel_border, do: color_rgb(194, 206, 235)
  defp nested_label_text, do: color_rgb(72, 96, 168)
  defp nested_item_bg, do: color_rgb(227, 234, 248)
  defp nested_item_text, do: color_rgb(45, 70, 142)
end
