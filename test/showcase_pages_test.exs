defmodule EmergeDemo.Showcase.PagesTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.Pages

  test "exposes layout, text, assets, borders, nearby, scroll, keys, and interaction pages" do
    state = Pages.init(%{}, %{})

    assert %{current: :layout, pages: pages} = Pages.expose(state, %{}, %{})

    assert pages == [
             %{id: :layout, label: "Layout"},
             %{id: :text, label: "Text"},
             %{id: :assets, label: "Assets"},
             %{id: :borders, label: "Borders"},
             %{id: :nearby, label: "Nearby"},
             %{id: :scroll, label: "Scroll"},
             %{id: :keys, label: "Keys"},
             %{id: :interaction, label: "Interaction"}
           ]
  end

  test "set_page switches to assets" do
    state = %{current: :layout}

    assert %{current: :assets} = Pages.set_page(:assets, state)
  end

  test "set_page ignores invalid page ids" do
    state = %{current: :layout}

    assert %{current: :layout} = Pages.set_page(:unknown, state)
  end
end
