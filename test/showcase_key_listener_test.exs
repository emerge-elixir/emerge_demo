defmodule EmergeDemo.Showcase.KeyListenerTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.KeyListener

  test "focused and blurred update state and clear popup" do
    state = KeyListener.init(%{}, %{})

    focused =
      KeyListener.focused(nil, state, %{}, %{
        clear_popup: fn -> send(self(), :clear_popup) end
      })

    blurred =
      KeyListener.blurred(nil, focused, %{}, %{
        clear_popup: fn -> send(self(), :clear_popup) end
      })

    assert %{focused?: true, focus_count: 1, blur_count: 0} =
             KeyListener.expose(focused, %{}, %{})

    assert %{focused?: false, focus_count: 1, blur_count: 1} =
             KeyListener.expose(blurred, %{}, %{})

    assert_received :clear_popup
    assert_received :clear_popup
  end

  test "key events update counters and last action" do
    state = KeyListener.init(%{}, %{})

    state = KeyListener.enter_down(nil, state)
    state = KeyListener.ctrl_digit_1_down(nil, state)
    state = KeyListener.arrow_left_down(nil, state)
    state = KeyListener.escape_up(nil, state)
    state = KeyListener.space_press(nil, state)

    assert %{
             key_down_count: 3,
             key_up_count: 1,
             key_press_count: 1,
             enter_count: 1,
             ctrl_digit_1_count: 1,
             arrow_left_count: 1,
             escape_count: 1,
             space_press_count: 1,
             last_action: "Keyboard key press: Space (1)"
           } = KeyListener.expose(state, %{}, %{})
  end
end
