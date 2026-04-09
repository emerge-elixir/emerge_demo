defmodule EmergeDemo.Showcase.Interaction do
  @moduledoc false

  @swipe_labels %{up: "Up", down: "Down", left: "Left", right: "Right"}

  use Solve.Controller,
    events: [
      :manual_hover_enter,
      :manual_hover_leave,
      :mouse_down,
      :mouse_up,
      :swiped,
      :transformed_move,
      :rotated_enter,
      :rotated_leave,
      :scaled_down,
      :scaled_up
    ]

  @impl true
  def init(_init_params, _dependencies) do
    %{
      manual_hover?: false,
      mouse_down_count: 0,
      mouse_up_count: 0,
      swipe_last: "None",
      swipe_up_count: 0,
      swipe_down_count: 0,
      swipe_left_count: 0,
      swipe_right_count: 0,
      transformed_last_move_target: "None",
      transformed_rotated_enter_count: 0,
      transformed_rotated_leave_count: 0,
      transformed_scaled_down_count: 0,
      transformed_scaled_up_count: 0
    }
  end

  def manual_hover_enter(_payload, state), do: %{state | manual_hover?: true}
  def manual_hover_leave(_payload, state), do: %{state | manual_hover?: false}
  def mouse_down(_payload, state), do: %{state | mouse_down_count: state.mouse_down_count + 1}
  def mouse_up(_payload, state), do: %{state | mouse_up_count: state.mouse_up_count + 1}

  def swiped(direction, state) when direction in [:up, :down, :left, :right] do
    %{
      state
      | swipe_last: Map.fetch!(@swipe_labels, direction),
        swipe_up_count:
          if(direction == :up, do: state.swipe_up_count + 1, else: state.swipe_up_count),
        swipe_down_count:
          if(direction == :down, do: state.swipe_down_count + 1, else: state.swipe_down_count),
        swipe_left_count:
          if(direction == :left, do: state.swipe_left_count + 1, else: state.swipe_left_count),
        swipe_right_count:
          if(direction == :right, do: state.swipe_right_count + 1, else: state.swipe_right_count)
    }
  end

  def transformed_move(label, state) when is_binary(label) do
    if state.transformed_last_move_target == label do
      state
    else
      %{state | transformed_last_move_target: label}
    end
  end

  def rotated_enter(_payload, state) do
    %{state | transformed_rotated_enter_count: state.transformed_rotated_enter_count + 1}
  end

  def rotated_leave(_payload, state) do
    %{state | transformed_rotated_leave_count: state.transformed_rotated_leave_count + 1}
  end

  def scaled_down(_payload, state) do
    %{state | transformed_scaled_down_count: state.transformed_scaled_down_count + 1}
  end

  def scaled_up(_payload, state) do
    %{state | transformed_scaled_up_count: state.transformed_scaled_up_count + 1}
  end

  @impl true
  def expose(state, _dependencies, _init_params) do
    %{
      manual_hover?: state.manual_hover?,
      mouse_down_count: state.mouse_down_count,
      mouse_up_count: state.mouse_up_count,
      swipe: %{
        last: state.swipe_last,
        up_count: state.swipe_up_count,
        down_count: state.swipe_down_count,
        left_count: state.swipe_left_count,
        right_count: state.swipe_right_count
      },
      transformed: %{
        last_move_target: state.transformed_last_move_target,
        rotated_enter_count: state.transformed_rotated_enter_count,
        rotated_leave_count: state.transformed_rotated_leave_count,
        scaled_down_count: state.transformed_scaled_down_count,
        scaled_up_count: state.transformed_scaled_up_count
      }
    }
  end
end
