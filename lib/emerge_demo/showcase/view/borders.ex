defmodule EmergeDemo.Showcase.View.Borders do
  use Emerge.UI

  alias EmergeDemo.Showcase.View

  # Page composition

  def layout do
    column([width(fill()), spacing(28)], [
      border_styles_section(),
      pill_radius_section(),
      per_edge_section(),
      box_shadow_section(),
      glow_section(),
      inner_shadow_section(),
      combined_section()
    ])
  end

  # Page sections

  defp border_styles_section do
    column([width(fill()), spacing(16)], [
      section_title("Border Styles"),
      section_copy(
        "Border width participates in layout. Style, width, and radius then decide how that occupied edge is painted."
      ),
      border_example(
        "Solid, dashed, and dotted borders",
        "Compare style, width, and radius permutations without the full old matrix.",
        {:borders, :styles},
        border_styles_code(),
        border_recipe_grid(border_style_cards())
      )
    ])
  end

  defp pill_radius_section do
    column([width(fill()), spacing(16)], [
      section_title("Pill Radius Clamp"),
      section_copy(
        "rounded(999) clamps to the element height, so circles and wide pills keep fills, borders, and clipping aligned."
      ),
      border_example(
        "Large radius behaves like a true pill",
        "The same rounded(999) attr forms a circle on square badges and pills on wider labels.",
        {:borders, :pill_radius},
        pill_radius_code(),
        pill_radius_showcase()
      )
    ])
  end

  defp per_edge_section do
    column([width(fill()), spacing(16)], [
      section_title("Per-Edge Border Width"),
      section_copy(
        "width_each/4 lets each edge contribute its own layout inset and painted stroke, so asymmetric borders can stay explicit."
      ),
      border_example(
        "Asymmetric and single-side widths",
        "Keep just a few recipes to show the concept instead of every style permutation.",
        {:borders, :per_edge},
        per_edge_code(),
        border_recipe_grid(per_edge_cards())
      )
    ])
  end

  defp box_shadow_section do
    column([width(fill()), spacing(16)], [
      section_title("Box Shadow"),
      section_copy(
        "Outer shadows are decorative only. Offset, blur, spread, and multiple layers change paint, not layout, so parent and child shadows can bleed and stack in the same composition."
      ),
      border_example(
        "Directional, diffuse, and stacked shadows",
        "A smaller set still shows offset, spread, and multi-layer depth.",
        {:borders, :shadow},
        box_shadow_code(),
        column([width(fill()), spacing(12)], [
          box_shadow_showcase(),
          border_recipe_grid(box_shadow_cards())
        ])
      )
    ])
  end

  defp glow_section do
    column([width(fill()), spacing(16)], [
      section_title("Glow"),
      section_copy(
        "glow/2 is just a zero-offset outer shadow, so color and intensity are the key variables."
      ),
      border_example(
        "Glow color and intensity",
        "Trimmed to three cards so the different rim strengths are still easy to compare.",
        {:borders, :glow},
        glow_code(),
        border_recipe_grid(glow_cards())
      )
    ])
  end

  defp inner_shadow_section do
    column([width(fill()), spacing(16)], [
      section_title("Inner Shadow"),
      section_copy(
        "Inner shadows stay inside the element, so they are useful for pressed, recessed, and tinted contour effects."
      ),
      border_example(
        "Centered, directional, and tinted inset shadows",
        "Keep one neutral depth, one directional press, and one colored contour.",
        {:borders, :inner_shadow},
        inner_shadow_code(),
        border_recipe_grid(inner_shadow_cards())
      )
    ])
  end

  defp combined_section do
    column([width(fill()), spacing(16)], [
      section_title("Combined"),
      section_copy(
        "Multiple border attrs can be layered into more expressive recipes that still stay within the same border and shadow model."
      ),
      border_example(
        "Composed border recipes",
        "A smaller recipe set still shows how borders, glow, shadow, and inset effects combine.",
        {:borders, :combined},
        combined_code(),
        column([width(fill()), spacing(12)], [
          combined_showcase(),
          border_recipe_grid(combined_cards())
        ])
      )
    ])
  end

  # Page-specific helpers

  defp border_style_cards do
    [
      border_recipe_card(
        "Solid thin round",
        "1px stroke + small radius",
        "Solid",
        [
          Border.rounded(6),
          Border.width(1),
          Border.color(color_rgb(102, 160, 255)),
          Border.solid()
        ],
        ["Border.rounded(6)", "Border.width(1)", "Border.color(:blue)", "Border.solid()"]
      ),
      border_recipe_card(
        "Solid thick square",
        "5px stroke + square corners",
        "Square",
        [
          Border.rounded(0),
          Border.width(5),
          Border.color(color_rgb(58, 190, 171)),
          Border.solid()
        ],
        ["Border.rounded(0)", "Border.width(5)", "Border.color(:teal)", "Border.solid()"]
      ),
      border_recipe_card(
        "Dashed medium round",
        "2px dashes + 8px radius",
        "Dashed",
        [
          Border.rounded(8),
          Border.width(2),
          Border.color(color_rgb(255, 172, 76)),
          Border.dashed()
        ],
        [
          "Border.rounded(8)",
          "Border.width(2)",
          "Border.color(:orange)",
          "Border.dashed()"
        ]
      ),
      border_recipe_card(
        "Dotted thick square",
        "4px dots + no radius",
        "Dotted",
        [
          Border.rounded(0),
          Border.width(4),
          Border.color(color_rgb(255, 110, 192)),
          Border.dotted()
        ],
        ["Border.rounded(0)", "Border.width(4)", "Border.color(:pink)", "Border.dotted()"]
      )
    ]
  end

  defp per_edge_cards do
    [
      border_recipe_card(
        "Thick top + bottom",
        "width_each(4, 1, 4, 1)",
        "Asymmetric",
        [
          Border.rounded(8),
          Border.width_each(4, 1, 4, 1),
          Border.color(color_rgb(58, 190, 171)),
          Border.solid()
        ],
        [
          "Border.rounded(8)",
          "Border.width_each(4, 1, 4, 1)",
          "Border.color(:teal)",
          "Border.solid()"
        ]
      ),
      border_recipe_card(
        "Top only",
        "single-side width_each variant",
        "Top",
        [
          Border.rounded(8),
          Border.width_each(3, 0, 0, 0),
          Border.color(color_rgb(255, 172, 76)),
          Border.dashed()
        ],
        [
          "Border.rounded(8)",
          "Border.width_each(3, 0, 0, 0)",
          "Border.color(:orange)",
          "Border.dashed()"
        ]
      ),
      border_recipe_card(
        "Left only",
        "single-side width_each variant",
        "Left",
        [
          Border.rounded(8),
          Border.width_each(0, 0, 0, 3),
          Border.color(color_rgb(220, 112, 255)),
          Border.dotted()
        ],
        [
          "Border.rounded(8)",
          "Border.width_each(0, 0, 0, 3)",
          "Border.color(:magenta)",
          "Border.dotted()"
        ]
      )
    ]
  end

  defp box_shadow_cards do
    [
      border_recipe_card(
        "Drop shadow down-right",
        "Classic card shadow",
        "Shadow",
        [
          Background.color(color_rgb(246, 249, 255)),
          Border.rounded(8),
          Border.shadow(offset: {4, 4}, blur: 12, color: color_rgba(15, 23, 42, 0.75))
        ],
        ["Border.rounded(8)", "Border.shadow(offset: {4, 4}, blur: 12, color: :black)"],
        sample_bg: color_rgb(226, 231, 239),
        sample_text_color: color_rgb(33, 43, 60)
      ),
      border_recipe_card(
        "Diffuse spread",
        "Large blur + spread size",
        "Diffuse",
        [
          Background.color(color_rgb(244, 248, 255)),
          Border.rounded(8),
          Border.shadow(offset: {0, 0}, blur: 20, size: 2, color: color_rgba(73, 115, 255, 0.7))
        ],
        ["Border.rounded(8)", "Border.shadow(offset: {0, 0}, blur: 20, size: 2, color: :blue)"],
        sample_bg: color_rgb(226, 231, 239),
        sample_text_color: color_rgb(33, 43, 60)
      ),
      border_recipe_card(
        "Stacked shadows",
        "Two shadow layers on one element",
        "Stacked",
        [
          Background.color(color_rgb(246, 248, 255)),
          Border.rounded(8),
          Border.shadow(offset: {2, 2}, blur: 6, color: color_rgba(0, 0, 0, 0.55)),
          Border.shadow(offset: {-2, -2}, blur: 8, color: color_rgba(56, 189, 248, 0.7))
        ],
        [
          "Border.rounded(8)",
          "Border.shadow(offset: {2, 2}, blur: 6, color: :black)",
          "Border.shadow(offset: {-2, -2}, blur: 8, color: :cyan)"
        ],
        sample_bg: color_rgb(226, 231, 239),
        sample_text_color: color_rgb(33, 43, 60)
      )
    ]
  end

  defp glow_cards do
    [
      border_recipe_card(
        "Cyan soft",
        "Low intensity glow",
        "Glow",
        [
          Background.color(color_rgb(36, 45, 64)),
          Border.rounded(8),
          Border.glow(color_rgba(56, 189, 248, 0.65), 2)
        ],
        ["Border.rounded(8)", "Border.glow(:cyan, 2)"],
        sample_bg: color_rgb(22, 28, 38)
      ),
      border_recipe_card(
        "Blue medium",
        "Cool-toned glow",
        "Blue",
        [
          Background.color(color_rgb(32, 42, 68)),
          Border.rounded(8),
          Border.glow(color_rgba(92, 156, 255, 0.8), 5)
        ],
        ["Border.rounded(8)", "Border.glow(:blue, 5)"],
        sample_bg: color_rgb(22, 28, 38)
      ),
      border_recipe_card(
        "Pink strong",
        "High intensity glow",
        "Pink",
        [
          Background.color(color_rgb(52, 34, 54)),
          Border.rounded(8),
          Border.glow(color_rgba(255, 110, 192, 0.9), 7)
        ],
        ["Border.rounded(8)", "Border.glow(:pink, 7)"],
        sample_bg: color_rgb(22, 28, 38)
      )
    ]
  end

  defp inner_shadow_cards do
    [
      border_recipe_card(
        "Inset neutral",
        "Centered inner depth",
        "Inset",
        [
          Background.color(color_rgb(244, 246, 252)),
          Border.rounded(8),
          Border.inner_shadow(blur: 10, color: color_rgba(0, 0, 0, 0.65))
        ],
        ["Border.rounded(8)", "Border.inner_shadow(blur: 10, color: :black)"],
        sample_bg: color_rgb(235, 239, 247),
        sample_text_color: color_rgb(33, 43, 60)
      ),
      border_recipe_card(
        "Inset down-right",
        "Directional pressed effect",
        "Pressed",
        [
          Background.color(color_rgb(240, 244, 252)),
          Border.rounded(8),
          Border.inner_shadow(offset: {3, 3}, blur: 8, color: color_rgba(111, 77, 189, 0.7))
        ],
        ["Border.rounded(8)", "Border.inner_shadow(offset: {3, 3}, blur: 8, color: :purple)"],
        sample_bg: color_rgb(236, 240, 247),
        sample_text_color: color_rgb(33, 43, 60)
      ),
      border_recipe_card(
        "Inset cyan tint",
        "Colored inner contour",
        "Tinted",
        [
          Background.color(color_rgb(236, 245, 250)),
          Border.rounded(8),
          Border.width(1),
          Border.color(color_rgb(210, 220, 236)),
          Border.inner_shadow(blur: 10, color: color_rgba(56, 189, 248, 0.85))
        ],
        [
          "Border.rounded(8)",
          "Border.width(1)",
          "Border.color(:slate_300)",
          "Border.inner_shadow(blur: 10, color: :cyan)"
        ],
        sample_bg: color_rgb(236, 240, 247),
        sample_text_color: color_rgb(33, 43, 60)
      )
    ]
  end

  defp combined_cards do
    [
      border_recipe_card(
        "Dashed + drop shadow",
        "Outlined card with depth",
        "Depth",
        [
          Background.color(color_rgb(245, 244, 255)),
          Border.rounded(10),
          Border.width(2),
          Border.color(color_rgb(144, 102, 255)),
          Border.dashed(),
          Border.shadow(offset: {3, 3}, blur: 10, color: color_rgba(0, 0, 0, 0.55))
        ],
        [
          "Border.rounded(10)",
          "Border.width(2)",
          "Border.color(:purple)",
          "Border.dashed()",
          "Border.shadow(offset: {3, 3}, blur: 10, color: :black)"
        ],
        sample_bg: color_rgb(35, 41, 58),
        sample_text_color: color_rgb(67, 45, 128)
      ),
      border_recipe_card(
        "Dotted + glow + inset",
        "Outer energy + inner depth",
        "Energy",
        [
          Background.gradient(color_rgb(67, 97, 150), color_rgb(111, 77, 189), 135),
          Border.rounded(10),
          Border.width(2),
          Border.color(color_rgb(255, 110, 192)),
          Border.dotted(),
          Border.glow(color_rgba(56, 189, 248, 0.65), 3),
          Border.inner_shadow(blur: 8, color: color_rgba(0, 0, 0, 0.55))
        ],
        [
          "Border.rounded(10)",
          "Border.width(2)",
          "Border.color(:pink)",
          "Border.dotted()",
          "Border.glow(:cyan, 3)",
          "Border.inner_shadow(blur: 8, color: :black)"
        ]
      ),
      border_recipe_card(
        "Per-edge + shadow",
        "Asymmetric border plus depth",
        "Edges",
        [
          Background.color(color_rgb(244, 248, 255)),
          Border.rounded(10),
          Border.width_each(4, 1, 4, 1),
          Border.color(color_rgb(58, 190, 171)),
          Border.solid(),
          Border.shadow(offset: {2, 2}, blur: 8, color: color_rgba(0, 0, 0, 0.45))
        ],
        [
          "Border.rounded(10)",
          "Border.width_each(4, 1, 4, 1)",
          "Border.color(:teal)",
          "Border.solid()",
          "Border.shadow(offset: {2, 2}, blur: 8, color: :black)"
        ],
        sample_bg: color_rgb(35, 41, 58),
        sample_text_color: color_rgb(33, 43, 60)
      )
    ]
  end

  defp pill_radius_showcase do
    el(
      [
        width(fill()),
        padding(14),
        Background.color(color_rgb(50, 54, 76)),
        Border.rounded(12)
      ],
      column([spacing(10)], [
        el(
          [Font.size(13), Font.color(:white), Font.bold()],
          text("rounded(999) clamps to the element height")
        ),
        el(
          [Font.size(11), Font.color(color_rgb(191, 199, 222))],
          text("The same radius creates a circle on square badges and pills on wider labels.")
        ),
        wrapped_row([width(fill()), spacing_xy(10, 10)], [
          pill_circle("42", color_rgb(232, 242, 255), color_rgb(52, 92, 168)),
          pill_chip("Stable", color_rgb(232, 248, 239), color_rgb(11, 126, 84)),
          pill_chip("Release branch", color_rgb(248, 249, 253), color_rgb(67, 81, 109)),
          pill_chip("Design review", color_rgb(244, 239, 255), color_rgb(111, 77, 189))
        ])
      ])
    )
  end

  defp box_shadow_showcase do
    el(
      [
        width(fill()),
        padding(16),
        Background.color(color_rgb(236, 240, 247)),
        Border.rounded(16)
      ],
      row(
        [
          width(fill()),
          padding(18),
          spacing(14),
          Background.color(color_rgb(248, 250, 253)),
          Border.rounded(18),
          Border.shadow(offset: {0, 16}, blur: 28, size: 6, color: color_rgba(15, 23, 42, 0.18))
        ],
        [
          showcase_shadow_card(
            "Stacked",
            "Counter-rotating",
            color_rgb(244, 248, 255),
            color_rgb(33, 43, 60),
            [
              orbiting_shadow_pair_animation(
                color_rgba(15, 23, 42, 0.16),
                18,
                2,
                12,
                color_rgba(56, 189, 248, 0.35),
                10,
                0,
                8,
                2800
              )
            ]
          ),
          showcase_shadow_card(
            "Right cast",
            "Orbiting cast",
            color_rgb(246, 243, 255),
            color_rgb(67, 45, 128),
            [
              orbiting_shadow_animation(
                color_rgba(111, 77, 189, 0.26),
                14,
                2,
                14,
                2400,
                :clockwise
              )
            ]
          ),
          showcase_shadow_card(
            "Soft spread",
            "Orbiting blur",
            color_rgb(240, 249, 246),
            color_rgb(28, 96, 74),
            [
              orbiting_shadow_animation(
                color_rgba(11, 126, 84, 0.2),
                24,
                6,
                12,
                3400,
                :counterclockwise
              )
            ]
          )
        ]
      )
    )
  end

  defp combined_showcase do
    el(
      [
        width(fill()),
        padding(14),
        Background.color(color_rgb(241, 244, 250)),
        Border.rounded(14),
        Border.width(1),
        Border.color(color_rgb(223, 228, 238))
      ],
      el(
        [
          width(fill()),
          padding(18),
          Background.gradient(color_rgb(67, 97, 150), color_rgb(111, 77, 189), 135),
          Border.rounded(18),
          Border.width(2),
          Border.color(color_rgb(255, 110, 192)),
          Border.dotted(),
          Border.glow(color_rgba(56, 189, 248, 0.65), 3),
          Border.shadow(offset: {0, 14}, blur: 28, size: 4, color: color_rgba(15, 23, 42, 0.35)),
          Border.inner_shadow(offset: {0, 2}, blur: 12, color: color_rgba(0, 0, 0, 0.35))
        ],
        column([width(fill()), spacing(12)], [
          row([width(fill()), spacing(8)], [
            showcase_chip("BORDER SHOWCASE", color_rgba(255, 255, 255, 0.18)),
            el([width(fill())], none()),
            showcase_chip("Gradient", color_rgba(255, 255, 255, 0.12))
          ]),
          el(
            [Font.size(24), Font.color(color(:white)), Font.bold()],
            text("Everything on one card")
          ),
          paragraph(
            [
              width(fill()),
              spacing(4),
              Font.size(13),
              Font.color(color_rgba(244, 247, 255, 0.95))
            ],
            [
              text(
                "Gradient background, dotted stroke, outer glow, drop shadow, and an inner shadow all stack on the same rounded shape."
              )
            ]
          ),
          row([width(fill()), spacing(8)], [
            showcase_chip("Rounded", color_rgba(255, 255, 255, 0.12)),
            showcase_chip("Glow", color_rgba(255, 255, 255, 0.12)),
            showcase_chip("Inner depth", color_rgba(255, 255, 255, 0.12))
          ])
        ])
      )
    )
  end

  # Code previews

  defp border_styles_code do
    ~S"""
    el([
      Border.rounded(8),
      Border.width(2),
      Border.color(:orange),
      Border.dashed()
    ], text("Dashed medium round"))
    """
  end

  defp pill_radius_code do
    ~S"""
    el([
      padding_xy(14, 8),
      Border.rounded(999),
      Border.width(1),
      Border.color(color(:slate, 300))
    ], text("Stable"))
    """
  end

  defp per_edge_code do
    ~S"""
    el([
      Border.rounded(8),
      Border.width_each(4, 1, 4, 1),
      Border.color(:teal),
      Border.solid()
    ], text("Asymmetric"))
    """
  end

  defp box_shadow_code do
    ~S"""
    row([width(fill()), spacing(14)], [
      el([
        Animation.animate([
          [
            Border.shadow(offset: {0, -12}, blur: 18, size: 2, color: color_rgba(15, 23, 42, 0.16)),
            Border.shadow(offset: {0, 8}, blur: 10, size: 0, color: color_rgba(56, 189, 248, 0.35))
          ],
          [
            Border.shadow(offset: {12, 0}, blur: 18, size: 2, color: color_rgba(15, 23, 42, 0.16)),
            Border.shadow(offset: {0, 8}, blur: 10, size: 0, color: color_rgba(56, 189, 248, 0.35))
          ]
        ], 2800, :linear, :loop)
      ], text("Stacked")),
      el([
        Animation.animate([
          [Border.shadow(offset: {0, -14}, blur: 14, size: 2, color: color_rgba(111, 77, 189, 0.26))],
          [Border.shadow(offset: {14, 0}, blur: 14, size: 2, color: color_rgba(111, 77, 189, 0.26))]
        ], 2400, :linear, :loop)
      ], text("Right cast"))
    ])
    """
  end

  defp glow_code do
    ~S"""
    el([
      Border.rounded(8),
      Border.glow(:cyan, 4)
    ], text("Glow"))
    """
  end

  defp inner_shadow_code do
    ~S"""
    el([
      Border.rounded(8),
      Border.inner_shadow(offset: {3, 3}, blur: 8, color: :purple)
    ], text("Pressed"))
    """
  end

  defp combined_code do
    ~S"""
    el([
      Background.gradient(color_rgb(67, 97, 150), color_rgb(111, 77, 189), 135),
      Border.rounded(18),
      Border.width(2),
      Border.color(:pink),
      Border.dotted(),
      Border.glow(:cyan, 3),
      Border.shadow(offset: {0, 14}, blur: 28, size: 4, color: color_rgba(15, 23, 42, 0.35)),
      Border.inner_shadow(offset: {0, 2}, blur: 12, color: color_rgba(0, 0, 0, 0.35))
    ], text("Everything on one card"))
    """
  end

  # Generic elements

  defp border_example(title, note, example_id, code, content) do
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

  defp border_recipe_grid(cards) do
    wrapped_row([width(fill()), spacing_xy(12, 12)], cards)
  end

  defp border_recipe_card(title, subtitle, sample_label, sample_attrs, detail_lines, opts \\ []) do
    sample_bg = Keyword.get(opts, :sample_bg, color_rgb(34, 38, 54))
    sample_text_color = Keyword.get(opts, :sample_text_color, color(:white))

    el(
      [
        width(max(px(280), fill())),
        padding(12),
        Background.color(color_rgb(245, 247, 251)),
        Border.rounded(12),
        Border.width(1),
        Border.color(color_rgb(223, 228, 238))
      ],
      column([spacing(10)], [
        el(
          [
            width(fill()),
            height(px(84)),
            padding(12),
            Background.color(sample_bg),
            Border.rounded(10)
          ],
          el(
            [width(fill()), height(fill())] ++ sample_attrs,
            el(
              [center_x(), center_y(), Font.size(13), Font.bold(), Font.color(sample_text_color)],
              text(sample_label)
            )
          )
        ),
        el([Font.size(13), Font.color(title_text()), Font.bold()], text(title)),
        el([Font.size(11), Font.color(body_text())], text(subtitle)),
        column(
          [spacing(2)],
          Enum.map(detail_lines, fn line ->
            el([Font.size(10), Font.color(detail_text())], text(line))
          end)
        )
      ])
    )
  end

  defp showcase_shadow_card(title, subtitle, bg, text_color, shadow_attrs) do
    el(
      [
        width(fill(1)),
        height(px(94)),
        padding(14),
        Background.color(bg),
        Border.rounded(14)
      ] ++ shadow_attrs,
      column([width(fill()), spacing(4)], [
        el([Font.size(14), Font.color(text_color), Font.bold()], text(title)),
        el([Font.size(11), Font.color(text_color)], text(subtitle))
      ])
    )
  end

  defp orbiting_shadow_animation(color, blur, size, radius, duration, direction) do
    positions = orbit_positions(radius, direction)

    Animation.animate(
      Enum.map(positions, fn {x, y} ->
        [Border.shadow(offset: {x, y}, blur: blur, size: size, color: color)]
      end),
      duration,
      :linear,
      :loop
    )
  end

  defp orbiting_shadow_pair_animation(
         color_a,
         blur_a,
         size_a,
         radius_a,
         color_b,
         blur_b,
         size_b,
         radius_b,
         duration
       ) do
    primary = orbit_positions(radius_a, :clockwise)

    secondary = [
      {0, radius_b},
      {0, radius_b},
      {-radius_b, 0},
      {-radius_b, 0},
      {0, -radius_b},
      {0, -radius_b},
      {radius_b, 0},
      {radius_b, 0},
      {0, radius_b}
    ]

    Animation.animate(
      Enum.zip(primary, secondary)
      |> Enum.map(fn {{ax, ay}, {bx, by}} ->
        [
          Border.shadow(offset: {ax, ay}, blur: blur_a, size: size_a, color: color_a),
          Border.shadow(offset: {bx, by}, blur: blur_b, size: size_b, color: color_b)
        ]
      end),
      duration,
      :linear,
      :loop
    )
  end

  defp orbit_positions(radius, :clockwise) do
    [
      {0, -radius},
      {radius, -radius},
      {radius, 0},
      {radius, radius},
      {0, radius},
      {-radius, radius},
      {-radius, 0},
      {-radius, -radius},
      {0, -radius}
    ]
  end

  defp orbit_positions(radius, :counterclockwise) do
    [
      {0, -radius},
      {-radius, -radius},
      {-radius, 0},
      {-radius, radius},
      {0, radius},
      {radius, radius},
      {radius, 0},
      {radius, -radius},
      {0, -radius}
    ]
  end

  defp pill_circle(label, bg, text_color) do
    el(
      [
        width(px(44)),
        height(px(44)),
        Background.color(bg),
        Border.rounded(999),
        Border.width(1),
        Border.color(color_rgb(214, 220, 236))
      ],
      el([center_x(), center_y(), Font.color(text_color)], text(label))
    )
  end

  defp pill_chip(label, bg, text_color) do
    el(
      [
        padding_xy(14, 8),
        Background.color(bg),
        Border.rounded(999),
        Border.width(1),
        Border.color(color_rgb(214, 220, 236)),
        Font.color(text_color)
      ],
      text(label)
    )
  end

  defp showcase_chip(label, bg) do
    el(
      [
        padding_each(5, 9, 5, 9),
        Background.color(bg),
        Border.rounded(999),
        Font.size(10),
        Font.color(color_rgba(255, 255, 255, 0.92))
      ],
      text(label)
    )
  end

  # Palette

  defp title_text, do: color_rgb(24, 30, 38)
  defp body_text, do: color_rgb(92, 100, 114)
  defp detail_text, do: color_rgb(120, 128, 144)
end
