defmodule EmergeDemo.Showcase.View.Text do
  use Emerge.UI

  alias EmergeDemo.Showcase.View

  # Page composition

  def layout do
    column([width(fill()), spacing(28)], [
      font_section(),
      decoration_spacing_section(),
      text_alignment_section(),
      paragraph_section(),
      document_flow_section(),
      float_flow_section()
    ])
  end

  # Page sections

  defp font_section do
    column([width(fill()), spacing(16)], [
      section_title("Font"),
      section_copy(
        "Font attrs inherit through the tree, so container-level defaults can establish the tone while children override only what needs to change."
      ),
      text_example(
        "Inheritance, size, weight, and style",
        "Compare inherited body styling with size steps and common weight/style combinations.",
        {:text, :font_basics},
        font_basics_code(),
        column([width(fill()), spacing(12)], [
          font_inheritance_demo(),
          wrapped_row([width(fill()), spacing_xy(12, 12)], [
            font_sizes_demo(),
            font_weight_style_demo()
          ])
        ])
      )
    ])
  end

  defp decoration_spacing_section do
    column([width(fill()), spacing(16)], [
      section_title("Decoration + Spacing"),
      section_copy(
        "Underline, strike, letter spacing, and word spacing all shape rhythm and emphasis without changing layout placement."
      ),
      text_example(
        "Decoration and spacing",
        "Compare line decoration with tracked and spaced labels.",
        {:text, :decoration_spacing},
        decoration_spacing_code(),
        column([width(fill()), spacing(12)], [
          decoration_demo(),
          spacing_demo()
        ])
      )
    ])
  end

  defp text_alignment_section do
    column([width(fill()), spacing(16)], [
      section_title("Text Alignment"),
      section_copy(
        "Font alignment changes how text sits inside its content box. It does not move the box itself through a row or column."
      ),
      text_example(
        "Alignment and inherited overrides",
        "Compare left, center, and right text alignment, then override inherited font settings on individual children.",
        {:text, :text_alignment},
        text_alignment_code(),
        column([width(fill()), spacing(12)], [
          alignment_demo(),
          inheritance_override_demo()
        ])
      )
    ])
  end

  defp paragraph_section do
    column([width(fill()), spacing(16)], [
      section_title("Paragraph"),
      section_copy(
        "Paragraphs wrap inline text naturally, so rich text can mix plain copy with styled spans and different line spacing in the same flow."
      ),
      text_example(
        "Paragraph flow",
        "See wrapped body copy, inline styled spans, and how paragraph spacing changes readability.",
        {:text, :paragraph},
        paragraph_code(),
        column([width(fill()), spacing(12)], [
          paragraph_demo(),
          inline_spans_demo(),
          line_spacing_demo()
        ])
      )
    ])
  end

  defp document_flow_section do
    column([width(fill()), spacing(16)], [
      section_title("Document Flow"),
      section_copy(
        "Document-style layouts combine headings, paragraphs, and text columns into readable article blocks without leaving the normal layout model."
      ),
      text_example(
        "Document cards and text columns",
        "Build article-like content with headings and grouped paragraphs, then switch to text_column for longer narrative blocks.",
        {:text, :document_flow},
        document_flow_code(),
        column([width(fill()), spacing(12)], [
          document_style_demo(),
          text_column_demo()
        ])
      )
    ])
  end

  defp float_flow_section do
    column([width(fill()), spacing(16)], [
      section_title("Float Flow"),
      section_copy(
        "align_left and align_right can float blocks inside paragraph and text_column content, letting copy wrap around richer inserts before returning to full width."
      ),
      text_example(
        "Paragraph and text_column floats",
        "Resize the page to see the same content reflow around floated blocks in both paragraph and text_column containers.",
        {:text, :float_flow},
        float_flow_code(),
        column([width(fill()), spacing(12)], [
          float_paragraph_demo(),
          float_text_column_demo()
        ])
      )
    ])
  end

  # Page-specific helpers

  defp font_inheritance_demo do
    el(
      [
        width(fill()),
        padding(12),
        Font.size(14),
        Font.color(color_rgb(200, 220, 255)),
        Background.color(color_rgb(45, 45, 65)),
        Border.rounded(8)
      ],
      column([spacing(8)], [
        text("This text inherits font from the column"),
        text("No Font.size() or Font.color() here"),
        row([spacing(8)], [
          text("Row child 1"),
          text("Row child 2"),
          text("All inherited")
        ])
      ])
    )
  end

  defp font_sizes_demo do
    el(
      [
        width(max(px(320), fill())),
        padding(12),
        Background.color(color_rgb(45, 45, 65)),
        Border.rounded(8)
      ],
      column([spacing(8)], [
        el([Font.size(12), Font.color(color_rgb(175, 186, 208))], text("Font sizes")),
        row([width(fill()), spacing(12), align_bottom()], [
          el([Font.size(10), Font.color(:white)], text("10px")),
          el([Font.size(12), Font.color(:white)], text("12px")),
          el([Font.size(14), Font.color(:white)], text("14px")),
          el([Font.size(16), Font.color(:white)], text("16px")),
          el([Font.size(20), Font.color(:white)], text("20px")),
          el([Font.size(24), Font.color(:white)], text("24px"))
        ])
      ])
    )
  end

  defp font_weight_style_demo do
    el(
      [
        width(max(px(320), fill())),
        padding(12),
        Background.color(color_rgb(45, 45, 65)),
        Border.rounded(8)
      ],
      column([spacing(8)], [
        el([Font.size(12), Font.color(color_rgb(175, 186, 208))], text("Weight and style")),
        wrapped_row([width(fill()), spacing_xy(16, 10)], [
          el([Font.size(14), Font.color(:white)], text("Normal")),
          el([Font.size(14), Font.color(:white), Font.bold()], text("Bold")),
          el([Font.size(14), Font.color(:white), Font.italic()], text("Italic")),
          el([Font.size(14), Font.color(:white), Font.bold(), Font.italic()], text("Bold Italic"))
        ])
      ])
    )
  end

  defp decoration_demo do
    wrapped_row([width(fill()), spacing_xy(10, 10)], [
      decoration_chip(
        "Underline",
        [Font.underline()],
        color_rgb(54, 70, 90)
      ),
      decoration_chip("Strike", [Font.strike()], color_rgb(72, 62, 88)),
      decoration_chip(
        "Underline + Strike",
        [Font.underline(), Font.strike()],
        color_rgb(70, 80, 62)
      )
    ])
  end

  defp spacing_demo do
    wrapped_row([width(fill()), spacing_xy(10, 10)], [
      spacing_chip(
        "LETTER SPACING",
        [Font.letter_spacing(2.5)],
        color_rgb(45, 60, 82)
      ),
      spacing_chip("word spacing demo", [Font.word_spacing(5)], color_rgb(56, 74, 66)),
      spacing_chip(
        "combined spacing",
        [Font.underline(), Font.letter_spacing(1.5), Font.word_spacing(3)],
        color_rgb(75, 62, 62)
      )
    ])
  end

  defp alignment_demo do
    wrapped_row([width(fill()), spacing_xy(8, 8)], [
      alignment_card("Left", Font.align_left()),
      alignment_card("Center", Font.center()),
      alignment_card("Right", Font.align_right())
    ])
  end

  defp inheritance_override_demo do
    el(
      [
        width(fill()),
        padding(12),
        Background.color(color_rgb(50, 50, 70)),
        Border.rounded(8)
      ],
      column(
        [
          spacing(8),
          Font.size(14),
          Font.color(color_rgb(180, 180, 200))
        ],
        [
          text("Inherited: 14px, gray"),
          el([Font.size(18), Font.color(:cyan)], text("Override: 18px, cyan")),
          el([Font.bold()], text("Override: bold only")),
          text("Back to inherited")
        ]
      )
    )
  end

  defp paragraph_demo do
    el(
      [
        width(max(px(400), fill())),
        padding(12),
        Background.color(color_rgb(45, 45, 65)),
        Border.rounded(8)
      ],
      paragraph([Font.size(14), Font.color(:white)], [
        text(
          "This is a paragraph that demonstrates automatic word wrapping. " <>
            "When text exceeds the available width, it flows naturally to the next line, " <>
            "just like in a word processor or web browser. No manual line breaks needed."
        )
      ])
    )
  end

  defp inline_spans_demo do
    el(
      [
        width(max(px(450), fill())),
        padding(12),
        Background.color(color_rgb(45, 45, 65)),
        Border.rounded(8)
      ],
      paragraph([Font.size(14), Font.color(:white)], [
        text("Paragraphs support "),
        el([Font.bold()], text("bold text")),
        text(" and "),
        el([Font.color(color_rgb(255, 120, 172))], text("colored spans")),
        text(" inline. This lets you build rich text layouts where "),
        el([Font.bold(), Font.color(color_rgb(92, 156, 255))], text("styled fragments")),
        text(" flow naturally within the same line-wrapped block.")
      ])
    )
  end

  defp line_spacing_demo do
    wrapped_row([width(fill()), spacing_xy(16, 16)], [
      line_spacing_card(
        "spacing(0)",
        0,
        "Tight line spacing makes text feel compact and dense. Good for code-like displays or space-constrained layouts."
      ),
      line_spacing_card(
        "spacing(8)",
        8,
        "Relaxed line spacing improves readability for body text. Good for articles, documentation, and longer content."
      )
    ])
  end

  defp document_style_demo do
    el(
      [
        width(fill()),
        padding(16),
        Background.color(color_rgb(40, 40, 60)),
        Border.rounded(10)
      ],
      column([width(fill()), spacing(12)], [
        el([Font.size(20), Font.bold(), Font.color(:white)], text("Getting Started")),
        paragraph([spacing(4), Font.size(14), Font.color(color_rgb(210, 210, 230))], [
          text(
            "Emerge is a native GUI toolkit for Elixir that renders with Skia. " <>
              "It uses a declarative layout model inspired by elm-ui, where you describe " <>
              "what your interface should look like and the engine handles the rest."
          )
        ]),
        paragraph([spacing(4), Font.size(14), Font.color(color_rgb(210, 210, 230))], [
          text("To get started, add "),
          el([Font.bold(), Font.color(color_rgb(92, 156, 255))], text("emerge_skia")),
          text(" to your dependencies and call "),
          el([Font.bold(), Font.color(color_rgb(92, 156, 255))], text("EmergeSkia.start/1")),
          text(
            ". From there you can build your UI tree using the helpers in Emerge.UI and send it to the renderer."
          )
        ])
      ])
    )
  end

  defp text_column_demo do
    el(
      [
        width(fill()),
        padding(16),
        Background.color(color_rgb(37, 44, 58)),
        Border.rounded(10)
      ],
      text_column(
        [spacing(14), Font.size(14), Font.color(color_rgb(220, 226, 236))],
        [
          paragraph([spacing(4)], [
            text(
              "Text columns are useful for blog posts, release notes, and long-form product explanations where several paragraphs should read as one section."
            )
          ]),
          paragraph([spacing(4)], [
            text("This block fills the available width by default, and you can still "),
            el(
              [Font.bold(), Font.color(color_rgb(92, 156, 255))],
              text("override width or spacing")
            ),
            text(" when a specific layout needs tighter control.")
          ]),
          paragraph([spacing(4)], [
            text(
              "In this demo it behaves like a vertical text container with paragraph-friendly defaults, so it is easy to compose document-style content."
            )
          ])
        ]
      )
    )
  end

  defp float_paragraph_demo do
    el(
      [
        width(fill()),
        padding(16),
        Background.color(color_rgb(44, 50, 66)),
        Border.rounded(10)
      ],
      paragraph([spacing(4), Font.size(14), Font.color(color_rgb(226, 232, 243))], [
        el(
          [
            align_left(),
            width(px(40)),
            height(px(40)),
            Background.color(color_rgb(74, 113, 214)),
            Border.rounded(8)
          ],
          el(
            [
              Font.bold(),
              Font.size(26),
              Font.color(:white),
              center_x(),
              center_y()
            ],
            text("S")
          )
        ),
        text(
          "tylish copy can wrap around a left-floated drop cap. This paragraph demonstrates inline flow with richer composition while keeping word wrapping automatic. "
        ),
        el(
          [
            align_right(),
            width(px(96)),
            padding(8),
            Background.color(color_rgb(78, 58, 90)),
            Border.rounded(6),
            Font.size(11),
            Font.bold(),
            Font.color(:white)
          ],
          text("PULL QUOTE")
        ),
        text(
          "A right float can sit beside the same text flow, and once the floated blocks end, text returns to full width for the rest of the paragraph."
        )
      ])
    )
  end

  defp float_text_column_demo do
    el(
      [
        width(fill()),
        padding(16),
        Background.color(color_rgb(36, 46, 60)),
        Border.rounded(10)
      ],
      text_column(
        [spacing(10), Font.size(13), Font.color(color_rgb(220, 228, 238))],
        [
          el(
            [
              align_left(),
              width(px(128)),
              height(px(92)),
              padding(10),
              Background.color(color_rgb(67, 97, 150)),
              Border.rounded(8)
            ],
            column([spacing(6)], [
              el([Font.bold(), Font.color(:white)], text("Floated Card")),
              el([Font.size(11), Font.color(color_rgb(232, 238, 246))], text("align_left()")),
              el([Font.size(11), Font.color(color_rgb(232, 238, 246))], text("92px tall"))
            ])
          ),
          paragraph([spacing(3)], [
            text(
              "This paragraph wraps around the floated card first, using the remaining line width to the right."
            )
          ]),
          paragraph([spacing(3)], [
            text(
              "A second paragraph keeps flowing around the same active float until its bottom edge is passed."
            )
          ]),
          el(
            [
              width(fill()),
              padding(8),
              Background.color(color_rgb(84, 62, 62)),
              Border.rounded(6),
              Font.size(12),
              Font.color(:white)
            ],
            text("Non-paragraph block: clears below active floats before rendering")
          ),
          paragraph([spacing(3)], [
            text(
              "After the clear block, flow continues as normal content in the text column with consistent vertical spacing."
            )
          ])
        ]
      )
    )
  end

  # Code previews

  defp font_basics_code do
    ~S"""
    column([Font.size(14), Font.color(color(:sky, 200))], [
      text("Inherited text"),
      row([], [text("Still inherited")])
    ])

    el([Font.bold()], text("Bold"))
    """
  end

  defp decoration_spacing_code do
    ~S"""
    el([Font.underline()], text("Underline"))
    el([Font.strike()], text("Strike"))
    el([Font.letter_spacing(2.5)], text("TRACKED"))
    el([Font.word_spacing(5)], text("word spacing demo"))
    """
  end

  defp text_alignment_code do
    ~S"""
    el([width(fill()), Font.align_left()], text("Left"))
    el([width(fill()), Font.center()], text("Center"))
    el([width(fill()), Font.align_right()], text("Right"))
    """
  end

  defp paragraph_code do
    ~S"""
    paragraph([width(px(400))], [
      text("Wrapped body copy"),
      el([Font.bold()], text("inline span"))
    ])
    """
  end

  defp document_flow_code do
    ~S"""
    column([], [
      el([Font.size(20), Font.bold()], text("Getting Started")),
      paragraph([], [text("Document paragraph")])
    ])

    text_column([spacing(14)], [
      paragraph([], [text("Column paragraph")])
    ])
    """
  end

  defp float_flow_code do
    ~S"""
    paragraph([], [
      el([align_left(), width(px(40)), height(px(40))], text("S")),
      text("Wrapped text around a floated block")
    ])
    """
  end

  # Generic elements

  defp text_example(title, note, example_id, code, content) do
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

  defp decoration_chip(label, font_attrs, bg) do
    el(
      [
        width(max(px(210), fill())),
        padding(8),
        Background.color(bg),
        Border.rounded(6),
        Font.size(13),
        Font.color(:white)
      ] ++ font_attrs,
      text(label)
    )
  end

  defp spacing_chip(label, font_attrs, bg) do
    el(
      [
        width(max(px(210), fill())),
        padding(8),
        Background.color(bg),
        Border.rounded(6),
        Font.size(12),
        Font.color(:white)
      ] ++ font_attrs,
      text(label)
    )
  end

  defp alignment_card(label, alignment_attr) do
    el(
      [
        width(max(px(180), fill())),
        padding(8),
        Background.color(color_rgb(55, 55, 80)),
        Border.rounded(4)
      ],
      el([width(fill()), Font.size(12), Font.color(:white), alignment_attr], text(label))
    )
  end

  defp line_spacing_card(label, spacing_value, copy) do
    column([width(max(px(320), fill())), spacing(6)], [
      el([Font.size(11), Font.color(body_text())], text(label)),
      el(
        [
          width(fill()),
          padding(10),
          Background.color(color_rgb(45, 45, 65)),
          Border.rounded(6)
        ],
        paragraph([spacing(spacing_value), Font.size(13), Font.color(:white)], [
          text(copy)
        ])
      )
    ])
  end

  # Palette

  defp title_text, do: color_rgb(24, 30, 38)
  defp body_text, do: color_rgb(92, 100, 114)
end
