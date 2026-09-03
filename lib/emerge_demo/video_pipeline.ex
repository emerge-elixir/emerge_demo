defmodule EmergeDemo.VideoPipeline do
  @moduledoc false

  use Membrane.Pipeline

  require Logger

  alias Membrane.VideoInterop.{Sink, Source}

  @headless_streams [:dma_buf, :binary]
  @dma_buf_target :headless_prime_validation
  @binary_target :headless_binary_validation
  @h264_target :h264_file_playback
  @h264_group :h264_playback
  @h264_children [
    :h264_file,
    :h264_parser,
    :h264_decoder,
    :h264_converter,
    :h264_realtimer,
    :h264_frame_converter,
    :h264_sink
  ]
  @h264_dmabuf_target :h264_dmabuf_playback
  @h264_dmabuf_group :h264_dmabuf_playback
  @h264_dmabuf_children [
    :h264_dmabuf_file,
    :h264_dmabuf_parser,
    :h264_dmabuf_realtimer,
    :h264_dmabuf_decoder,
    :h264_dmabuf_sink
  ]
  @h264_all_children @h264_children ++ @h264_dmabuf_children

  def start_link(opts \\ []) do
    Membrane.Pipeline.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def handle_init(_ctx, opts) do
    spec = [
      child(:dma_buf_source, %Source{notify: self()})
      |> child(:dma_buf_sink, %Sink{
        submit: {__MODULE__, :submit, []},
        target: @dma_buf_target
      }),
      child(:binary_source, %Source{notify: self()})
      |> child(:binary_sink, %Sink{
        submit: {__MODULE__, :submit, []},
        target: @binary_target
      }),
      h264_branch(),
      h264_dmabuf_branch()
    ]

    state = %{
      sources: %{dma_buf: nil, binary: nil},
      notify: Keyword.get(opts, :notify),
      viewport_closed?: false,
      restarting_playbacks: MapSet.new()
    }

    {[spec: spec], state}
  end

  @impl true
  def handle_info(
        {:video_interop_source_ready, _source},
        _ctx,
        %{viewport_closed?: true} = state
      ),
      do: {[], state}

  def handle_info({:video_interop_source_ready, source}, ctx, state) do
    case stream_for_source(ctx.children, source) do
      nil ->
        {[], state}

      stream ->
        state =
          state
          |> replace_video_source_if_ingress_changed(stream, source)
          |> put_in([:sources, stream], source)

        start_video_source(stream, state)
    end
  end

  def handle_info(
        {:start_video_source, _stream},
        _ctx,
        %{viewport_closed?: true} = state
      ),
      do: {[], state}

  def handle_info({:start_video_source, stream}, _ctx, state) do
    start_video_source(stream, state)
  end

  def handle_info(_message, _ctx, state), do: {[], state}

  @impl true
  def handle_element_end_of_stream(
        sink,
        :input,
        _ctx,
        %{viewport_closed?: false} = state
      )
      when sink in [:h264_sink, :h264_dmabuf_sink] do
    playback = playback_for_sink(sink)
    restarting_playbacks = MapSet.put(state.restarting_playbacks, playback)

    {[remove_children: playback_group(playback)],
     %{state | restarting_playbacks: restarting_playbacks}}
  end

  def handle_element_end_of_stream(_element, _pad, _ctx, state), do: {[], state}

  @impl true
  def handle_child_terminated(child, ctx, state) when child in @h264_all_children do
    playback = playback_for_child(child)

    cond do
      state.viewport_closed? ->
        {[], state}

      MapSet.member?(state.restarting_playbacks, playback) and
          playback_stopped?(playback, ctx.children) ->
        restarting_playbacks = MapSet.delete(state.restarting_playbacks, playback)
        {[spec: playback_branch(playback)], %{state | restarting_playbacks: restarting_playbacks}}

      true ->
        {[], state}
    end
  end

  def handle_child_terminated(_child, _ctx, state), do: {[], state}

  @impl true
  def handle_child_notification(
        {:video_interop_sink_error, :viewport_not_ready},
        _child,
        _ctx,
        state
      ) do
    Enum.each(@headless_streams, &stop_video_source/1)

    actions =
      if state.viewport_closed? do
        []
      else
        [remove_children: [@h264_group, @h264_dmabuf_group]]
      end

    {actions,
     %{
       state
       | sources: %{dma_buf: nil, binary: nil},
         viewport_closed?: true,
         restarting_playbacks: MapSet.new()
     }}
  end

  def handle_child_notification(
        {:video_interop_sink_error, :viewport_unavailable},
        _child,
        _ctx,
        %{viewport_closed?: true} = state
      ),
      do: {[], state}

  def handle_child_notification({:video_interop_sink_error, reason}, _child, _ctx, state) do
    report_error(:video_interop_sink_error, reason, state)
  end

  def handle_child_notification({:video_interop_source_error, reason}, _child, _ctx, state) do
    report_error(:video_interop_source_error, reason, state)
  end

  def handle_child_notification(
        {:raw_video_to_video_interop_error, reason},
        _child,
        _ctx,
        state
      ) do
    report_error(:h264_frame_conversion_error, reason, state)
  end

  def handle_child_notification(_notification, _child, _ctx, state), do: {[], state}

  @doc false
  def h264_source_path do
    Application.app_dir(:emerge_demo, "priv/video/big_buck_bunny_bird.h264")
  end

  defp h264_branch do
    branch =
      child(:h264_file, %Membrane.File.Source{
        location: h264_source_path(),
        content_format: Membrane.H264
      })
      |> child(:h264_parser, %Membrane.H264.Parser{
        output_alignment: :au,
        output_stream_structure: :annexb,
        generate_best_effort_timestamps: %{framerate: {24, 1}}
      })
      |> child(:h264_decoder, Membrane.H264.FFmpeg.Decoder)
      |> child(:h264_converter, %Membrane.FFmpeg.SWScale.Converter{format: :RGBA})
      |> child(:h264_realtimer, Membrane.Realtimer)
      |> child(:h264_frame_converter, EmergeDemo.RawVideoToVideoInterop)
      |> child(:h264_sink, %Sink{
        submit: {__MODULE__, :submit, []},
        target: @h264_target
      })

    {branch, group: @h264_group}
  end

  defp h264_dmabuf_branch do
    branch =
      child(:h264_dmabuf_file, %Membrane.File.Source{
        location: h264_source_path(),
        content_format: Membrane.H264
      })
      |> child(:h264_dmabuf_parser, %Membrane.H264.Parser{
        output_alignment: :au,
        output_stream_structure: :annexb,
        generate_best_effort_timestamps: %{framerate: {24, 1}}
      })
      |> child(:h264_dmabuf_realtimer, Membrane.Realtimer)
      |> child(:h264_dmabuf_decoder, %Membrane.H264.Decoder{
        output: :dmabuf,
        decoder: :vaapi,
        hw_device: EmergeDemo.Application.video_decode_drm_node(),
        max_in_flight: 4
      })
      |> child(:h264_dmabuf_sink, %Sink{
        submit: {__MODULE__, :submit, []},
        target: @h264_dmabuf_target
      })

    {branch, group: @h264_dmabuf_group}
  end

  defp playback_for_sink(:h264_sink), do: :h264
  defp playback_for_sink(:h264_dmabuf_sink), do: :h264_dmabuf

  defp playback_for_child(child) when child in @h264_children, do: :h264
  defp playback_for_child(child) when child in @h264_dmabuf_children, do: :h264_dmabuf

  defp playback_group(:h264), do: @h264_group
  defp playback_group(:h264_dmabuf), do: @h264_dmabuf_group

  defp playback_branch(:h264), do: h264_branch()
  defp playback_branch(:h264_dmabuf), do: h264_dmabuf_branch()

  defp playback_stopped?(playback, children) do
    playback
    |> playback_children()
    |> Enum.all?(&(not Map.has_key?(children, &1)))
  end

  defp playback_children(:h264), do: @h264_children
  defp playback_children(:h264_dmabuf), do: @h264_dmabuf_children

  defp stream_for_source(children, source) do
    Enum.find_value(@headless_streams, fn stream ->
      case Map.get(children, source_child(stream)) do
        %{pid: ^source} -> stream
        _other -> nil
      end
    end)
  end

  defp replace_video_source_if_ingress_changed(state, stream, source) do
    if state.sources[stream] == source do
      state
    else
      stop_video_source(stream)
      state
    end
  end

  defp stop_video_source(stream) do
    case Process.whereis(source_module(stream)) do
      nil ->
        :ok

      source ->
        case DynamicSupervisor.terminate_child(EmergeDemo.VideoSupervisor, source) do
          :ok -> :ok
          {:error, :not_found} -> :ok
        end
    end
  end

  defp start_video_source(stream, state) do
    case state.sources[stream] do
      nil -> {[], state}
      target -> start_ready_video_source(stream, target, state)
    end
  end

  defp start_ready_video_source(stream, target, state) do
    cond do
      Process.whereis(source_module(stream)) ->
        {[], state}

      is_nil(Process.whereis(EmergeDemo.VideoSupervisor)) ->
        Process.send_after(self(), {:start_video_source, stream}, 10)
        {[], state}

      true ->
        module = source_module(stream)

        case DynamicSupervisor.start_child(
               EmergeDemo.VideoSupervisor,
               {module, [name: module, video_output_target: target]}
             ) do
          {:ok, _pid} -> {[], state}
          {:error, {:already_started, _pid}} -> {[], state}
          {:error, reason} -> report_error(source_start_error(stream), reason, state)
        end
    end
  end

  defp source_child(:dma_buf), do: :dma_buf_source
  defp source_child(:binary), do: :binary_source

  defp source_module(:dma_buf), do: EmergeDemo.PrimeSource
  defp source_module(:binary), do: EmergeDemo.BinarySource

  defp source_start_error(:dma_buf), do: :dma_buf_source_start_failed
  defp source_start_error(:binary), do: :binary_source_start_failed

  defp report_error(kind, reason, state) do
    Logger.error("#{kind}: #{inspect(reason)}")
    if state.notify, do: send(state.notify, {kind, reason})
    {[], state}
  end

  def submit(frame, target) do
    case Process.whereis(EmergeDemo) do
      nil ->
        VideoInterop.release(frame)
        {:error, :viewport_unavailable}

      viewport ->
        Emerge.submit_video_frame(viewport, target, frame)
    end
  end
end
