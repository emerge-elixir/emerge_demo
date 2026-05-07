defmodule EmergeDemo.Showcase.SliderInput do
  @moduledoc false

  use Solve.Controller,
    events: [
      :volume_changed,
      :accent_changed,
      :vertical_changed,
      :reset
    ]

  @impl true
  def init(_init_params, _dependencies) do
    %{
      volume: 42.0,
      accent: 68.0,
      vertical: 35.0,
      last: "None",
      change_count: 0
    }
  end

  def volume_changed(value, state) when is_number(value) do
    put_slider_value(state, :volume, value, "Volume")
  end

  def accent_changed(value, state) when is_number(value) do
    put_slider_value(state, :accent, value, "Accent")
  end

  def vertical_changed(value, state) when is_number(value) do
    put_slider_value(state, :vertical, value, "Rotated")
  end

  def reset(_payload, _state), do: init(%{}, %{})

  @impl true
  def expose(state, _dependencies, _init_params), do: state

  defp put_slider_value(state, key, value, label) do
    value = value * 1.0

    state
    |> Map.put(key, value)
    |> Map.put(:last, "#{label} #{format_value(value)}")
    |> Map.update!(:change_count, &(&1 + 1))
  end

  defp format_value(value), do: :erlang.float_to_binary(value, decimals: 1)
end
