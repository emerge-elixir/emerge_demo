defmodule EmergeDemo.Showcase.View.CodeBlock do
  @moduledoc false

  use Emerge.UI

  @enforce_keys [:source, :tree]
  defstruct @enforce_keys

  # Snippets are literals so highlighting happens when the view compiles, not
  # every time an input, video status, or other controller updates the page.
  defmacro snippet(source) do
    source = Macro.expand(source, __CALLER__)

    unless is_binary(source) do
      raise ArgumentError, "CodeBlock.snippet/1 expects a literal source string"
    end

    Macro.escape(compile(source))
  end

  def compile(source) when is_binary(source) do
    source = source |> Code.format_string!(line_length: 48) |> IO.iodata_to_binary()

    %__MODULE__{
      source: source,
      tree:
        Makeup.highlight(source,
          formatter: Makeup.Formatters.Emerge,
          formatter_options: [
            style: :monokai_style,
            attrs: [padding(16), Border.rounded(10)],
            paragraph_attrs: [Font.family("monospace"), Font.size(13)]
          ]
        )
    }
  end

  def layout(%__MODULE__{tree: tree}), do: tree
end
