defmodule EmergeDemo.Showcase.PagesTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.Pages

  test "exposes showcase pages including Video Interop" do
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
             %{id: :interaction, label: "Interaction"},
             %{id: :video_interop, label: "Video Interop"}
           ]
  end

  test "set_page switches to Video Interop" do
    state = %{current: :layout}

    assert %{current: :video_interop} = Pages.set_page(:video_interop, state)
  end

  test "set_page ignores invalid page ids" do
    state = %{current: :layout}

    assert %{current: :layout} = Pages.set_page(:unknown, state)
  end
end
