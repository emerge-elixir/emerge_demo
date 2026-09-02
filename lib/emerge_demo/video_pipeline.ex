defmodule EmergeDemo.VideoPipeline do
  @moduledoc false

  use Membrane.Pipeline

  require Logger

  alias Membrane.VideoInterop.{Sink, Source}

  @dma_buf_target :headless_prime_validation
  @binary_target :headless_binary_validation

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
      })
    ]

    {[spec: spec], %{sources: %{dma_buf: nil, binary: nil}, notify: Keyword.get(opts, :notify)}}
  end

  @impl true
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

  def handle_info({:start_video_source, stream}, _ctx, state) do
    start_video_source(stream, state)
  end

  def handle_info(_message, _ctx, state), do: {[], state}

  @impl true
  def handle_child_notification({:video_interop_sink_error, reason}, _child, _ctx, state) do
    report_error(:video_interop_sink_error, reason, state)
  end

  def handle_child_notification({:video_interop_source_error, reason}, _child, _ctx, state) do
    report_error(:video_interop_source_error, reason, state)
  end

  def handle_child_notification(_notification, _child, _ctx, state), do: {[], state}

  defp stream_for_source(children, source) do
    Enum.find_value([:dma_buf, :binary], fn stream ->
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
