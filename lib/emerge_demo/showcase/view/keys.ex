defmodule EmergeDemo.Showcase.View.Keys do
  use Emerge.UI
  use Solve.Lookup, :helpers

  alias EmergeDemo.Showcase
  alias EmergeDemo.Showcase.View

  # Page composition

  def layout do
    keys = solve(Showcase.App, :keys)

    column([width(fill()), spacing(28)], [
      scroll_identity_section(keys),
      focused_input_section(keys)
    ])
  end

  # Page sections

  defp scroll_identity_section(keys) do
    column([width(fill()), spacing(16)], [
      section_title("Keyed scroll state"),
      section_copy(
        "Reorder sibling cards without changing their inner lists. Keys belong on the reordered card roots here, so the nested scrollbar state can stay attached to each label."
      ),
      keys_example(
        "Rotate outer cards",
        "Scroll Bravo or Delta to a distinct position, then rotate the cards. Without keys, the inner scrollbar state stays with the reused slot. With keys, it stays with the same labeled card.",
        {:keys, :scroll_state},
        scroll_state_code(),
        column([width(fill()), spacing(12)], [
          wrapped_row([width(fill()), spacing_xy(12, 8)], [
            action_button("Rotate cards", event(keys, :rotate_scroll_items)),
            el(
              [align_bottom(), Font.size(11), Font.color(body_text())],
              text("Only the outer cards reorder. Child counts stay attached to each card.")
            )
          ]),
          comparison_grid([
            comparison_panel(
              "Without keys",
              "Scroll state follows the reused slot.",
              scroll_list(keys.scroll_items, false)
            ),
            comparison_panel(
              "With keys",
              "Scroll state follows the keyed card.",
              scroll_list(keys.scroll_items, true)
            )
          ])
        ])
      )
    ])
  end

  defp focused_input_section(keys) do
    column([width(fill()), spacing(16)], [
      section_title("Focused input state"),
      section_copy(
        "Focused text inputs keep Rust-owned caret and selection state across rebuilds. Insert a new row above the focused field to compare focus following the reused slot versus the keyed row."
      ),
      keys_example(
        "Prepend above the focused field",
        "Click into Bravo or Charlie, place the caret in the middle or type a few letters, then press Ctrl+N while the field stays focused. Without keys, the live edit state jumps to whichever row reuses that slot. With keys, it stays with the same labeled row.",
        {:keys, :focused_input},
        focused_input_code(),
        column([width(fill()), spacing(12)], [
          shortcut_strip(),
          comparison_grid([
            comparison_panel(
              "Without keys",
              "Focus follows the reused slot.",
              input_list(keys, false)
            ),
            comparison_panel(
              "With keys",
              "Focus follows the keyed row.",
              input_list(keys, true)
            )
          ]),
          paragraph([width(fill()), spacing(3), Font.size(11), Font.color(body_text())], [
            text(
              "Keep the field focused while testing. This example is about focused runtime edit state across rebuilds, not persisting every keystroke into Solve state."
            )
          ])
        ])
      )
    ])
  end

  # Page-specific helpers

  defp scroll_list(items, keyed?) do
    column([width(fill()), spacing(12)], Enum.map(items, &scroll_card(&1, keyed?)))
  end

  defp scroll_card(item, keyed?) do
    row_key = if keyed?, do: [key({:keys, :scroll, item.id})], else: []

    column(
      [
        width(fill()),
        padding(12),
        spacing(10),
        Background.color(card_bg()),
        Border.rounded(12),
        Border.width(1),
        Border.color(card_border())
      ] ++ row_key,
      [
        row([width(fill()), spacing(10)], [
          el([Font.size(13), Font.color(title_text()), Font.bold()], text(item.label)),
          el(
            [align_right(), Font.size(11), Font.color(body_text())],
            text("#{length(item.children)} items")
          )
        ]),
        el(
          [
            width(fill()),
            height(px(108)),
            padding(8),
            scrollbar_y(),
            Background.color(scroll_surface()),
            Border.rounded(10)
          ],
          column([spacing(8)], Enum.map(item.children, &scroll_child/1))
        )
      ]
    )
  end

  defp scroll_child(label) do
    el(
      [
        padding_each(7, 9, 7, 9),
        Background.color(scroll_chip_bg()),
        Border.rounded(999),
        Font.size(11),
        Font.color(scroll_chip_text())
      ],
      text(label)
    )
  end

  defp input_list(keys, keyed?) do
    column([width(fill()), spacing(12)], Enum.map(keys.input_rows, &input_row(&1, keyed?, keys)))
  end

  defp input_row(row, keyed?, keys) do
    row_key = if keyed?, do: [key({:keys, :input, row.id})], else: []

    column(
      [
        width(fill()),
        padding(12),
        spacing(8),
        Background.color(card_bg()),
        Border.rounded(12),
        Border.width(1),
        Border.color(card_border())
      ] ++ row_key,
      [
        row([width(fill()), spacing(10)], [
          el([Font.size(12), Font.color(title_text()), Font.bold()], text(row.label)),
          el([align_right(), Font.size(11), Font.color(body_text())], text("Ctrl+N"))
        ]),
        Input.text(
          [
            width(fill()),
            padding_xy(10, 8),
            Font.size(14),
            Font.color(input_text()),
            Background.color(input_bg()),
            Border.rounded(8),
            Border.width(1),
            Border.color(input_border()),
            Interactive.focused([
              Background.color(input_focus_bg()),
              Border.color(input_focus_border())
            ]),
            Event.on_key_down(
              [key: :n, mods: [:ctrl], match: :all],
              event(keys, :prepend_input_row)
            )
          ],
          row.value
        )
      ]
    )
  end

  defp scroll_state_code do
    ~S"""
    Input.button([Event.on_press(event(keys, :rotate_scroll_items))], text("Rotate cards"))

    Enum.map(items, fn item ->
      column([
        if keyed?, do: key({:keys, :scroll, item.id})
      ], [
        text(item.label),
        el([height(px(108)), scrollbar_y()],
          column([], Enum.map(item.children, &text/1))
        )
      ])
    end)
    """
  end

  defp focused_input_code do
    ~S"""
    Enum.map(rows, fn row ->
      column([
        if keyed?, do: key({:keys, :input, row.id})
      ], [
        text(row.label),
        Input.text(
          [
            Event.on_key_down([key: :n, mods: [:ctrl], match: :all], event(keys, :prepend_input_row))
          ],
          row.value
        )
      ])
    end)
    """
  end

  # Generic elements

  defp keys_example(title, note, example_id, code, content) do
    View.hover_example(
      example_id,
      code,
      column([width(fill()), spacing(10)], [
        el([Font.size(12), Font.color(body_text()), Font.bold()], text(title)),
        paragraph([width(fill()), spacing(3), Font.size(12), Font.color(body_text())], [
          text(note)
        ]),
        content
      ])
    )
  end

  defp comparison_grid(panels) do
    wrapped_row([width(fill()), spacing_xy(16, 16)], panels)
  end

  defp comparison_panel(title, note, content) do
    column(
      [
        width(max(px(320), fill())),
        spacing(10),
        padding(14),
        Background.color(panel_bg()),
        Border.rounded(14),
        Border.width(1),
        Border.color(panel_border())
      ],
      [
        el([Font.size(13), Font.color(title_text()), Font.bold()], text(title)),
        paragraph([width(fill()), spacing(3), Font.size(11), Font.color(body_text())], [
          text(note)
        ]),
        content
      ]
    )
  end

  defp action_button(label, on_press) do
    Input.button(
      [
        Event.on_press(on_press),
        padding_each(8, 12, 8, 12),
        Background.color(button_bg()),
        Border.rounded(999),
        Border.width(1),
        Border.color(button_border()),
        Font.size(12),
        Font.color(button_text()),
        Interactive.mouse_over([
          Background.color(button_hover_bg()),
          Border.color(button_hover_border())
        ]),
        Interactive.focused([
          Border.color(button_focus_border()),
          Border.glow(button_focus_glow(), 2)
        ]),
        Interactive.mouse_down([Transform.move_y(1)])
      ],
      text(label)
    )
  end

  defp shortcut_strip do
    wrapped_row([width(fill()), spacing_xy(10, 10)], [
      shortcut_chip("Ctrl+N", "Prepend a row above the focused field."),
      shortcut_chip("Focus ring", "Watch which labeled row keeps the active input.")
    ])
  end

  defp shortcut_chip(title, detail) do
    column(
      [
        width(max(px(220), fill())),
        spacing(4),
        padding(12),
        Background.color(shortcut_bg()),
        Border.rounded(12),
        Border.width(1),
        Border.color(shortcut_border())
      ],
      [
        el([Font.size(12), Font.color(title_text()), Font.bold()], text(title)),
        paragraph([width(fill()), spacing(3), Font.size(11), Font.color(body_text())], [
          text(detail)
        ])
      ]
    )
  end

  defp section_title(label) do
    el([Font.size(18), Font.color(title_text())], text(label))
  end

  defp section_copy(content) do
    paragraph([width(fill()), spacing(3), Font.size(13), Font.color(body_text())], [
      text(content)
    ])
  end

  # Palette

  defp panel_bg, do: color_rgb(249, 250, 252)
  defp panel_border, do: color_rgb(223, 227, 236)
  defp card_bg, do: color_rgb(255, 255, 255)
  defp card_border, do: color_rgb(221, 226, 236)
  defp scroll_surface, do: color_rgb(244, 246, 250)
  defp scroll_chip_bg, do: color_rgb(232, 236, 245)
  defp scroll_chip_text, do: color_rgb(66, 78, 98)
  defp shortcut_bg, do: color_rgb(241, 245, 255)
  defp shortcut_border, do: color_rgb(205, 216, 242)
  defp button_bg, do: color_rgb(238, 243, 255)
  defp button_hover_bg, do: color_rgb(230, 237, 254)
  defp button_border, do: color_rgb(178, 192, 231)
  defp button_hover_border, do: color_rgb(154, 171, 220)
  defp button_focus_border, do: color_rgb(142, 160, 214)
  defp button_focus_glow, do: color_rgba(116, 138, 210, 0.26)
  defp button_text, do: color_rgb(45, 70, 142)
  defp input_bg, do: color_rgb(249, 250, 253)
  defp input_focus_bg, do: color_rgb(255, 251, 239)
  defp input_text, do: color_rgb(38, 46, 58)
  defp input_border, do: color_rgb(193, 201, 218)
  defp input_focus_border, do: color_rgb(222, 176, 92)
  defp title_text, do: color_rgb(28, 36, 48)
  defp body_text, do: color_rgb(92, 100, 114)
end
