defmodule EmergeDemo.Showcase.View.Example do
  @moduledoc false

  use Emerge.UI

  alias EmergeDemo.Showcase.View.CodeBlock

  def layout(title, explanation, id, %CodeBlock{} = code, demo, opts \\ []) do
    controls = Keyword.get(opts, :controls, none())

    {container, code_width, demo_width} =
      case Keyword.get(opts, :direction, :row) do
        :row -> {&row/2, fill(2), fill(3)}
        :column -> {&column/2, fill(), fill()}
      end

    el(
      [width(fill())],
      column([key(id), width(fill()), spacing(12)], [
        el([width(fill()), Font.size(20), Font.bold(), Font.color(ink())], text(title)),
        prose(explanation),
        el(
          [width(fill()), scrollbar_x(), padding_each(0, 0, 8, 0)],
          container.([width(max(px(1120), fill())), spacing(24)], [
            el([width(code_width)], CodeBlock.layout(code)),
            column([width(demo_width), spacing(12)], [demo, controls])
          ])
        )
      ])
    )
  end

  # Keep comparisons in explicit rows beside the code, rather than allowing a
  # narrow preview to split a pair across separate wrapping lines.
  def comparison_rows(items, count \\ 2) do
    column(
      [width(fill()), spacing(12)],
      items
      |> Enum.chunk_every(count)
      |> Enum.map(&row([width(fill()), spacing(12)], &1))
    )
  end

  def heading(label) do
    el(
      [width(fill()), padding_each(12, 0, 0, 0), Font.size(26), Font.bold(), Font.color(ink())],
      text(label)
    )
  end

  def prose(content) do
    paragraph([width(fill()), spacing(5), Font.size(15), Font.color(color_rgb(80, 89, 105))], [
      text(content)
    ])
  end

  defp ink, do: color_rgb(28, 38, 60)
end
