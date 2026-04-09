defmodule EmergeDemo.Showcase.View do
  use Emerge.UI
  use Solve.Lookup, :helpers

  alias EmergeDemo.Showcase

  alias EmergeDemo.Showcase.View.{
    Assets,
    Borders,
    CodeBlock,
    Interaction,
    Keys,
    Layout,
    Scroll,
    Text
  }

  alias EmergeDemo.Showcase.View.Nearby, as: NearbyPage

  # Domain composition and state wiring

  def layout do
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
          active_page(pages)
        ]
      )
    )
  end

  defp page_header(pages) do
    column([padding(16), width(fill()), spacing(12)], [
      row([width(fill()), padding_each(0, 0, 0, 50)], [
        el(
          [
            width(fill()),
            Font.size(36),
            Font.color(accent_text()),
            Font.bold()
          ],
          text("Showcase")
        ),
        el(
          [
            align_bottom(),
            padding_each(6, 10, 6, 10),
            Background.color(color_rgb(238, 243, 255)),
            Border.rounded(999),
            Font.size(12),
            Font.color(body_text())
          ],
          text("Hover code blocks are simplified")
        )
      ]),
      page_nav(pages),
      column([padding_xy(6, 0)], [
        el([Font.size(40), Font.color(title_text())], text(current_page_label(pages))),
        paragraph([width(fill()), spacing(3), Font.size(14), Font.color(body_text())], [
          text(current_page_summary(pages.current))
        ])
      ])
    ])
  end

  def hover_example(example_id, code, content) do
    code_hover = solve(Showcase.App, :code_hover)

    el(
      [
        width(fill()),
        Event.on_mouse_enter(event(code_hover, :show, example_id)),
        Event.on_mouse_leave(event(code_hover, :hide, example_id)),
        Emerge.UI.Nearby.above(code_preview(code_hover, example_id, code))
      ],
      content
    )
  end

  defp active_page(%{current: current}) do
    el(
      [padding(16), width(fill()), height(fill())],
      el(
        [
          scrollbar_y(),
          width(fill()),
          height(fill()),
          padding(24),
          Background.color(surface_bg()),
          Border.rounded(24),
          Border.shadow(offset: {0, 16}, blur: 40, size: 0, color: color_rgba(0, 0, 0, 0.08))
        ],
        case current do
          :layout -> Layout.layout()
          :text -> Text.layout()
          :assets -> Assets.layout()
          :borders -> Borders.layout()
          :nearby -> NearbyPage.layout()
          :scroll -> Scroll.layout()
          :keys -> Keys.layout()
          :interaction -> Interaction.layout()
          _other -> none()
        end
      )
    )
  end

  defp current_page_label(%{current: current, pages: pages}) do
    case Enum.find(pages, &(&1.id == current)) do
      %{label: label} -> label
      nil -> "Showcase"
    end
  end

  defp current_page_summary(:layout) do
    "Resize the window to observe how sizing, spacing, wrapping, alignment, and paint-time transforms change across the same layout primitives. Hover an example to inspect the code."
  end

  defp current_page_summary(:assets) do
    "Compare logical assets from priv, allowlisted runtime paths, blocked runtime sources, startup font assets, SVG tinting, and contain/cover fit behavior. Hover an example to inspect the code."
  end

  defp current_page_summary(:scroll) do
    "Resize the window and scroll inside the panels to compare vertical, horizontal, both-axis, and nested overflow behavior. Hover an example to inspect the code."
  end

  defp current_page_summary(:keys) do
    "Reorder sibling cards and prepend focused inputs to compare how scrollbars, focus, and live edit state follow slots without keys and logical items with keys. Hover an example to inspect the code."
  end

  defp current_page_summary(:text) do
    "Compare font inheritance, decoration, wrapped paragraphs, document flow, and floated text blocks. Resize the page to observe how copy reflows. Hover an example to inspect the code."
  end

  defp current_page_summary(:borders) do
    "Compare border styles, pill radii, per-edge widths, and decorative shadows. Resize the page to observe how the recipe cards wrap. Hover an example to inspect the code."
  end

  defp current_page_summary(:nearby) do
    "Attach overlays that escape normal layout while staying anchored to a host. Compare slot positioning, escape behavior, sibling precedence, and clip_nearby(). Hover an example to inspect the code. Elemnts escaping when scrolling is not a bug, see clip_nearby example at the end."
  end

  defp current_page_summary(:interaction) do
    "Compare decorative pointer states with swipe gestures, transformed hit testing, text input, buttons, focused key listeners, and virtual keys. Hover and interact with the demos to inspect the code."
  end

  defp current_page_summary(_page) do
    "Resize the window and interact with the examples to inspect how the layout behaves. Hover an example to inspect the code."
  end

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
        Border.rounded(999),
        Border.width(1),
        Border.color(if(active?, do: tab_active_border(), else: tab_border())),
        Font.size(13),
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

  defp code_preview(%{active: example_id}, example_id, code) do
    el(
      [
        width(fill()),
        align_left(),
        padding_each(0, 0, 10, 0)
      ],
      CodeBlock.layout(code)
    )
  end

  defp code_preview(_code_hover, _example_id, _code), do: none()

  defp page_bg, do: color_rgb(243, 244, 247)
  defp surface_bg, do: color_rgb(255, 255, 255)
  defp title_text, do: color_rgb(22, 28, 36)
  defp body_text, do: color_rgb(92, 100, 114)
  defp accent_text, do: color_rgb(72, 96, 168)
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
