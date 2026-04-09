defmodule EmergeDemo.Showcase.KeysTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.Keys

  test "expose returns the initial scroll cards and input rows" do
    state = Keys.init(%{}, %{})

    assert %{scroll_items: scroll_items, input_rows: input_rows} = Keys.expose(state, %{}, %{})
    assert Enum.map(scroll_items, & &1.label) == ["Alpha", "Bravo", "Charlie", "Delta"]
    assert Enum.map(input_rows, & &1.label) == ["Alpha", "Bravo", "Charlie", "Delta"]
  end

  test "rotate_scroll_items rotates only the outer scroll cards" do
    state = Keys.init(%{}, %{})

    rotated = Keys.rotate_scroll_items(nil, state)

    assert %{scroll_items: scroll_items, input_rows: input_rows} = Keys.expose(rotated, %{}, %{})
    assert Enum.map(scroll_items, & &1.label) == ["Bravo", "Charlie", "Delta", "Alpha"]
    assert Enum.map(input_rows, & &1.label) == ["Alpha", "Bravo", "Charlie", "Delta"]

    assert Enum.find(scroll_items, &(&1.label == "Bravo")).children == [
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
  end

  test "prepend_input_row inserts a new row at the front and increments ids" do
    state = Keys.init(%{}, %{})

    prepended = Keys.prepend_input_row(nil, state)
    prepended_again = Keys.prepend_input_row(nil, prepended)

    assert %{input_rows: input_rows} = Keys.expose(prepended_again, %{}, %{})

    assert Enum.take(Enum.map(input_rows, & &1.label), 3) == ["Inserted 6", "Inserted 5", "Alpha"]

    assert Enum.take(Enum.map(input_rows, & &1.value), 2) == [
             "inserted draft 6",
             "inserted draft 5"
           ]
  end
end
