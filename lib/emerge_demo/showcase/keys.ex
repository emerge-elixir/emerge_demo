defmodule EmergeDemo.Showcase.Keys do
  @moduledoc false

  use Solve.Controller, events: [:rotate_scroll_items, :prepend_input_row]

  @impl true
  def init(_init_params, _dependencies) do
    %{
      scroll_items: initial_scroll_items(),
      input_rows: initial_input_rows(),
      next_input_row_id: 5
    }
  end

  def rotate_scroll_items(_payload, state) do
    %{state | scroll_items: rotate(state.scroll_items)}
  end

  def prepend_input_row(_payload, state) do
    row_id = state.next_input_row_id

    %{
      state
      | input_rows: [inserted_input_row(row_id) | state.input_rows],
        next_input_row_id: row_id + 1
    }
  end

  @impl true
  def expose(state, _dependencies, _init_params) do
    %{scroll_items: state.scroll_items, input_rows: state.input_rows}
  end

  defp rotate([]), do: []
  defp rotate([head | tail]), do: tail ++ [head]

  defp initial_scroll_items do
    [
      %{
        id: :alpha,
        label: "Alpha",
        children: ["Queue", "Pinned", "Recent", "Archived", "Notes", "History"]
      },
      %{
        id: :bravo,
        label: "Bravo",
        children: [
          "Draft 1",
          "Draft 2",
          "Draft 3",
          "Draft 4",
          "Draft 5",
          "Draft 6",
          "Draft 7",
          "Draft 8",
          "Draft 9"
        ]
      },
      %{
        id: :charlie,
        label: "Charlie",
        children: ["Inbox", "Urgent", "Waiting", "Someday"]
      },
      %{
        id: :delta,
        label: "Delta",
        children: [
          "Alpha pass",
          "Bravo pass",
          "Charlie pass",
          "Delta pass",
          "Echo pass",
          "Foxtrot pass",
          "Golf pass",
          "Hotel pass",
          "India pass",
          "Juliet pass",
          "Kilo pass"
        ]
      }
    ]
  end

  defp initial_input_rows do
    [
      %{id: 1, label: "Alpha", value: "alpha draft"},
      %{id: 2, label: "Bravo", value: "bravo draft"},
      %{id: 3, label: "Charlie", value: "charlie draft"},
      %{id: 4, label: "Delta", value: "delta draft"}
    ]
  end

  defp inserted_input_row(row_id) do
    %{
      id: row_id,
      label: "Inserted #{row_id}",
      value: "inserted draft #{row_id}"
    }
  end
end
