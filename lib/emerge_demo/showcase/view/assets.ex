defmodule EmergeDemo.Showcase.View.Assets do
  use Emerge.UI

  alias EmergeDemo.Showcase.AssetCatalog
  alias EmergeDemo.Showcase.View

  @fit_frames [
    {"Wide frame", {280, 120}},
    {"Tall frame", {140, 240}},
    {"Square frame", {180, 180}}
  ]

  # Page composition

  def layout do
    column([width(fill()), spacing(28)], [
      assets_section(),
      svg_weather_section(),
      svg_scaling_section(),
      svg_tint_section(),
      source_section(),
      fonts_section(),
      image_section(),
      background_section(),
      demo_policy_section()
    ])
  end

  # Page sections

  defp assets_section do
    column([width(fill()), spacing(16)], [
      section_title("Assets"),
      section_copy(
        "Assets resolve from the example app priv directory or from allowlisted runtime paths. This page keeps the old demo breadth: image/2, Background helpers, SVGs, fonts, source behavior, fit modes, and the renderer policy that makes them work."
      ),
      assets_example(
        "image/2 + Background.image/2",
        "Start with the two most common entry points: a normal image element and an element whose frame is painted from an asset background.",
        {:assets, :overview},
        assets_overview_code(),
        assets_overview_showcase()
      )
    ])
  end

  defp svg_weather_section do
    column([width(fill()), spacing(16)], [
      section_title("SVG Weather"),
      section_copy(
        "A hardcoded seven-day forecast using local SVG icons. Temperatures lead with Celsius and keep Fahrenheit as the quieter secondary scale."
      ),
      assets_example(
        "Local SVGs in a richer UI card",
        "The same small set of SVG files can drive a more composed interface, not just standalone icons.",
        {:assets, :svg_weather},
        svg_weather_code(),
        weather_widget_card(AssetCatalog.weather_forecast_data())
      )
    ])
  end

  defp svg_scaling_section do
    specs = [
      {"Sun", "Bright icon reused from forecast cells to oversized hero scale.",
       AssetCatalog.weather_icon_source(:sun)},
      {"Cloud", "Soft neutral linework rendered across compact and roomy card slots.",
       AssetCatalog.weather_icon_source(:cloud)},
      {"Rain", "Same source file reused for small forecast markers and larger detail art.",
       AssetCatalog.weather_icon_source(:rain)}
    ]

    column([width(fill()), spacing(16)], [
      section_title("SVG Scaling"),
      section_copy(
        "The same icon files stay crisp across compact forecast markers and larger showcase sizes."
      ),
      assets_example(
        "svg/2 across multiple sizes",
        "Render the same source at 24px, 48px, and 80px to compare scale without changing the file.",
        {:assets, :svg_scaling},
        svg_scaling_code(),
        svg_weather_scale_showcase(specs)
      )
    ])
  end

  defp svg_tint_section do
    column([width(fill()), spacing(16)], [
      section_title("SVG Tint"),
      section_copy(
        "svg/2 preserves original colors by default. Svg.color/1 applies template tint to all visible pixels while keeping alpha and edge smoothing."
      ),
      assets_example(
        "Original, tinted, and flattened multicolor SVGs",
        "Keep the original strokes when no tint is set, then compare how a single tint recolors template art and flattens a multicolor source into one themed silhouette.",
        {:assets, :svg_tint},
        svg_tint_code(),
        svg_tint_showcase(AssetCatalog.template_cloud(), AssetCatalog.tile_quad())
      )
    ])
  end

  defp source_section do
    column([width(fill()), spacing(16)], [
      section_title("Source"),
      section_copy(
        "How each source type resolves before rendering: logical assets from priv, allowlisted runtime paths, and runtime paths that the renderer blocks."
      ),
      assets_example(
        "Logical and runtime sources",
        "The blocked card intentionally points outside the runtime allowlist so it resolves to the failed placeholder instead of loading the file.",
        {:assets, :source},
        source_cards_code(),
        centered_wrapped_cards(source_cards(), 936)
      )
    ])
  end

  defp fonts_section do
    column([width(fill()), spacing(16)], [
      section_title("Fonts"),
      section_copy(
        "Startup font assets are resolved from priv and mapped by family, weight, and style before the example viewport renders."
      ),
      assets_example(
        "Built-in and startup-loaded font families",
        "The built-in default requires no config. The Lobster sample is loaded once at startup and then selected declaratively through Font.family/1.",
        {:assets, :fonts},
        font_cards_code(),
        centered_wrapped_cards(font_cards(), 936)
      )
    ])
  end

  defp image_section do
    column([width(fill()), spacing(16)], [
      section_title("Image"),
      section_copy(
        "image/2 fit behavior with the same source across wide, tall, and square frames. contain keeps the full image visible, while cover fills the frame and may crop."
      ),
      assets_example(
        "image/2 contain and cover",
        "Compare the same raster source across changing frame ratios without changing the file itself.",
        {:assets, :image_fit},
        image_fit_code(),
        column([width(fill()), spacing(12)], [
          centered_wrapped_cards(image_fit_cards(), 960),
          fit_legend()
        ])
      )
    ])
  end

  defp background_section do
    column([width(fill()), spacing(16)], [
      section_title("Background"),
      section_copy(
        "Background.image plus its contain and repeat helpers. The helper cards keep the same frame design so the only difference is the background attribute itself."
      ),
      assets_example(
        "Background.image and helper variants",
        "The tile source is reused with cover, contain, repeat, repeat_x, and repeat_y to show the helper APIs side by side.",
        {:assets, :background_helpers},
        background_helpers_code(),
        centered_wrapped_cards(background_cards(), 936)
      ),
      assets_example(
        "Background.image/2 fit behavior",
        "The same raster source uses contain and cover inside wide, tall, and square frames while foreground content stays in the host element.",
        {:assets, :background_fit},
        background_fit_code(),
        column([width(fill()), spacing(8)], [
          centered_wrapped_cards(background_fit_cards(), 960),
          paragraph([width(fill()), spacing(3), Font.size(10), Font.color(dim_text())], [
            text(
              "Tile source: demo_images/tile_bird_small.jpg (160x120). SVG backgrounds are also supported through the same API."
            )
          ])
        ])
      )
    ])
  end

  defp demo_policy_section do
    column([width(fill()), spacing(16)], [
      section_title("Demo Policy"),
      section_copy(
        "The page uses startup font registration plus runtime path allowlisting, and then relies on the renderer's built-in pending and failed placeholders while assets resolve asynchronously."
      ),
      assets_example(
        "Renderer asset config",
        "This is the renderer-side setup that makes the logical, runtime, and font examples on this page work inside the example app.",
        {:assets, :policy},
        demo_policy_code(),
        demo_policy_card()
      )
    ])
  end

  # Page-specific helpers

  defp assets_overview_showcase do
    wrapped_row([width(fill()), spacing_xy(16, 16)], [
      column([width(max(px(240), fill())), spacing(8)], [
        el([Font.color(color(:slate, 50)), Font.size(14)], text("image/2")),
        el(
          [
            padding(10),
            Background.color(color(:slate, 800)),
            Border.rounded(12)
          ],
          image(
            [width(px(120)), height(px(120)), Border.rounded(10)],
            AssetCatalog.static_image()
          )
        )
      ]),
      column([width(max(px(320), fill())), spacing(8)], [
        el([Font.color(color(:slate, 50)), Font.size(14)], text("Background.image/2")),
        el(
          [
            width(px(288)),
            height(px(160)),
            padding(12),
            Background.image(AssetCatalog.fallback_image(), fit: :cover),
            Border.rounded(12)
          ],
          column([height(fill()), spacing(8)], [
            el(
              [
                padding_xy(10, 6),
                Background.color(color_rgba(15, 23, 42, 0.7)),
                Border.rounded(999),
                Font.color(color(:slate, 50))
              ],
              text("Featured trail")
            ),
            el(
              [
                align_bottom(),
                padding(10),
                Background.color(color_rgba(15, 23, 42, 0.58)),
                Border.rounded(10),
                Font.color(color(:slate, 50))
              ],
              column([spacing(4)], [
                el([Font.size(18)], text("Background image host")),
                el(
                  [Font.size(12), Font.color(color(:slate, 200))],
                  text("Foreground content sits on top.")
                )
              ])
            )
          ])
        )
      ])
    ])
  end

  defp source_cards do
    [
      %{
        title: "Static source",
        source_label: ~s(source: "demo_images/static.jpg"),
        status: {"Source root", :source},
        preview: {:image, AssetCatalog.static_image(), :contain, "image :contain"}
      },
      %{
        title: "Runtime source",
        source_label: "source: {:path, runtime.jpg}",
        status: {"Allowlisted", :runtime},
        preview: {:image, AssetCatalog.runtime_image_source(), :cover, "image :cover"}
      },
      %{
        title: "Static SVG source",
        source_label: ~s(source: "demo_images/weather_sun.svg"),
        status: {"Source root", :source},
        preview: {:svg, AssetCatalog.weather_icon_source(:sun), :contain, "svg :contain"}
      },
      %{
        title: "Restricted source",
        source_label: "source outside allowlist",
        status: {"Blocked", :blocked},
        preview: {:image, AssetCatalog.blocked_image_source(), :contain, "blocked"}
      }
    ]
    |> Enum.map(&asset_behavior_card/1)
  end

  defp font_cards do
    [
      %{
        title: "Default Inter",
        source_label: "source: built-in default",
        status: {"Built-in", :font_builtin},
        note: "No assets.fonts entry required",
        attrs: []
      },
      %{
        title: "Lobster asset",
        source_label: ~s(source: "#{AssetCatalog.lobster_font_path()}"),
        status: {"Font asset", :font},
        note: "Loaded at startup from the example app priv",
        attrs: [Font.family("lobster-demo")]
      },
      %{
        title: "Lobster synthetic bold + italic",
        source_label: ~s(source: "#{AssetCatalog.lobster_font_path()}"),
        status: {"Synthetic", :synthetic},
        note: "Only the regular face is loaded, so style is synthesized",
        attrs: [Font.family("lobster-demo"), Font.bold(), Font.italic()]
      }
    ]
    |> Enum.map(&font_asset_card/1)
  end

  defp image_fit_cards do
    fit_demo_cards("image/2", :image, AssetCatalog.static_image())
  end

  defp background_cards do
    [
      %{
        title: "Background.image/1",
        source_label: "source: demo_images/tile_bird_small.jpg",
        status: {"Background", :background},
        preview: {:background, Background.image(AssetCatalog.bird_tile()), "bg :cover"}
      },
      %{
        title: "Background.uncropped/1",
        source_label: "source: demo_images/tile_bird_small.jpg",
        status: {"Helper", :helper},
        preview: {:background, Background.uncropped(AssetCatalog.bird_tile()), "bg :contain"}
      },
      %{
        title: "Background.tiled/1",
        source_label: "source: demo_images/tile_bird_small.jpg",
        status: {"Helper", :helper},
        preview: {:background, Background.tiled(AssetCatalog.bird_tile()), "bg :repeat"}
      },
      %{
        title: "Background.tiled_x/1",
        source_label: "source: demo_images/tile_bird_small.jpg",
        status: {"Helper", :helper},
        preview: {:background, Background.tiled_x(AssetCatalog.bird_tile()), "bg :repeat_x"}
      },
      %{
        title: "Background.tiled_y/1",
        source_label: "source: demo_images/tile_bird_small.jpg",
        status: {"Helper", :helper},
        preview: {:background, Background.tiled_y(AssetCatalog.bird_tile()), "bg :repeat_y"}
      }
    ]
    |> Enum.map(&asset_behavior_card/1)
  end

  defp background_fit_cards do
    fit_demo_cards("Background.image/2", :background, AssetCatalog.static_image())
  end

  defp fit_demo_cards(api_label, variant, source) do
    Enum.flat_map(@fit_frames, fn {label, dims} ->
      Enum.map([:contain, :cover], fn fit ->
        fit_demo_card(api_label, label, dims, fit, variant, source)
      end)
    end)
  end

  defp centered_wrapped_cards(cards, max_width) do
    el(
      [center_x(), width(max(px(max_width), fill()))],
      wrapped_row([width(fill()), spacing_xy(12, 12)], cards)
    )
  end

  defp asset_behavior_card(%{
         title: title,
         source_label: source_label,
         status: {status_label, status_tone},
         preview: preview_spec
       }) do
    el(
      [
        width(px(300)),
        padding(10),
        spacing(8),
        Background.color(dark_card_bg()),
        Border.rounded(10)
      ],
      column([spacing(8)], [
        row([width(fill()), spacing(8)], [
          el([width(fill()), Font.size(12), Font.color(color(:white))], text(title)),
          source_status_chip(status_label, status_tone)
        ]),
        paragraph([width(fill()), spacing(3), Font.size(10), Font.color(dim_text())], [
          text(source_label)
        ]),
        el(
          [
            width(fill()),
            height(px(170)),
            padding(8),
            Background.color(dark_panel_bg()),
            Border.rounded(8)
          ],
          asset_behavior_preview(preview_spec)
        )
      ])
    )
  end

  defp font_asset_card(%{
         title: title,
         source_label: source_label,
         status: {status_label, status_tone},
         note: note,
         attrs: font_attrs
       }) do
    sample = "quick brown fox jumps over a lazy dog"

    el(
      [
        width(px(300)),
        padding(10),
        spacing(8),
        Background.color(dark_card_bg()),
        Border.rounded(10)
      ],
      column([spacing(8)], [
        row([width(fill()), spacing(8)], [
          el([width(fill()), Font.size(12), Font.color(color(:white))], text(title)),
          source_status_chip(status_label, status_tone)
        ]),
        paragraph([width(fill()), spacing(3), Font.size(10), Font.color(dim_text())], [
          text(source_label)
        ]),
        paragraph(
          [width(fill()), spacing(3), Font.size(10), Font.color(color_rgb(196, 202, 222))],
          [
            text(note)
          ]
        ),
        el(
          [
            width(fill()),
            padding(10),
            Background.color(dark_panel_bg()),
            Border.rounded(8)
          ],
          column([spacing(6)], [
            el([Font.size(22), Font.color(color(:white))] ++ font_attrs, text("Asset Fonts 123")),
            el(
              [Font.size(12), Font.color(color_rgb(214, 220, 236))] ++ font_attrs,
              text(sample)
            )
          ])
        )
      ])
    )
  end

  defp weather_widget_card(days) do
    counts = Enum.frequencies_by(days, & &1.kind)

    summary =
      "#{Map.get(counts, :sun, 0)} sunny, #{Map.get(counts, :cloud, 0)} cloudy, #{Map.get(counts, :rain, 0)} rainy across the week"

    el(
      [
        width(fill()),
        padding(16),
        spacing(14),
        Background.gradient(color_rgb(16, 52, 102), color_rgb(44, 132, 182), 90),
        Border.rounded(18),
        Border.width(1),
        Border.color(color_rgba(204, 233, 255, 120 / 255)),
        Border.glow(color_rgba(66, 156, 230, 90 / 255), 4)
      ],
      column([spacing(14)], [
        row([width(fill()), spacing(12)], [
          column([width(fill()), spacing(6)], [
            el([Font.size(22), Font.color(color(:white))], text("Weekly forecast")),
            paragraph(
              [width(fill()), spacing(3), Font.size(12), Font.color(color_rgb(226, 238, 249))],
              [
                text("North Shore boardwalk · local SVG weather icons rendered with svg/2")
              ]
            ),
            wrapped_row([width(fill()), spacing_xy(8, 8)], [
              weather_badge("SVG via svg/2", color_rgba(5, 20, 34, 105 / 255)),
              weather_badge("C primary", color_rgba(28, 83, 49, 140 / 255)),
              weather_badge("F secondary", color_rgba(64, 52, 20, 130 / 255))
            ])
          ]),
          column([spacing(8)], [
            el(
              [
                padding_each(5, 10, 5, 10),
                Background.color(color_rgba(6, 24, 40, 110 / 255)),
                Border.rounded(999),
                Font.size(11),
                Font.color(color(:white))
              ],
              text("Hardcoded sample")
            ),
            paragraph(
              [width(px(220)), spacing(3), Font.size(11), Font.color(color_rgb(220, 236, 248))],
              [
                text(summary)
              ]
            )
          ])
        ]),
        el(
          [
            width(fill()),
            padding(10),
            Background.color(color_rgba(5, 20, 34, 95 / 255)),
            Border.rounded(14)
          ],
          wrapped_row([width(fill()), spacing_xy(10, 10)], Enum.map(days, &weather_day_card/1))
        )
      ])
    )
  end

  defp weather_day_card(%{day: day, kind: kind, high_c: high_c, low_c: low_c, precip: precip}) do
    {icon_glow, accent, detail_bg} = weather_icon_tone(kind)

    el(
      [
        width(px(118)),
        padding(10),
        spacing(8),
        Background.color(color_rgba(8, 18, 30, 145 / 255)),
        Border.rounded(14),
        Border.width(1),
        Border.color(color_rgba(226, 238, 248, 60 / 255))
      ],
      column([center_x(), spacing(8)], [
        el([Font.size(12), Font.color(color(:white))], text(day)),
        el(
          [
            width(px(58)),
            height(px(58)),
            padding(8),
            Background.color(icon_glow),
            Border.rounded(999)
          ],
          svg(
            [width(fill()), height(fill()), image_fit(:contain)],
            AssetCatalog.weather_icon_source(kind)
          )
        ),
        el(
          [Font.size(11), Font.color(color_rgb(232, 238, 248))],
          text(weather_condition_label(kind))
        ),
        weather_temp_line("HI", high_c, accent),
        weather_temp_line("LO", low_c, color_rgb(214, 223, 236)),
        el(
          [
            padding_each(3, 8, 3, 8),
            Background.color(detail_bg),
            Border.rounded(999),
            Font.size(9),
            Font.color(color(:white))
          ],
          text("precip #{precip}")
        )
      ])
    )
  end

  defp weather_temp_line(label, temp_c, primary_color) do
    row([center_x(), spacing(6)], [
      el([Font.size(9), Font.color(dim_text())], text(label)),
      el([Font.size(15), Font.color(primary_color)], text("#{temp_c}C")),
      el(
        [Font.size(11), Font.color(color_rgb(218, 226, 239))],
        text("#{celsius_to_fahrenheit(temp_c)}F")
      )
    ])
  end

  defp weather_badge(label, bg_color) do
    el(
      [
        padding_each(4, 8, 4, 8),
        Background.color(bg_color),
        Border.rounded(999),
        Font.size(10),
        Font.color(color(:white))
      ],
      text(label)
    )
  end

  defp weather_condition_label(:sun), do: "Sunny"
  defp weather_condition_label(:cloud), do: "Cloudy"
  defp weather_condition_label(:rain), do: "Rain"

  defp weather_icon_tone(:sun) do
    {
      color_rgba(255, 209, 102, 34 / 255),
      color_rgb(255, 215, 110),
      color_rgba(102, 74, 18, 170 / 255)
    }
  end

  defp weather_icon_tone(:cloud) do
    {
      color_rgba(198, 212, 233, 34 / 255),
      color_rgb(224, 232, 243),
      color_rgba(65, 84, 108, 170 / 255)
    }
  end

  defp weather_icon_tone(:rain) do
    {
      color_rgba(110, 198, 255, 34 / 255),
      color_rgb(136, 224, 255),
      color_rgba(32, 88, 114, 175 / 255)
    }
  end

  defp svg_weather_scale_showcase(specs) do
    centered_wrapped_cards(
      Enum.map(specs, fn {label, note, source} -> svg_weather_scale_card(label, note, source) end),
      960
    )
  end

  defp svg_weather_scale_card(label, note, source) do
    sizes = [24, 48, 80]

    el(
      [
        width(px(300)),
        padding(12),
        spacing(10),
        Background.color(dark_card_bg()),
        Border.rounded(12)
      ],
      column([spacing(10)], [
        row([width(fill()), spacing(8)], [
          el([width(fill()), Font.size(12), Font.color(color(:white))], text(label)),
          weather_badge("SVG", color_rgba(66, 89, 122, 170 / 255))
        ]),
        paragraph([width(fill()), spacing(3), Font.size(10), Font.color(dim_text())], [
          text(note)
        ]),
        row(
          [width(fill()), spacing(8)],
          Enum.map(sizes, fn size ->
            el(
              [
                width(px(86)),
                height(px(118)),
                padding(8),
                Background.color(dark_panel_bg()),
                Border.rounded(10)
              ],
              column([center_x(), center_y(), spacing(8)], [
                svg([width(px(size)), height(px(size)), image_fit(:contain)], source),
                el(
                  [Font.size(10), Font.color(color_rgb(213, 219, 234))],
                  text("#{size}px")
                )
              ])
            )
          end)
        )
      ])
    )
  end

  defp svg_tint_showcase(source, multicolor_source) do
    cards = [
      {"Original", "svg/2 keeps the source stroke color when no tint is set.", nil, "default"},
      {"White tint", "Template tint turns every visible pixel white.", :white,
       "Svg.color(:white)"},
      {"Cyan tint", "Same icon, now themed for cool accents and status states.",
       color_rgb(110, 198, 255), "Svg.color(cyan)"},
      {"Amber tint", "Warm tint for highlights, alerts, and seasonal accents.",
       color_rgb(255, 209, 102), "Svg.color(amber)"}
    ]

    column([spacing(12)], [
      centered_wrapped_cards(
        Enum.map(cards, fn {label, note, tint, tint_label} ->
          svg_tint_card(source, label, note, tint, tint_label)
        end),
        960
      ),
      paragraph([width(fill()), spacing(3), Font.size(11), Font.color(dim_text())], [
        text(
          "Tint also overrides multicolor SVGs, so illustrations and logos flatten into one themed silhouette when Svg.color/1 is set."
        )
      ]),
      centered_wrapped_cards(
        [
          svg_tint_card(
            multicolor_source,
            "Multicolor original",
            "The source keeps its four quadrant colors when rendered without tint.",
            nil,
            "tile_quad.svg"
          ),
          svg_tint_card(
            multicolor_source,
            "Multicolor tinted",
            "A single tint overrides all visible colors while preserving the alpha edges.",
            color_rgb(110, 198, 255),
            "Svg.color(cyan)"
          )
        ],
        960
      )
    ])
  end

  defp svg_tint_card(source, label, note, tint, tint_label) do
    cyan_tint = color_rgb(110, 198, 255)
    amber_tint = color_rgb(255, 209, 102)

    svg_attrs =
      [width(px(72)), height(px(72)), image_fit(:contain)] ++
        if(tint, do: [Svg.color(tint)], else: [])

    badge_tone =
      case tint do
        nil -> color_rgba(80, 98, 122, 150 / 255)
        :white -> color_rgba(110, 116, 132, 180 / 255)
        ^cyan_tint -> color_rgba(52, 124, 170, 185 / 255)
        ^amber_tint -> color_rgba(138, 96, 28, 190 / 255)
      end

    el(
      [
        width(px(228)),
        padding(12),
        spacing(10),
        Background.color(color_rgb(46, 48, 72)),
        Border.rounded(12)
      ],
      column([spacing(10)], [
        row([width(fill()), spacing(8)], [
          el([width(fill()), Font.size(12), Font.color(color(:white))], text(label)),
          weather_badge("svg/2", badge_tone)
        ]),
        paragraph([width(fill()), spacing(3), Font.size(10), Font.color(dim_text())], [text(note)]),
        el(
          [
            center_x(),
            width(px(132)),
            height(px(120)),
            Background.color(color_rgb(28, 31, 46)),
            Border.width(1),
            Border.color(color_rgba(214, 220, 236, 90 / 255)),
            Border.rounded(12)
          ],
          el([center_x(), center_y()], svg(svg_attrs, source))
        ),
        el(
          [Font.size(10), Font.color(color_rgb(213, 219, 234))],
          text(tint_label)
        )
      ])
    )
  end

  defp asset_behavior_preview({:image, source, fit, mode_label}) do
    el(
      [
        width(fill()),
        height(fill()),
        Border.width(1),
        Border.color(color_rgba(214, 220, 236, 220 / 255)),
        Border.rounded(8),
        Nearby.in_front(asset_preview_mode_badge(mode_label))
      ],
      image([width(fill()), height(fill()), image_fit(fit)], source)
    )
  end

  defp asset_behavior_preview({:svg, source, fit, mode_label}) do
    el(
      [
        width(fill()),
        height(fill()),
        Border.width(1),
        Border.color(color_rgba(214, 220, 236, 220 / 255)),
        Border.rounded(8),
        Nearby.in_front(asset_preview_mode_badge(mode_label))
      ],
      svg([width(fill()), height(fill()), image_fit(fit)], source)
    )
  end

  defp asset_behavior_preview({:background, bg_attr, mode_label}) do
    el(
      [
        width(fill()),
        height(fill()),
        bg_attr,
        Border.width(1),
        Border.color(color_rgba(214, 220, 236, 220 / 255)),
        Border.rounded(8),
        Nearby.in_front(asset_preview_mode_badge(mode_label))
      ],
      none()
    )
  end

  defp asset_preview_mode_badge(label) do
    el(
      [
        align_right(),
        align_bottom(),
        Transform.move_x(-6),
        Transform.move_y(-6),
        padding_each(2, 6, 2, 6),
        Background.color(color_rgba(0, 0, 0, 165 / 255)),
        Border.rounded(4),
        Font.size(9),
        Font.color(color(:white))
      ],
      text(label)
    )
  end

  defp source_status_chip(label, tone) do
    bg_color =
      case tone do
        :source -> color_rgb(58, 98, 158)
        :runtime -> color_rgb(48, 120, 102)
        :blocked -> color_rgb(150, 77, 83)
        :background -> color_rgb(92, 80, 164)
        :helper -> color_rgb(88, 92, 124)
        :font_builtin -> color_rgb(84, 106, 94)
        :font -> color_rgb(132, 86, 54)
        :synthetic -> color_rgb(118, 74, 120)
      end

    el(
      [
        padding_each(2, 8, 2, 8),
        Background.color(bg_color),
        Border.rounded(999),
        Font.size(10),
        Font.color(color(:white))
      ],
      text(label)
    )
  end

  defp fit_demo_card(api_label, frame_label, {frame_w, frame_h}, fit, variant, source) do
    stage_padding = 10
    stage_w = frame_w + stage_padding * 2
    stage_h = frame_h + stage_padding * 2
    card_w = Kernel.max(stage_w + 20, 220)

    el(
      [
        width(px(card_w)),
        padding(10),
        spacing(8),
        Background.color(color_rgb(45, 45, 68)),
        Border.rounded(10)
      ],
      column([spacing(8)], [
        row([width(fill()), spacing(8)], [
          el([Font.size(11), Font.color(color(:white))], text(api_label)),
          fit_chip(fit)
        ]),
        el([Font.size(10), Font.color(dim_text())], text(frame_label)),
        el(
          [Font.size(10), Font.color(color_rgb(184, 188, 210))],
          text("#{frame_w}x#{frame_h}")
        ),
        el(
          [
            center_x(),
            width(px(stage_w)),
            height(px(stage_h)),
            Background.color(color_rgb(31, 31, 45)),
            Border.rounded(8)
          ],
          fit_demo_preview(variant, source, fit, {frame_w, frame_h})
        )
      ])
    )
  end

  defp fit_demo_preview(:image, source, fit, {frame_w, frame_h}) do
    el(
      [
        center_x(),
        center_y(),
        width(px(frame_w)),
        height(px(frame_h)),
        Background.color(color_rgb(24, 24, 36)),
        Border.width(1),
        Border.color(color_rgba(214, 220, 236, 220 / 255)),
        Border.rounded(8)
      ],
      image([width(fill()), height(fill()), image_fit(fit)], source)
    )
  end

  defp fit_demo_preview(:svg, source, fit, {frame_w, frame_h}) do
    el(
      [
        center_x(),
        center_y(),
        width(px(frame_w)),
        height(px(frame_h)),
        Background.color(color_rgb(24, 24, 36)),
        Border.width(1),
        Border.color(color_rgba(214, 220, 236, 220 / 255)),
        Border.rounded(8)
      ],
      svg([width(fill()), height(fill()), image_fit(fit)], source)
    )
  end

  defp fit_demo_preview(:background, source, fit, {frame_w, frame_h}) do
    el(
      [
        center_x(),
        center_y(),
        width(px(frame_w)),
        height(px(frame_h)),
        Background.image(source, fit: fit),
        Border.width(1),
        Border.color(color_rgba(214, 220, 236, 220 / 255)),
        Border.rounded(8)
      ],
      el(
        [
          center_x(),
          center_y(),
          padding(5),
          Background.color(color_rgba(0, 0, 0, 160 / 255)),
          Border.rounded(5),
          Font.size(10),
          Font.color(color(:white))
        ],
        text("bg")
      )
    )
  end

  defp fit_chip(:contain) do
    el(
      [
        padding(4),
        Background.color(color_rgb(52, 110, 124)),
        Border.rounded(6),
        Font.size(10),
        Font.color(color(:white))
      ],
      text("contain")
    )
  end

  defp fit_chip(:cover) do
    el(
      [
        padding(4),
        Background.color(color_rgb(142, 84, 52)),
        Border.rounded(6),
        Font.size(10),
        Font.color(color(:white))
      ],
      text("cover")
    )
  end

  defp fit_legend do
    column([spacing(4)], [
      el([Font.size(11), Font.color(color_rgb(200, 210, 222))], text("Fit legend")),
      el(
        [Font.size(10), Font.color(dim_text())],
        text("contain: full image visible, may letterbox")
      ),
      el([Font.size(10), Font.color(dim_text())], text("cover: frame fully filled, may crop"))
    ])
  end

  defp demo_policy_card do
    el(
      [
        width(fill()),
        padding(12),
        spacing(8),
        Background.color(color_rgb(48, 48, 72)),
        Border.rounded(10)
      ],
      column([spacing(6)], [
        el([Font.size(12), Font.color(color(:white))], text("Renderer asset policy")),
        el(
          [Font.size(11), Font.color(dim_text())],
          text("async asset loading + loading/failed placeholders")
        ),
        paragraph([width(fill()), spacing(3), Font.size(11), Font.color(dim_text())], [
          text("runtime allowlist: priv/demo_images")
        ]),
        paragraph([width(fill()), spacing(3), Font.size(11), Font.color(dim_text())], [
          text("font asset: #{AssetCatalog.lobster_font_path()}")
        ])
      ])
    )
  end

  defp celsius_to_fahrenheit(temp_c) do
    round(temp_c * 9 / 5 + 32)
  end

  # Code previews

  defp assets_overview_code do
    ~S"""
    image([width(px(120)), height(px(120)), Border.rounded(10)], ~m"demo_images/static.jpg")

    el([
      width(px(288)),
      height(px(160)),
      Background.image(~m"demo_images/fallback.jpg", fit: :cover)
    ], none())
    """
  end

  defp svg_weather_code do
    ~S"""
    wrapped_row([], Enum.map(days, fn day ->
      column([], [
        svg([width(px(58)), height(px(58)), image_fit(:contain)], weather_icon_source(day.kind)),
        text(day.day)
      ])
    end))
    """
  end

  defp svg_scaling_code do
    ~S"""
    Enum.map([24, 48, 80], fn size ->
      svg([width(px(size)), height(px(size)), image_fit(:contain)], ~m"demo_images/weather_sun.svg")
    end)
    """
  end

  defp svg_tint_code do
    ~S"""
    svg([width(px(72)), height(px(72))], ~m"demo_images/template_cloud.svg")

    svg(
      [width(px(72)), height(px(72)), Svg.color(color(:sky, 500))],
      ~m"demo_images/template_cloud.svg"
    )
    """
  end

  defp source_cards_code do
    ~S"""
    image([width(px(160)), height(px(120))], ~m"demo_images/static.jpg")
    image([width(px(160)), height(px(120))], {:path, runtime_path})
    svg([width(px(80)), height(px(80))], ~m"demo_images/weather_sun.svg")
    image([width(px(160)), height(px(120))], {:path, blocked_path})
    """
  end

  defp font_cards_code do
    ~S"""
    el([Font.family("lobster-demo"), Font.size(22)], text("Asset Fonts 123"))
    el([Font.family("lobster-demo"), Font.bold(), Font.italic()], text("Synthetic style"))
    """
  end

  defp image_fit_code do
    ~S"""
    image([width(fill()), height(fill()), image_fit(:contain)], ~m"demo_images/static.jpg")
    image([width(fill()), height(fill()), image_fit(:cover)], ~m"demo_images/static.jpg")
    """
  end

  defp background_helpers_code do
    ~S"""
    Background.image(~m"demo_images/tile_bird_small.jpg")
    Background.uncropped(~m"demo_images/tile_bird_small.jpg")
    Background.tiled(~m"demo_images/tile_bird_small.jpg")
    Background.tiled_x(~m"demo_images/tile_bird_small.jpg")
    Background.tiled_y(~m"demo_images/tile_bird_small.jpg")
    """
  end

  defp background_fit_code do
    ~S"""
    el([
      width(px(280)),
      height(px(120)),
      Background.image(~m"demo_images/static.jpg", fit: :contain)
    ], none())

    el([
      width(px(280)),
      height(px(120)),
      Background.image(~m"demo_images/static.jpg", fit: :cover)
    ], none())
    """
  end

  defp demo_policy_code do
    ~S"""
    emerge_skia: [
      otp_app: :emerge_demo,
      assets: [
        fonts: [[family: "lobster-demo", source: ~m"demo_fonts/Lobster-Regular.ttf", weight: 400]],
        runtime_paths: [enabled: true, allowlist: [runtime_allowlist_root]]
      ]
    ]
    """
  end

  # Generic elements

  defp assets_example(title, note, example_id, code, content) do
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

  # Palette

  defp title_text, do: color_rgb(24, 30, 38)
  defp body_text, do: color_rgb(92, 100, 114)
  defp dark_card_bg, do: color_rgb(50, 50, 74)
  defp dark_panel_bg, do: color_rgb(34, 34, 50)
  defp dim_text, do: color_rgb(191, 199, 222)
end
