defmodule EmergeDemo.Showcase.InputButtonTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.InputButton

  test "pressed increments the press count" do
    state = InputButton.init(%{}, %{})
    pressed = InputButton.pressed(nil, state)

    assert %{press_count: 1} = InputButton.expose(pressed, %{}, %{})
  end

  test "focused and blurred update counts and clear popup" do
    state = InputButton.init(%{}, %{})

    focused =
      InputButton.focused(nil, state, %{}, %{
        clear_popup: fn -> send(self(), :clear_popup) end
      })

    blurred =
      InputButton.blurred(nil, focused, %{}, %{
        clear_popup: fn -> send(self(), :clear_popup) end
      })

    assert %{focused?: true, focus_count: 1, blur_count: 0} =
             InputButton.expose(focused, %{}, %{})

    assert %{focused?: false, focus_count: 1, blur_count: 1} =
             InputButton.expose(blurred, %{}, %{})

    assert_received :clear_popup
    assert_received :clear_popup
  end
end
