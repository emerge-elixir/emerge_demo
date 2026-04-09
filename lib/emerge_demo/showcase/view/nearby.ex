defmodule EmergeDemo.Showcase.View.Nearby do
  use Emerge.UI

  alias EmergeDemo.Showcase.View
  alias Emerge.UI.Nearby, as: NearbyUI

  # Page composition

  def layout do
    column([width(fill()), spacing(28)], [
      nearby_elements_section(),
      escape_layout_section(),
      sibling_precedence_section(),
      clip_nearby_section()
    ])
  end

  # Page sections

  defp nearby_elements_section do
    column([width(fill()), spacing(16)], [
      section_title("Nearby Elements"),
      section_copy(
        "Nearby.above/1, Nearby.below/1, Nearby.on_left/1, Nearby.on_right/1, and Nearby.in_front/1 all let content escape the normal layout while staying anchored to a host element. For above and below, horizontal alignment comes from the nearby root. For on_left and on_right, vertical alignment comes from the nearby root. in_front can use both axes."
      ),
      nearby_example(
        "Slots and host anchoring",
        "Above and below read align_left, center_x, and align_right on the nearby root. on_left and on_right read align_top, center_y, and align_bottom. in_front can use both axes. behind_content stays between the host background and its content.",
        {:nearby, :slots},
        nearby_slots_code(),
        wrapped_row([width(fill()), spacing_xy(12, 12)], [
          el([width(max(px(340), fill()))], nearby_slot_card()),
          el([width(max(px(340), fill()))], nearby_behind_content_card())
        ])
      )
    ])
  end

  defp escape_layout_section do
    column([width(fill()), spacing(16)], [
      section_title("Escape the Layout"),
      section_copy(
        "Nearby content stays anchored to a host, but it can still escape the normal layout flow. That is what makes dropdowns, popovers, badges, and oversized overlays possible without changing where siblings are laid out."
      ),
      nearby_example(
        "Dropdowns and oversized overlays",
        "The dropdown stays attached to the button while the caption below remains in its normal slot. The oversized in_front overlay escapes the host bounds while staying anchored to it.",
        {:nearby, :escape_layout},
        escape_layout_code(),
        wrapped_row([width(fill()), spacing_xy(12, 12)], [
          el([width(max(px(360), fill()))], nearby_toolbar_escape_card()),
          el([width(max(px(320), fill()))], nearby_overflow_card())
        ])
      )
    ])
  end

  defp sibling_precedence_section do
    column([width(fill()), spacing(16)], [
      section_title("Sibling Precedence"),
      section_copy(
        "Nearby overlays still follow sibling paint order. If two overlays overlap, the later sibling wins where they intersect."
      ),
      nearby_example(
        "Later sibling paints above earlier sibling",
        "The green overlay belongs to the later sibling, so it ends up on top where both nearby overlays overlap.",
        {:nearby, :precedence},
        precedence_code(),
        nearby_sibling_precedence_card()
      )
    ])
  end

  defp clip_nearby_section do
    column([width(fill()), spacing(16)], [
      section_title("clip_nearby"),
      section_copy(
        "Nearby content escapes clipping by default. Add clip_nearby() on a scroll container when you want that container to become a clipping barrier for nearby content inside it."
      ),
      nearby_example(
        "Unclipped vs clipped overlays",
        "The first scroll panel lets the oversized nearby card bleed outside its rounded viewport. The second panel adds clip_nearby() and clips the same overlay back to the scrollport.",
        {:nearby, :clip_nearby},
        clip_nearby_code(),
        wrapped_row([width(fill()), spacing_xy(12, 12)], [
          el([width(max(px(320), fill()))], nearby_clip_card("Unclipped escape", false)),
          el([width(max(px(320), fill()))], nearby_clip_card("clip_nearby()", true))
        ])
      )
    ])
  end

  # Page-specific helpers

  defp nearby_slot_card do
    nearby_demo_card(
      "Host slot anchors nearby roots",
      "The nearby root decides how its own box aligns to the host slot.",
      el(
        [
          width(fill()),
          height(px(170)),
          padding(16),
          Background.color(color_rgb(236, 240, 247)),
          Border.rounded(10)
        ],
        el(
          [
            width(px(140)),
            height(px(64)),
            center_x(),
            center_y(),
            Background.color(color_rgb(76, 92, 136)),
            Border.rounded(10),
            NearbyUI.above(slot_badge("Above", color_rgb(164, 92, 120), [align_right()])),
            NearbyUI.below(slot_badge("Below", color_rgb(74, 132, 102), [center_x()])),
            NearbyUI.on_left(slot_badge("Left", color_rgb(92, 84, 62), [align_bottom()])),
            NearbyUI.on_right(slot_badge("Right", color_rgb(122, 102, 58), [align_bottom()])),
            NearbyUI.in_front(
              slot_badge("Front", color_rgba(0, 0, 0, 170 / 255), [center_x(), center_y()])
            )
          ],
          el([center_x(), center_y(), Font.size(13), Font.color(color(:white))], text("Host"))
        )
      )
    )
  end

  defp nearby_behind_content_card do
    nearby_demo_card(
      "behind_content stays decorative",
      "It paints above the host background but below the host content, which makes it useful for highlights and placeholders.",
      el(
        [
          width(fill()),
          height(px(170)),
          padding(16),
          Background.color(color_rgb(236, 240, 247)),
          Border.rounded(10)
        ],
        el(
          [
            width(px(180)),
            height(px(88)),
            center_x(),
            center_y(),
            Background.color(color_rgb(61, 86, 122)),
            Border.rounded(12),
            NearbyUI.behind_content(
              el(
                [
                  width(px(212)),
                  height(px(120)),
                  center_x(),
                  center_y(),
                  Background.color(color_rgba(92, 156, 255, 48 / 255)),
                  Border.rounded(18)
                ],
                none()
              )
            )
          ],
          column([center_x(), center_y(), spacing(4)], [
            el([Font.size(13), Font.color(color(:white)), Font.bold()], text("Behind content")),
            el(
              [Font.size(10), Font.color(color_rgb(218, 226, 242))],
              text("Highlight stays behind text")
            )
          ])
        )
      )
    )
  end

  defp nearby_toolbar_escape_card do
    nearby_demo_card(
      "Dropdown over later siblings",
      "The caption stays where the column placed it. The menu escapes that flow while staying attached to the button.",
      el(
        [
          width(fill()),
          padding(12),
          Background.color(color_rgb(236, 240, 247)),
          Border.rounded(10)
        ],
        column([width(fill()), spacing(12)], [
          row(
            [
              width(fill()),
              padding(12),
              spacing(12),
              Background.color(color_rgb(248, 250, 253)),
              Border.rounded(10)
            ],
            [
              el(
                [width(fill()), center_y(), Font.size(12), Font.color(color_rgb(79, 96, 120))],
                text("Selected: 3 items")
              ),
              Input.button(
                [
                  padding(12),
                  Background.color(color_rgb(53, 71, 102)),
                  Border.rounded(10),
                  Border.width(1),
                  Border.color(color_rgb(84, 105, 146)),
                  Font.color(color(:white)),
                  Interactive.focused([
                    Border.color(color_rgb(170, 190, 240)),
                    Border.glow(color_rgba(132, 158, 232, 100 / 255), 2)
                  ]),
                  NearbyUI.below(nearby_dropdown_menu())
                ],
                text("Actions")
              )
            ]
          ),
          el(
            [Font.size(12), Font.color(color_rgb(92, 100, 114))],
            text("This help text stays where the column placed it.")
          )
        ])
      )
    )
  end

  defp nearby_dropdown_menu do
    el(
      [
        align_right(),
        padding(8),
        Background.color(color_rgb(255, 255, 255)),
        Border.rounded(10),
        Border.width(1),
        Border.color(color_rgb(214, 221, 236))
      ],
      column([spacing(4)], [
        nearby_dropdown_item("Rename"),
        nearby_dropdown_item("Duplicate"),
        nearby_dropdown_item("Delete")
      ])
    )
  end

  defp nearby_dropdown_item(label) do
    Input.button(
      [
        width(fill()),
        padding(10),
        Background.color(color_rgb(239, 242, 248)),
        Border.rounded(6),
        Border.width(1),
        Border.color(color_rgb(220, 225, 236)),
        Interactive.focused([
          Background.color(color_rgb(232, 237, 246)),
          Border.color(color_rgb(170, 190, 240)),
          Border.glow(color_rgba(132, 158, 232, 100 / 255), 2)
        ]),
        Font.color(color_rgb(63, 75, 98))
      ],
      text(label)
    )
  end

  defp nearby_overflow_card do
    nearby_demo_card(
      "in_front can escape host bounds",
      "The overlay is wider than the host, but it stays centered and bottom-aligned from the host slot.",
      el(
        [
          width(fill()),
          height(px(180)),
          Background.color(color_rgb(236, 240, 247)),
          Border.rounded(10)
        ],
        el(
          [
            width(px(126)),
            height(px(78)),
            center_x(),
            center_y(),
            Background.color(color_rgb(76, 76, 132)),
            Border.width(2),
            Border.color(color_rgb(182, 194, 255)),
            Border.rounded(10),
            NearbyUI.in_front(nearby_oversized_front_overlay())
          ],
          el([center_x(), center_y(), Font.size(13), Font.color(color(:white))], text("Host"))
        )
      )
    )
  end

  defp nearby_oversized_front_overlay do
    el(
      [
        width(px(220)),
        height(px(90)),
        center_x(),
        align_bottom(),
        Background.color(color_rgba(235, 96, 140, 210 / 255)),
        Border.rounded(10),
        Font.size(11),
        Font.color(color(:white))
      ],
      column([center_x(), center_y(), spacing(4)], [
        text("in_front 220x90"),
        el(
          [Font.size(10), Font.color(color_rgba(255, 255, 255, 220 / 255))],
          text("center_x + align_bottom")
        )
      ])
    )
  end

  defp nearby_sibling_precedence_card do
    nearby_demo_card(
      "Later sibling wins",
      "The green overlay belongs to the later sibling, so it wins where both overlays overlap.",
      el(
        [
          width(px(280)),
          center_x(),
          height(px(132)),
          padding(16),
          Background.color(color_rgb(236, 240, 247)),
          Border.rounded(10)
        ],
        row([width(px(208)), center_x(), center_y(), spacing(16)], [
          el(
            [
              width(px(96)),
              height(px(58)),
              Background.color(color_rgb(104, 66, 92)),
              Border.rounded(10),
              NearbyUI.in_front(
                nearby_precedence_overlay("Earlier in_front", color_rgb(220, 92, 120), [
                  align_right(),
                  center_y()
                ])
              )
            ],
            el([center_x(), center_y(), Font.size(12), Font.color(color(:white))], text("Left"))
          ),
          el(
            [
              width(px(96)),
              height(px(58)),
              Background.color(color_rgb(61, 86, 122)),
              Border.rounded(10),
              NearbyUI.on_left(
                nearby_precedence_overlay("Later on_left", color_rgb(74, 186, 132), [center_y()])
              )
            ],
            el([center_x(), center_y(), Font.size(12), Font.color(color(:white))], text("Right"))
          )
        ])
      )
    )
  end

  defp nearby_precedence_overlay(label, bg, extra_attrs) do
    el(
      extra_attrs ++
        [
          width(px(118)),
          padding(8),
          Background.color(bg),
          Border.rounded(8),
          Font.size(11),
          Font.color(color(:white))
        ],
      text(label)
    )
  end

  defp nearby_clip_card(title, clipped?) do
    panel_attrs = [
      width(fill()),
      height(px(196)),
      padding(12),
      scrollbar_y(),
      Background.color(color_rgb(236, 240, 247)),
      Border.rounded(10)
    ]

    panel_attrs = if clipped?, do: [clip_nearby() | panel_attrs], else: panel_attrs

    nearby_demo_card(
      title,
      if(clipped?,
        do: "This scroll container clips the same nearby card back to its rounded viewport.",
        else: "This scroll container lets the oversized nearby card bleed outside the viewport."
      ),
      el(
        panel_attrs,
        column([spacing(10)], [
          nearby_clip_scroll_item(
            "Pinned review",
            "This row mounts an oversized Nearby.above card.",
            true
          ),
          nearby_clip_scroll_item("Payments", "Scrollable list content.", false),
          nearby_clip_scroll_item("Invoices", "Scrollable list content.", false),
          nearby_clip_scroll_item("Notes", "Scrollable list content.", false),
          nearby_clip_scroll_item("Archive", "Scrollable list content.", false)
        ])
      )
    )
  end

  defp nearby_clip_scroll_item(title, subtitle, show_overlay?) do
    attrs = [
      width(fill()),
      padding(12),
      Background.color(color_rgb(76, 76, 132)),
      Border.rounded(10)
    ]

    attrs =
      if show_overlay?, do: [NearbyUI.above(nearby_clip_preview_overlay()) | attrs], else: attrs

    el(
      attrs,
      column([spacing(4)], [
        el([Font.size(12), Font.color(color(:white))], text(title)),
        el([Font.size(10), Font.color(color_rgba(225, 230, 245, 220 / 255))], text(subtitle))
      ])
    )
  end

  defp nearby_clip_preview_overlay do
    el(
      [
        width(px(168)),
        align_right(),
        Transform.move_y(-8),
        padding(10),
        Background.color(color_rgba(235, 96, 140, 210 / 255)),
        Border.rounded(10),
        Font.size(10),
        Font.color(color(:white))
      ],
      column([spacing(4)], [
        text("Nearby.above 168px wide"),
        el(
          [Font.size(10), Font.color(color_rgba(255, 255, 255, 220 / 255))],
          text("Only clip_nearby() keeps it inside the rounded viewport.")
        )
      ])
    )
  end

  # Code previews

  defp nearby_slots_code do
    ~S"""
    el([
      Nearby.above(el([align_right()], text("Above"))),
      Nearby.below(el([center_x()], text("Below"))),
      Nearby.on_left(el([align_bottom()], text("Left"))),
      Nearby.on_right(el([align_bottom()], text("Right"))),
      Nearby.in_front(el([center_x(), center_y()], text("Front")))
    ], text("Host"))
    """
  end

  defp escape_layout_code do
    ~S"""
    Input.button(
      [
        Nearby.below(dropdown_menu())
      ],
      text("Actions")
    )
    """
  end

  defp precedence_code do
    ~S"""
    row([], [
      el([Nearby.in_front(red_overlay())], text("Left")),
      el([Nearby.on_left(green_overlay())], text("Right"))
    ])
    """
  end

  defp clip_nearby_code do
    ~S"""
    el([
      scrollbar_y(),
      clip_nearby()
    ], column([], [
      el([Nearby.above(overlay())], text("Pinned review"))
    ]))
    """
  end

  # Generic elements

  defp nearby_example(title, note, example_id, code, content) do
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

  defp section_title(label) do
    el([Font.size(18), Font.color(title_text())], text(label))
  end

  defp section_copy(content) do
    paragraph([width(fill()), spacing(3), Font.size(13), Font.color(body_text())], [
      text(content)
    ])
  end

  defp nearby_demo_card(title, note, body) do
    column(
      [
        width(fill()),
        spacing(10),
        padding(12),
        Background.color(color_rgb(45, 45, 65)),
        Border.rounded(10)
      ],
      [
        el([Font.size(13), Font.color(color(:white)), Font.bold()], text(title)),
        paragraph(
          [width(fill()), spacing(3), Font.size(11), Font.color(color_rgb(191, 199, 222))],
          [
            text(note)
          ]
        ),
        body
      ]
    )
  end

  defp slot_badge(label, bg, extra_attrs) do
    el(
      extra_attrs ++
        [
          padding(8),
          Background.color(bg),
          Border.rounded(8),
          Font.size(11),
          Font.color(color(:white))
        ],
      text(label)
    )
  end

  # Palette

  defp title_text, do: color_rgb(24, 30, 38)
  defp body_text, do: color_rgb(92, 100, 114)
end
