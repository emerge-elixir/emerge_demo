defmodule EmergeDemo.RawVideoToVideoInterop do
  @moduledoc false

  use Membrane.Filter

  alias Membrane.Buffer
  alias Membrane.VideoInterop.RawVideo
  alias VideoInterop.{Binary, Format}

  def_input_pad(:input,
    accepted_format: %Membrane.RawVideo{pixel_format: :RGBA, aligned: true},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: Format,
    flow_control: :auto
  )

  @impl true
  def handle_init(_ctx, _opts), do: {[], %{raw_format: nil}}

  @impl true
  def handle_stream_format(:input, %Membrane.RawVideo{} = raw_format, _ctx, state) do
    format = %Format{
      width: raw_format.width,
      height: raw_format.height,
      framerate: raw_format.framerate,
      storage: %Binary.Format{pixel_format: :rgba8888},
      acquire_sync: :implicit,
      alpha_mode: :straight
    }

    {[stream_format: {:output, format}], %{state | raw_format: raw_format}}
  end

  @impl true
  def handle_buffer(:input, %Buffer{} = buffer, _ctx, %{raw_format: raw_format} = state) do
    case RawVideo.frame_from_buffer(buffer, raw_format) do
      {:ok, frame} ->
        {[buffer: {:output, %{buffer | payload: frame}}], state}

      {:error, reason} ->
        {[notify_parent: {:raw_video_to_video_interop_error, reason}], state}
    end
  end
end
