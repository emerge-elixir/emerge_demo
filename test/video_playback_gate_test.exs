defmodule EmergeDemo.VideoPlaybackGateTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.VideoPlaybackGate, as: Gate

  test "forwards codec input until asked to drain and sends EOS only once" do
    {[], state} = Gate.handle_init(%{}, [])
    ctx = %{playback: :playing}
    format = %Membrane.H265{alignment: :au}
    buffer = %Membrane.Buffer{payload: <<1, 2, 3>>}

    assert {[stream_format: {:output, ^format}], ^state} =
             Gate.handle_stream_format(:input, format, ctx, state)

    assert {[buffer: {:output, ^buffer}], ^state} =
             Gate.handle_buffer(:input, buffer, ctx, state)

    assert {[end_of_stream: :output], draining} =
             Gate.handle_parent_notification(:drain, ctx, state)

    assert {[], ^draining} = Gate.handle_buffer(:input, buffer, ctx, draining)
    assert {[], ^draining} = Gate.handle_stream_format(:input, format, ctx, draining)
    assert {[], ^draining} = Gate.handle_parent_notification(:drain, ctx, draining)
    assert {[], ^draining} = Gate.handle_end_of_stream(:input, ctx, draining)
  end

  test "drain requested during setup waits until playback to send EOS" do
    {[], state} = Gate.handle_init(%{}, [])
    assert {[], draining} = Gate.handle_parent_notification(:drain, %{playback: :stopped}, state)
    refute draining.eos_sent?
    assert {[end_of_stream: :output], drained} = Gate.handle_playing(%{}, draining)
    assert drained.eos_sent?
  end

  test "draining after natural EOS does not send it again" do
    {[], state} = Gate.handle_init(%{}, [])
    assert {[end_of_stream: :output], ended} = Gate.handle_end_of_stream(:input, %{}, state)
    assert {[], draining} = Gate.handle_parent_notification(:drain, %{playback: :playing}, ended)
    assert draining.draining?
  end
end
