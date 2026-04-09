defmodule EmergeDemo.Showcase.InteractionTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.Interaction

  test "expose returns pointer interaction state for the page" do
    state = Interaction.init(%{}, %{})

    assert %{
             manual_hover?: false,
             mouse_down_count: 0,
             mouse_up_count: 0,
             swipe: %{last: "None", up_count: 0, down_count: 0, left_count: 0, right_count: 0},
             transformed: %{
               last_move_target: "None",
               rotated_enter_count: 0,
               rotated_leave_count: 0,
               scaled_down_count: 0,
               scaled_up_count: 0
             }
           } = Interaction.expose(state, %{}, %{})
  end

  test "manual hover enter and leave toggle state" do
    state = Interaction.init(%{}, %{})
    hovered = Interaction.manual_hover_enter(nil, state)
    idle = Interaction.manual_hover_leave(nil, hovered)

    assert %{manual_hover?: true} = Interaction.expose(hovered, %{}, %{})
    assert %{manual_hover?: false} = Interaction.expose(idle, %{}, %{})
  end

  test "mouse down increments its counter" do
    state = Interaction.init(%{}, %{})
    pressed = Interaction.mouse_down(nil, state)

    assert %{mouse_down_count: 1, mouse_up_count: 0} = Interaction.expose(pressed, %{}, %{})
  end

  test "mouse up increments its counter" do
    state = Interaction.init(%{}, %{})
    released = Interaction.mouse_up(nil, state)

    assert %{mouse_down_count: 0, mouse_up_count: 1} = Interaction.expose(released, %{}, %{})
  end

  test "swiped updates the correct direction count and last direction" do
    state = Interaction.init(%{}, %{})
    swiped = Interaction.swiped(:left, state)

    assert %{swipe: %{last: "Left", left_count: 1, up_count: 0, down_count: 0, right_count: 0}} =
             Interaction.expose(swiped, %{}, %{})
  end

  test "transformed move remembers the last move target without churn" do
    state = Interaction.init(%{}, %{})
    moved = Interaction.transformed_move("Translated Move", state)
    moved_again = Interaction.transformed_move("Translated Move", moved)

    assert %{transformed: %{last_move_target: "Translated Move"}} =
             Interaction.expose(moved_again, %{}, %{})
  end

  test "rotated hover counters increment independently" do
    state = Interaction.init(%{}, %{})
    entered = Interaction.rotated_enter(nil, state)
    left = Interaction.rotated_leave(nil, entered)

    assert %{transformed: %{rotated_enter_count: 1, rotated_leave_count: 1}} =
             Interaction.expose(left, %{}, %{})
  end

  test "scaled press counters increment independently" do
    state = Interaction.init(%{}, %{})
    down = Interaction.scaled_down(nil, state)
    up = Interaction.scaled_up(nil, down)

    assert %{transformed: %{scaled_down_count: 1, scaled_up_count: 1}} =
             Interaction.expose(up, %{}, %{})
  end
end
