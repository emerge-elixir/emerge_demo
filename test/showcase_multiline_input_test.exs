defmodule EmergeDemo.Showcase.MultilineInputTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.MultilineInput

  test "grow and submit changes update their respective values" do
    state = MultilineInput.init(%{}, %{})

    state = MultilineInput.grow_changed("alpha\nbeta", state)
    state = MultilineInput.submit_changed("submitted once", state)

    assert %{grow: %{value: "alpha\nbeta"}, submit: %{value: "submitted once"}} =
             MultilineInput.expose(state, %{}, %{})
  end

  test "focus and blur counts stay independent per field" do
    state = MultilineInput.init(%{}, %{})

    state = MultilineInput.grow_focused(nil, state)
    state = MultilineInput.grow_blurred(nil, state)
    state = MultilineInput.submit_focused(nil, state)

    assert %{grow: %{focused?: false, focus_count: 1, blur_count: 1}} =
             MultilineInput.expose(state, %{}, %{})

    assert %{submit: %{focused?: true, focus_count: 1, blur_count: 0}} =
             MultilineInput.expose(state, %{}, %{})
  end

  test "submit_enter increments the intercepted enter counter" do
    state = MultilineInput.init(%{}, %{})

    state = MultilineInput.submit_enter(nil, state)
    state = MultilineInput.submit_enter(nil, state)

    assert %{submit: %{submit_count: 2}} = MultilineInput.expose(state, %{}, %{})
  end
end
