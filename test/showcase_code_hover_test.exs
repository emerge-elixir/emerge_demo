defmodule EmergeDemo.Showcase.CodeHoverTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.CodeHover

  test "show exposes the active example id" do
    state = CodeHover.init(%{}, %{})
    shown = CodeHover.show({:layout, :wrapped_row}, state)

    assert %{active: {:layout, :wrapped_row}} = CodeHover.expose(shown, %{}, %{})
  end

  test "hide clears the active example when ids match" do
    state = %{active: {:layout, :alignment_tokens}}
    hidden = CodeHover.hide({:layout, :alignment_tokens}, state)

    assert %{active: nil} = CodeHover.expose(hidden, %{}, %{})
  end

  test "hide ignores stale example ids" do
    state = %{active: {:layout, :centered_content}}
    hidden = CodeHover.hide({:layout, :wrapped_row}, state)

    assert %{active: {:layout, :centered_content}} = CodeHover.expose(hidden, %{}, %{})
  end
end
