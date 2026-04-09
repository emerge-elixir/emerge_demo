defmodule EmergeDemo.Showcase.TextInputTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.TextInput

  test "changed updates the value and notifies soft keyboard callback" do
    state = TextInput.init(%{}, %{})

    updated =
      TextInput.changed("hello world", state, %{}, %{
        text_committed: fn -> send(self(), :text_committed) end
      })

    assert %{value: "hello world"} = TextInput.expose(updated, %{}, %{})
    assert_received :text_committed
  end

  test "focused and blurred update counts and clear popup" do
    state = TextInput.init(%{}, %{})

    focused =
      TextInput.focused(nil, state, %{}, %{
        clear_popup: fn -> send(self(), :clear_popup) end
      })

    blurred =
      TextInput.blurred(nil, focused, %{}, %{
        clear_popup: fn -> send(self(), :clear_popup) end
      })

    assert %{focused?: true, focus_count: 1, blur_count: 0} = TextInput.expose(focused, %{}, %{})
    assert %{focused?: false, focus_count: 1, blur_count: 1} = TextInput.expose(blurred, %{}, %{})
    assert_received :clear_popup
    assert_received :clear_popup
  end
end
