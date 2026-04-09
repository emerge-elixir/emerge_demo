defmodule EmergeDemo.Showcase.KeyListener do
  @moduledoc false

  use Solve.Controller,
    events: [
      :focused,
      :blurred,
      :enter_down,
      :ctrl_digit_1_down,
      :arrow_left_down,
      :escape_up,
      :space_press
    ]

  @initial_last_action "Nothing yet"

  @impl true
  def init(_init_params, _dependencies) do
    %{
      focused?: false,
      focus_count: 0,
      blur_count: 0,
      key_down_count: 0,
      key_up_count: 0,
      key_press_count: 0,
      enter_count: 0,
      ctrl_digit_1_count: 0,
      arrow_left_count: 0,
      escape_count: 0,
      space_press_count: 0,
      last_action: @initial_last_action
    }
  end

  def focused(_payload, state, _dependencies, callbacks) do
    if clear_popup = callbacks[:clear_popup], do: clear_popup.()
    %{state | focused?: true, focus_count: state.focus_count + 1}
  end

  def blurred(_payload, state, _dependencies, callbacks) do
    if clear_popup = callbacks[:clear_popup], do: clear_popup.()
    %{state | focused?: false, blur_count: state.blur_count + 1}
  end

  def enter_down(_payload, state) do
    %{
      state
      | key_down_count: state.key_down_count + 1,
        enter_count: state.enter_count + 1,
        last_action: "Keyboard key down: Enter (#{state.enter_count + 1})"
    }
  end

  def ctrl_digit_1_down(_payload, state) do
    %{
      state
      | key_down_count: state.key_down_count + 1,
        ctrl_digit_1_count: state.ctrl_digit_1_count + 1,
        last_action: "Keyboard key down: Ctrl+1 (#{state.ctrl_digit_1_count + 1})"
    }
  end

  def arrow_left_down(_payload, state) do
    %{
      state
      | key_down_count: state.key_down_count + 1,
        arrow_left_count: state.arrow_left_count + 1,
        last_action: "Keyboard key down: Arrow Left (#{state.arrow_left_count + 1})"
    }
  end

  def escape_up(_payload, state) do
    %{
      state
      | key_up_count: state.key_up_count + 1,
        escape_count: state.escape_count + 1,
        last_action: "Keyboard key up: Escape (#{state.escape_count + 1})"
    }
  end

  def space_press(_payload, state) do
    %{
      state
      | key_press_count: state.key_press_count + 1,
        space_press_count: state.space_press_count + 1,
        last_action: "Keyboard key press: Space (#{state.space_press_count + 1})"
    }
  end
end
