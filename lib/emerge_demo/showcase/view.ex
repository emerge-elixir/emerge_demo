defmodule EmergeDemo.Showcase.View do
  use Emerge.UI
  use Solve.Lookup, :helpers

  alias EmergeDemo.Showcase

  alias EmergeDemo.Showcase.View.{
    Assets,
    Borders,
    Interaction,
    Keys,
    Layout,
    Scroll,
    Text,
    VideoInterop
  }

  alias EmergeDemo.Showcase.View.Nearby, as: NearbyPage
  alias EmergeDemo.Showcase.View.Animation, as: AnimationPage

  # Domain composition and state wiring

  def layout(video_targets \\ nil) do
    pages = solve(Showcase.App, :pages)

    el(
      [
        width(fill()),
        height(fill()),
        Background.color(page_bg())
      ],
      column(
        [
          width(fill()),
          height(fill())
        ],
        [
          page_header(pages),
          active_page(pages, video_targets)
        ]
      )
    )
  end

  defp page_header(pages) do
    column([padding_xy(24, 16), width(fill()), spacing(14)], [
      # Leave space on the left for AppSelector's overlaid 40px menu button.
      el(
        [width(fill()), height(px(40)), padding_each(0, 0, 0, 48)],
        el([center_y(), Font.size(26), Font.bold(), Font.color(title_text())], text("Showcase"))
      ),
      page_nav(pages)
    ])
  end

  defp active_page(%{current: current} = pages, video_targets) do
    el(
      [padding_each(0, 20, 20, 20), width(fill()), height(fill())],
      el(
        [
          key(current),
          scrollbar_y(),
          width(fill()),
          height(fill()),
          padding(28),
          Background.color(surface_bg()),
          Border.rounded(12)
        ],
        column([width(min(px(1500), fill())), center_x(), spacing(28)], [
          column([width(fill()), spacing(12)], [
            el(
              [Font.size(34), Font.bold(), Font.color(title_text())],
              text(current_page_label(pages))
            ),
            paragraph([width(fill()), spacing(5), Font.size(16), Font.color(body_text())], [
              text(current_page_summary(current))
            ]),
            paragraph([width(fill()), Font.size(12), Font.color(body_text())], [
              text(
                "Snippets focus on the API; surrounding styling and helper definitions are omitted."
              )
            ])
          ]),
          page_content(current, video_targets)
        ])
      )
    )
  end

  defp page_content(current, video_targets) do
    case current do
      :layout -> Layout.layout()
      :text -> Text.layout()
      :assets -> Assets.layout()
      :borders -> Borders.layout()
      :nearby -> NearbyPage.layout()
      :scroll -> Scroll.layout()
      :keys -> Keys.layout()
      :interaction -> Interaction.layout()
      :animation -> AnimationPage.layout()
      :video_interop -> VideoInterop.layout(video_targets)
      _other -> none()
    end
  end

  defp current_page_label(%{current: current, pages: pages}) do
    case Enum.find(pages, &(&1.id == current)) do
      %{label: label} -> label
      nil -> "Showcase"
    end
  end

  defp current_page_summary(:layout) do
    "Layout examples showing content and fill sizing, constraints, spacing, alignment, and transforms. Each snippet sits beside the layout it describes."
  end

  defp current_page_summary(:text) do
    "Text examples covering inherited fonts, child overrides, styled spans, paragraphs, and documents within the same tree model."
  end

  defp current_page_summary(:assets) do
    "Images, SVGs, and fonts loaded from application assets and runtime paths. The examples show source resolution, sizing, tinting, and renderer configuration."
  end

  defp current_page_summary(:borders) do
    "Border strokes, rounded corners, shadows, and their combinations. Border widths occupy layout space; shadows only affect painting."
  end

  defp current_page_summary(:nearby) do
    "Nearby overlays attach to a host without occupying another layout slot. These examples show placement, layering, and clipping outside the normal flow."
  end

  defp current_page_summary(:scroll) do
    "Bounded viewports with vertical, horizontal, and two-axis scrolling, including oversized content and nested panels."
  end

  defp current_page_summary(:keys) do
    "Explicit keys retain element identity across list changes. These examples compare positional and keyed reuse for scroll state and focused inputs."
  end

  defp current_page_summary(:interaction) do
    "Pointer styling, event handlers, controlled inputs, and keyboard actions. The examples distinguish local visual states from state managed by Solve controllers."
  end

  defp current_page_summary(:animation) do
    "Animated value changes, content sizing, element entry and exit, and repeating sequences. The examples include expanding labels, highlights, panels, and notifications."
  end

  defp current_page_summary(:video_interop) do
    "A video element identifies where frames appear; a producer supplies them. Five examples connect owned CPU pixels and leased GPU buffers to the same viewport."
  end

  defp current_page_summary(_page), do: "Examples with their corresponding Elixir snippets."

  defp page_nav(pages) do
    wrapped_row(
      [padding_xy(0, 2), width(fill()), spacing(10)],
      Enum.map(pages.pages, fn page ->
        page_tab(
          page.id == pages.current,
          page.label,
          event(pages, :set_page, page.id)
        )
      end)
    )
  end

  defp page_tab(active?, label, on_press) do
    Input.button(
      [
        Event.on_press(on_press),
        padding_each(8, 12, 8, 12),
        Background.color(if(active?, do: tab_active_bg(), else: tab_bg())),
        Border.rounded(8),
        Border.width(1),
        Border.color(if(active?, do: tab_active_border(), else: tab_border())),
        Font.size(14),
        Font.color(if(active?, do: tab_active_text(), else: tab_text())),
        Interactive.mouse_over([
          Background.color(if(active?, do: tab_active_bg(), else: tab_hover_bg())),
          Border.color(if(active?, do: tab_active_border(), else: tab_hover_border()))
        ]),
        Interactive.focused([
          Border.color(if(active?, do: tab_active_border(), else: tab_focus_border())),
          Border.glow(tab_focus_glow(), 2)
        ]),
        Interactive.mouse_down([Transform.move_y(1)])
      ],
      text(label)
    )
  end

  # Reusable attribute bundles and palette

  defp page_bg, do: color_rgb(243, 244, 247)
  defp surface_bg, do: color_rgb(255, 255, 255)
  defp title_text, do: color_rgb(22, 28, 36)
  defp body_text, do: color_rgb(92, 100, 114)
  defp tab_bg, do: color_rgb(255, 255, 255)
  defp tab_hover_bg, do: color_rgb(248, 249, 252)
  defp tab_active_bg, do: color_rgb(238, 243, 255)
  defp tab_border, do: color_rgb(218, 222, 231)
  defp tab_hover_border, do: color_rgb(194, 202, 220)
  defp tab_active_border, do: color_rgb(171, 188, 234)
  defp tab_focus_border, do: color_rgb(150, 169, 221)
  defp tab_focus_glow, do: color_rgba(116, 138, 210, 0.26)
  defp tab_text, do: color_rgb(98, 108, 126)
  defp tab_active_text, do: color_rgb(45, 70, 142)
end
