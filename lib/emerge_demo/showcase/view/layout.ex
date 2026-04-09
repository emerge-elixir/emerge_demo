defmodule EmergeDemo.Showcase.View.Layout do
  use Emerge.UI

  alias EmergeDemo.Showcase.View

  # Page composition

  def layout do
    column([width(fill()), spacing(28)], [
      sizing_section(),
      spacing_section(),
      alignment_section(),
      transforms_section()
    ])
  end

  # Page sections

  defp sizing_section do
    column([width(fill()), spacing(16)], [
      section_title("Layout + Sizing"),
      section_copy("Fill, shrink, weighted fill, and min/max constraints."),
      View.hover_example({:layout, :shrink_fill}, shrink_fill_code(), shrink_fill_example()),
      View.hover_example(
        {:layout, :weighted_fill},
        weighted_fill_code(),
        weighted_fill_example()
      ),
      View.hover_example({:layout, :min_max}, min_max_code(), min_max_example())
    ])
  end

  defp spacing_section do
    column([width(fill()), spacing(16)], [
      section_title("Spacing + Wrapping"),
      section_copy(
        "Use space distribution and wrapped rows to keep layouts readable as the viewport changes."
      ),
      View.hover_example({:layout, :space_evenly}, space_evenly_code(), space_evenly_example()),
      View.hover_example({:layout, :wrapped_row}, wrapped_row_code(), wrapped_row_example())
    ])
  end

  defp alignment_section do
    column([width(fill()), spacing(16)], [
      section_title("Alignment"),
      section_copy(
        "Resize the window to observe how horizontal and vertical alignment respond inside flexible rows and fixed frames."
      ),
      alignment_tokens_demo(),
      fixed_alignment_demo(),
      nested_alignment_demo(),
      centered_content_demo()
    ])
  end

  defp transforms_section do
    column([width(fill()), spacing(16)], [
      section_title("Transforms"),
      section_copy(
        "Transforms change paint, not layout. The slot stays put even when the element moves, rotates, scales, or fades."
      ),
      View.hover_example(
        {:layout, :transform_slot},
        transform_slot_code(),
        transform_slot_demo()
      ),
      View.hover_example(
        {:layout, :transform_cards},
        transform_cards_code(),
        transform_cards_demo()
      )
    ])
  end

  # Page-specific helpers

  defp sizing_card(size_attrs, title, detail, tone) do
    el(
      size_attrs ++ [padding(10), Background.color(tone.surface), Border.rounded(8)],
      column([spacing(4)], [
        el([Font.size(13), Font.color(tone.title)], text(title)),
        el([Font.size(11), Font.color(tone.detail)], text(detail))
      ])
    )
  end

  defp fill_weight_card(weight, tone) do
    el(
      [width(fill(weight)), padding(8), Background.color(tone.surface), Border.rounded(8)],
      el([Font.size(13), Font.color(tone.title)], text("Fill #{weight}"))
    )
  end

  defp shrink_fill_example do
    row([width(fill()), spacing(12)], [
      sizing_card([width(shrink())], "Shrink", "Content sized", tone_blue()),
      sizing_card([width(fill())], "Fill", "Expands to the remaining space", tone_slate())
    ])
  end

  defp weighted_fill_example do
    row([width(fill()), spacing(8)], [
      fill_weight_card(1, tone_indigo()),
      fill_weight_card(2, tone_ocean()),
      fill_weight_card(3, tone_teal())
    ])
  end

  defp min_max_example do
    row([width(fill()), spacing(12)], [
      sizing_card(
        [width(min(px(140), shrink()))],
        "Min + shrink",
        "At least 140px",
        tone_purple()
      ),
      sizing_card([width(max(px(180), fill()))], "Max + fill", "At most 180px", tone_rose())
    ])
  end

  defp space_evenly_example do
    row([width(fill()), space_evenly()], [
      chip("Space"),
      chip("Between"),
      chip("Items")
    ])
  end

  defp wrapped_row_example do
    wrapped_row(
      [width(fill()), spacing_xy(16, 18)],
      Enum.map(
        [
          "Spacing",
          "X/Y",
          "Wrapped",
          "Row",
          "Example",
          "Resize",
          "The",
          "Window",
          "To",
          "Observe",
          "How",
          "It",
          "Reflows"
        ],
        &chip/1
      )
    )
  end

  defp alignment_tokens_demo do
    alignment_example(
      "Horizontal alignment inside a row",
      {:layout, :alignment_tokens},
      alignment_tokens_code(),
      row([width(fill()), spacing(10)], [
        alignment_token([], "Left"),
        alignment_token([align_left()], "Left 2"),
        alignment_token([center_x()], "Center"),
        alignment_token([align_right()], "Right")
      ])
    )
  end

  defp fixed_alignment_demo do
    alignment_example(
      "Fixed-width containers",
      {:layout, :fixed_alignment},
      fixed_alignment_code(),
      wrapped_row([width(fill()), spacing_xy(12, 12)], [
        fixed_alignment_box([center_x()], "Centered text"),
        fixed_alignment_box([align_right()], "Right-aligned")
      ])
    )
  end

  defp nested_alignment_demo do
    alignment_example(
      "Nested alignment",
      {:layout, :nested_alignment},
      nested_alignment_code(),
      row([width(fill())], [
        el(
          [
            width(px(200)),
            center_x(),
            padding(10),
            Background.color(alignment_surface()),
            Border.rounded(4)
          ],
          el(
            [width(fill()), align_right(), Font.size(12), Font.color(alignment_text())],
            text("Centered box, right text")
          )
        )
      ])
    )
  end

  defp centered_content_demo do
    alignment_example(
      "Centered in both axes",
      {:layout, :centered_content},
      centered_content_code(),
      el(
        [
          width(fill()),
          height(px(80)),
          padding(10),
          Background.color(centered_panel_bg()),
          Border.rounded(6)
        ],
        el(
          [
            width(fill()),
            height(fill()),
            center_x(),
            center_y(),
            Font.size(16),
            Font.color(centered_panel_text())
          ],
          text("Centered content")
        )
      )
    )
  end

  defp transform_slot_demo do
    el(
      [
        width(fill()),
        height(px(180)),
        padding(20),
        Background.color(color_rgb(31, 38, 54)),
        Border.rounded(14)
      ],
      el(
        [
          width(px(128)),
          height(px(76)),
          center_x(),
          center_y(),
          Background.color(color_rgba(248, 250, 252, 0.72)),
          Border.rounded(12),
          Border.width(1),
          Border.color(color_rgb(199, 207, 220)),
          Border.dashed(),
          Font.color(color_rgb(107, 114, 128)),
          Nearby.in_front(
            el(
              [
                width(fill()),
                height(fill()),
                padding(12),
                Transform.move_x(36),
                Transform.move_y(-8),
                Transform.rotate(-10),
                Background.color(color_rgb(245, 247, 251)),
                Border.rounded(12),
                Border.width(1),
                Border.color(color_rgb(199, 207, 220)),
                Font.color(color_rgb(31, 38, 54))
              ],
              column([width(fill()), center_y(), spacing(4)], [
                el(
                  [width(fill()), Font.size(14), Font.bold(), Font.align_left()],
                  text("Painted card")
                ),
                paragraph(
                  [
                    width(fill()),
                    Font.size(11),
                    Font.align_left(),
                    Font.color(color_rgb(92, 100, 114))
                  ],
                  [text("Paint only, layout stays put")]
                )
              ])
            )
          )
        ],
        el([center_x(), center_y(), Font.size(11)], text("Original slot"))
      )
    )
  end

  defp transform_cards_demo do
    wrapped_row([width(fill()), padding_each(6, 0, 14, 0), spacing_xy(12, 12)], [
      transform_card("Rotate", "-8deg", [Transform.rotate(-8)], tone_blue()),
      transform_card("Scale", "1.08x", [Transform.scale(1.08)], tone_purple()),
      transform_card("Alpha", "60%", [Transform.alpha(0.6)], tone_rose())
    ])
  end

  defp transform_card(title, detail, transform_attrs, tone) do
    el(
      [width(px(170))] ++
        transform_attrs ++ [padding(14), Background.color(tone.surface), Border.rounded(10)],
      column([center_x(), center_y(), spacing(4)], [
        el([Font.size(14), Font.color(tone.title), Font.bold()], text(title)),
        el([Font.size(11), Font.color(tone.detail)], text(detail))
      ])
    )
  end

  defp shrink_fill_code do
    ~S"""
    row([width(fill()), spacing(12)], [
      el([width(shrink()), padding(10)], text("Shrink")),
      el([width(fill()), padding(10)], text("Fill"))
    ])
    """
  end

  defp weighted_fill_code do
    ~S"""
    row([width(fill()), spacing(8)], [
      el([width(fill(1)), padding(8)], text("Fill 1")),
      el([width(fill(2)), padding(8)], text("Fill 2")),
      el([width(fill(3)), padding(8)], text("Fill 3"))
    ])
    """
  end

  defp min_max_code do
    ~S"""
    row([width(fill()), spacing(12)], [
      el([width(min(px(140), shrink()))], text("Min + shrink")),
      el([width(max(px(180), fill()))], text("Max + fill"))
    ])
    """
  end

  defp space_evenly_code do
    ~S"""
    row([width(fill()), space_evenly()], [
      chip("Space"),
      chip("Between"),
      chip("Items")
    ])
    """
  end

  defp wrapped_row_code do
    ~S"""
    wrapped_row([width(fill()), spacing_xy(16, 18)], [
      chip("Spacing"),
      chip("X/Y"),
      chip("Wrapped"),
      chip("Row"),
      chip("Reflows")
    ])
    """
  end

  defp alignment_tokens_code do
    ~S"""
    row([width(fill()), spacing(10)], [
      el([], text("Left")),
      el([align_left()], text("Left 2")),
      el([center_x()], text("Center")),
      el([align_right()], text("Right"))
    ])
    """
  end

  defp fixed_alignment_code do
    ~S"""
    wrapped_row([width(fill()), spacing_xy(12, 12)], [
      el([width(px(180)), center_x()], text("Centered text")),
      el([width(px(180)), align_right()], text("Right-aligned"))
    ])
    """
  end

  defp nested_alignment_code do
    ~S"""
    row([width(fill())], [
      el([width(px(200)), center_x()],
        el([width(fill()), align_right()], text("Centered box, right text"))
      )
    ])
    """
  end

  defp centered_content_code do
    ~S"""
    el([width(fill()), height(px(80))],
      el([width(fill()), height(fill()), center_x(), center_y()],
        text("Centered content")
      )
    )
    """
  end

  defp transform_slot_code do
    ~S"""
    el([width(px(128)), height(px(76)), Nearby.in_front(
      el([
        width(fill()),
        height(fill()),
        padding(12),
        Transform.move_x(36),
        Transform.move_y(-8),
        Transform.rotate(-10)
      ], column([width(fill()), center_y(), spacing(4)], [
        el([width(fill()), Font.align_left()], text("Painted card")),
        paragraph([width(fill()), Font.size(11), Font.align_left()], [
          text("Paint only, layout stays put")
        ])
      ]))
    )], text("Original slot"))
    """
  end

  defp transform_cards_code do
    ~S"""
    wrapped_row([width(fill()), padding_each(6, 0, 14, 0), spacing_xy(12, 12)], [
      el([width(px(170)), Transform.rotate(-8)], text("Rotate")),
      el([width(px(170)), Transform.scale(1.08)], text("Scale")),
      el([width(px(170)), Transform.alpha(0.6)], text("Alpha"))
    ])
    """
  end

  # Generic elements

  defp section_title(label) do
    el([Font.size(18), Font.color(title_text())], text(label))
  end

  defp section_copy(content) do
    paragraph([width(fill()), spacing(3), Font.size(13), Font.color(body_text())], [
      text(content)
    ])
  end

  defp chip(label) do
    el(
      [
        padding(6),
        Background.color(chip_bg()),
        Border.rounded(12),
        Font.size(11),
        Font.color(chip_text())
      ],
      text(label)
    )
  end

  defp alignment_example(title, example_id, code, content) do
    View.hover_example(
      example_id,
      code,
      column([width(fill()), spacing(10)], [
        el([Font.size(12), Font.color(body_text()), Font.bold()], text(title)),
        content
      ])
    )
  end

  defp alignment_token(alignment_attrs, label) do
    el(
      alignment_attrs ++
        [
          padding(10),
          Background.color(alignment_surface()),
          Border.rounded(4),
          Font.size(12),
          Font.color(alignment_text())
        ],
      text(label)
    )
  end

  defp fixed_alignment_box(alignment_attrs, label) do
    el(
      [width(px(180))] ++
        alignment_attrs ++
        [
          padding(10),
          Background.color(alignment_surface()),
          Border.rounded(4),
          Font.size(12),
          Font.color(alignment_text())
        ],
      text(label)
    )
  end

  # Palette

  defp tone_blue do
    %{surface: color_rgb(55, 70, 90), title: color(:white), detail: color_rgb(210, 220, 230)}
  end

  defp tone_slate do
    %{surface: color_rgb(70, 80, 95), title: color(:white), detail: color_rgb(220, 225, 235)}
  end

  defp tone_indigo do
    %{surface: color_rgb(65, 70, 100), title: color(:white), detail: color_rgb(220, 225, 235)}
  end

  defp tone_ocean do
    %{surface: color_rgb(65, 80, 110), title: color(:white), detail: color_rgb(220, 230, 238)}
  end

  defp tone_teal do
    %{surface: color_rgb(65, 90, 120), title: color(:white), detail: color_rgb(220, 233, 240)}
  end

  defp tone_purple do
    %{surface: color_rgb(70, 65, 95), title: color(:white), detail: color_rgb(220, 220, 235)}
  end

  defp tone_rose do
    %{surface: color_rgb(85, 65, 95), title: color(:white), detail: color_rgb(225, 215, 235)}
  end

  defp title_text, do: color_rgb(24, 30, 38)
  defp body_text, do: color_rgb(92, 100, 114)
  defp chip_bg, do: color_rgb(55, 60, 90)
  defp chip_text, do: color_rgb(255, 255, 255)
  defp alignment_surface, do: color_rgb(55, 55, 80)
  defp alignment_text, do: color_rgb(255, 255, 255)
  defp centered_panel_bg, do: color_rgb(45, 45, 65)
  defp centered_panel_text, do: color_rgb(0, 255, 255)
end
