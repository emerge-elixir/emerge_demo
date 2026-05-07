defmodule EmergeDemo.Showcase.SliderInputTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.SliderInput

  test "changes update slider values and last change label" do
    state = SliderInput.init(%{}, %{})

    state = SliderInput.volume_changed(55.0, state)
    state = SliderInput.accent_changed(72.25, state)
    state = SliderInput.vertical_changed(20, state)

    assert %{
             volume: 55.0,
             accent: 72.25,
             vertical: 20.0,
             last: "Rotated 20.0",
             change_count: 3
           } = SliderInput.expose(state, %{}, %{})
  end

  test "reset restores initial slider values" do
    state = SliderInput.volume_changed(95.0, SliderInput.init(%{}, %{}))

    assert %{volume: 42.0, accent: 68.0, vertical: 35.0, last: "None", change_count: 0} =
             SliderInput.reset(nil, state)
  end
end
