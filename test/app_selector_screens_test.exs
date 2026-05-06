defmodule EmergeDemo.AppSelector.ScreensTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.AppSelector.Screens

  test "exposes todo and showcase screens" do
    state = Screens.init(%{}, %{})

    assert %{
             current: :todo,
             menu_open?: false,
             rotate: rotate,
             rotate_options: rotate_options,
             scale: 1.0,
             scale_options: scale_options,
             screens: screens
           } =
             Screens.expose(state, %{}, %{})

    assert screens == [
             %{id: :todo, label: "Todo"},
             %{id: :showcase, label: "Showcase"}
           ]

    assert rotate == 0.0

    assert scale_options == [
             %{value: 1.0, label: "100%"},
             %{value: 1.25, label: "125%"},
             %{value: 1.5, label: "150%"}
           ]

    assert rotate_options == [
             %{value: 0.0, label: "0"},
             %{value: 90.0, label: "90"},
             %{value: 180.0, label: "180"},
             %{value: 270.0, label: "270"}
           ]
  end

  test "set_screen switches to showcase and closes the menu" do
    state = %{current: :todo, menu_open?: true}

    assert %{current: :showcase, menu_open?: false} = Screens.set_screen(:showcase, state)
  end

  test "set_scale updates supported app scale without closing the menu" do
    state = %{current: :todo, menu_open?: true, scale: 1.0}

    assert %{scale: 1.25, menu_open?: true} = Screens.set_scale(1.25, state)
  end

  test "set_scale ignores unsupported values" do
    state = %{current: :todo, menu_open?: true, scale: 1.0}

    assert %{scale: 1.0, menu_open?: true} = Screens.set_scale(2.0, state)
  end

  test "set_rotate updates supported app rotation without closing the menu" do
    state = %{current: :todo, menu_open?: true, rotate: 0.0}

    assert %{rotate: 90.0, menu_open?: true} = Screens.set_rotate(90.0, state)
  end

  test "set_rotate ignores unsupported values" do
    state = %{current: :todo, menu_open?: true, rotate: 0.0}

    updated = Screens.set_rotate(45.0, state)

    assert updated.rotate == 0.0
    assert updated.menu_open?
  end
end
