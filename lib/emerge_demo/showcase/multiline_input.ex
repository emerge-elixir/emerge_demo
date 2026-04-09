defmodule EmergeDemo.Showcase.MultilineInput do
  @moduledoc false

  use Solve.Controller,
    events: [
      :grow_changed,
      :grow_focused,
      :grow_blurred,
      :submit_changed,
      :submit_focused,
      :submit_blurred,
      :submit_enter
    ]

  @impl true
  def init(_init_params, _dependencies) do
    %{
      grow:
        field_state(
          "Multiline fields wrap and grow with their content when height is omitted.\nResize the window or add more lines to watch the frame expand."
        ),
      submit:
        field_state(
          "Enter is intercepted here. Type normally, then press Enter to count the event instead of inserting a newline.",
          submit_count: 0
        )
    }
  end

  def grow_changed(value, state) when is_binary(value),
    do: put_in(state, [:grow, :value], value)

  def grow_focused(_payload, state), do: update_in(state, [:grow], &focus_field/1)
  def grow_blurred(_payload, state), do: update_in(state, [:grow], &blur_field/1)

  def submit_changed(value, state) when is_binary(value),
    do: put_in(state, [:submit, :value], value)

  def submit_focused(_payload, state), do: update_in(state, [:submit], &focus_field/1)
  def submit_blurred(_payload, state), do: update_in(state, [:submit], &blur_field/1)

  def submit_enter(_payload, state) do
    update_in(state, [:submit, :submit_count], &(&1 + 1))
  end

  @impl true
  def expose(state, _dependencies, _init_params), do: state

  defp field_state(value, extras \\ []) do
    %{value: value, focused?: false, focus_count: 0, blur_count: 0}
    |> Map.merge(Enum.into(extras, %{}))
  end

  defp focus_field(field) do
    %{field | focused?: true, focus_count: field.focus_count + 1}
  end

  defp blur_field(field) do
    %{field | focused?: false, blur_count: field.blur_count + 1}
  end
end
