defmodule EmergeDemo.VideoPipeline do
  @moduledoc false

  use Membrane.Pipeline

  require Logger

  alias Membrane.VideoInterop.{Sink, Source}

  @target :headless_prime_validation

  def start_link(opts \\ []) do
    Membrane.Pipeline.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def handle_init(_ctx, opts) do
    spec =
      child(:source, %Source{notify: self()})
      |> child(:sink, %Sink{submit: {__MODULE__, :submit, []}, target: @target})

    {[spec: spec], %{source: nil, notify: Keyword.get(opts, :notify)}}
  end

  @impl true
  def handle_info({:video_interop_source_ready, source}, _ctx, state) do
    state
    |> replace_prime_source_if_ingress_changed(source)
    |> Map.put(:source, source)
    |> start_prime_source()
  end

  def handle_info(:start_prime_source, _ctx, state), do: start_prime_source(state)
  def handle_info(_message, _ctx, state), do: {[], state}

  @impl true
  def handle_child_notification({:video_interop_sink_error, reason}, _child, _ctx, state) do
    report_error(:video_interop_sink_error, reason, state)
  end

  def handle_child_notification({:video_interop_source_error, reason}, _child, _ctx, state) do
    report_error(:video_interop_source_error, reason, state)
  end

  def handle_child_notification(_notification, _child, _ctx, state), do: {[], state}

  defp replace_prime_source_if_ingress_changed(%{source: source} = state, source), do: state

  defp replace_prime_source_if_ingress_changed(state, _source) do
    case Process.whereis(EmergeDemo.PrimeSource) do
      nil ->
        state

      prime_source ->
        case DynamicSupervisor.terminate_child(EmergeDemo.VideoSupervisor, prime_source) do
          :ok -> state
          {:error, :not_found} -> state
        end
    end
  end

  defp start_prime_source(%{source: nil} = state), do: {[], state}

  defp start_prime_source(state) do
    cond do
      Process.whereis(EmergeDemo.PrimeSource) ->
        {[], state}

      is_nil(Process.whereis(EmergeDemo.VideoSupervisor)) ->
        Process.send_after(self(), :start_prime_source, 10)
        {[], state}

      true ->
        case DynamicSupervisor.start_child(
               EmergeDemo.VideoSupervisor,
               {EmergeDemo.PrimeSource,
                [name: EmergeDemo.PrimeSource, video_output_target: state.source]}
             ) do
          {:ok, _pid} -> {[], state}
          {:error, {:already_started, _pid}} -> {[], state}
          {:error, reason} -> report_error(:prime_source_start_failed, reason, state)
        end
    end
  end

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
