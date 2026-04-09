defmodule EmergeDemo.Showcase.View.CodeBlock do
  use Emerge.UI

  def layout(code) when is_binary(code) do
    column(code_block_attrs(), [
      el(code_label_attrs(), text("Code")),
      column(code_lines_attrs(), Enum.map(code_lines(code), &code_line/1))
    ])
  end

  defp code_line(content) do
    el(code_line_attrs(), text(if(content == "", do: " ", else: content)))
  end

  defp code_lines(code) do
    code
    |> String.trim()
    |> String.split("\n", trim: false)
  end

  defp code_block_attrs do
    [
      width(max(px(460), fill())),
      padding(12),
      spacing(10),
      Background.color(surface_bg()),
      Border.rounded(14),
      Border.width(1),
      Border.color(surface_line()),
      Border.shadow(offset: {0, 10}, blur: 30, size: 0, color: color_rgba(0, 0, 0, 0.2))
    ]
  end

  defp code_label_attrs do
    [Font.size(11), Font.color(label_text()), Font.bold()]
  end

  defp code_lines_attrs do
    [spacing(4)]
  end

  defp code_line_attrs do
    [Font.size(12), Font.color(code_text())]
  end

  defp surface_bg, do: color_rgb(28, 32, 43)
  defp surface_line, do: color_rgb(74, 82, 104)
  defp label_text, do: color_rgb(145, 160, 212)
  defp code_text, do: color_rgb(235, 239, 247)
end
