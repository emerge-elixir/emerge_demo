defmodule EmergeDemo.AppSelector.ScreensTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.AppSelector.Screens

  test "exposes todo and showcase screens" do
    state = Screens.init(%{}, %{})

    assert %{current: :todo, menu_open?: false, screens: screens} =
             Screens.expose(state, %{}, %{})

    assert screens == [
             %{id: :todo, label: "Todo"},
             %{id: :showcase, label: "Showcase"}
           ]
  end

  test "set_screen switches to showcase and closes the menu" do
    state = %{current: :todo, menu_open?: true}

    assert %{current: :showcase, menu_open?: false} = Screens.set_screen(:showcase, state)
  end
end
