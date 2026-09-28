defmodule EmergeDemo.VideoPlaybackGate do
  @moduledoc false

  use Membrane.Filter

  def_input_pad(:input,
    accepted_format: any_of(Membrane.H264, Membrane.H265),
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: any_of(Membrane.H264, Membrane.H265),
    flow_control: :auto
  )

  @impl true
  def handle_init(_ctx, _opts), do: {[], %{draining?: false, eos_sent?: false}}

  @impl true
  def handle_parent_notification(:drain, ctx, state) do
    state = %{state | draining?: true}
    if ctx.playback == :playing, do: end_output(state), else: {[], state}
  end

  @impl true
  def handle_playing(_ctx, %{draining?: true} = state), do: end_output(state)
  def handle_playing(_ctx, state), do: {[], state}

  @impl true
  def handle_stream_format(:input, _format, _ctx, %{draining?: true} = state),
    do: {[], state}

  def handle_stream_format(:input, format, _ctx, state),
    do: {[stream_format: {:output, format}], state}

  @impl true
  def handle_buffer(:input, _buffer, _ctx, %{draining?: true} = state), do: {[], state}
  def handle_buffer(:input, buffer, _ctx, state), do: {[buffer: {:output, buffer}], state}

  @impl true
  def handle_end_of_stream(:input, _ctx, state), do: end_output(state)

  defp end_output(%{eos_sent?: true} = state), do: {[], state}
  defp end_output(state), do: {[end_of_stream: :output], %{state | eos_sent?: true}}
end
