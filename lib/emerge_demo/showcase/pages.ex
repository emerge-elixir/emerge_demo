defmodule EmergeDemo.Showcase.Pages do
  @moduledoc false

  use Solve.Controller, events: [:set_page]

  @pages [
    %{id: :layout, label: "Layout"},
    %{id: :text, label: "Text"},
    %{id: :assets, label: "Assets"},
    %{id: :borders, label: "Borders"},
    %{id: :nearby, label: "Nearby"},
    %{id: :scroll, label: "Scroll"},
    %{id: :keys, label: "Keys"},
    %{id: :interaction, label: "Interaction"}
  ]
  @page_ids Enum.map(@pages, & &1.id)

  @impl true
  def init(_init_params, _dependencies) do
    %{current: :layout}
  end

  def set_page(page_id, state) when page_id in @page_ids do
    %{state | current: page_id}
  end

  def set_page(_other_page_id, state), do: state

  @impl true
  def expose(state, _dependencies, _init_params) do
    %{current: state.current, pages: @pages}
  end
end
