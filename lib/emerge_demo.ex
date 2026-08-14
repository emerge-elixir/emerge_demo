defmodule EmergeDemo do
  @moduledoc """
  Desktop example shell built with `Emerge` and `Solve`.
  """

  use Emerge
  use Solve.Lookup, handle_info: :manual

  require Logger

  alias EmergeDemo.{PrimeSource, Showcase.AssetCatalog}
  alias EmergeSkia.VideoTarget

  @prime_retry_ms 2_000

  @impl Viewport
  def mount(opts) do
    viewport_opts =
      Keyword.merge(
        [
          emerge_skia: [
            otp_app: :emerge_demo,
            backend: :wayland,
            title: "Emerge Example",
            rendering_api: EmergeDemo.Application.main_rendering_api(),
            # backend: :drm,
            # drm_card: "/dev/dri/card0",
            assets: AssetCatalog.renderer_assets_config(),
            renderer_cache: [enabled: true],
            renderer_stats_log: true,
            render_log: false
          ]
        ],
        opts
      )

    prime_status =
      if EmergeDemo.Application.prime_validation?() do
        send(self(), :bootstrap_prime_target)
        :starting
      else
        {:error, :prime_validation_disabled}
      end

    {:ok, %{prime_connection: nil, prime_target: nil, prime_status: prime_status}, viewport_opts}
  end

  @impl Viewport
  def render(state) do
    EmergeDemo.AppSelector.View.layout({state.prime_status, state.prime_target})
  end

  @impl Viewport
  def handle_info(:bootstrap_prime_target, %{prime_connection: connection} = state)
      when is_reference(connection),
      do: {:noreply, state}

  def handle_info(:bootstrap_prime_target, state) do
    case bootstrap_prime_target(state) do
      {:ok, state} ->
        {:noreply, Viewport.rerender(state)}

      {:error, reason, state} ->
        Logger.warning("PRIME validation connection unavailable: #{inspect(reason)}")
        Process.send_after(self(), :bootstrap_prime_target, @prime_retry_ms)
        {:noreply, state |> Map.put(:prime_status, {:error, reason}) |> Viewport.rerender()}
    end
  end

  def handle_info(
        {:emerge_video_output, _source, connection, :connected},
        %{prime_connection: connection} = state
      ) do
    {:noreply, state |> Map.put(:prime_status, :waiting) |> Viewport.rerender()}
  end

  def handle_info(
        {:emerge_video_output, _source, connection, {:first_frame_accepted, _sequence}},
        %{prime_connection: connection} = state
      ) do
    {:noreply, state |> Map.put(:prime_status, :streaming) |> Viewport.rerender()}
  end

  def handle_info(
        {:emerge_video_output, _source, connection, {:error, reason}},
        %{prime_connection: connection} = state
      ) do
    {:noreply,
     state
     |> Map.put(:prime_status, {:error, {:submit_failed, reason}})
     |> Viewport.rerender()}
  end

  def handle_info(
        {:emerge_video_output, _source, connection, :disconnected},
        %{prime_connection: connection} = state
      ) do
    Process.send_after(self(), :bootstrap_prime_target, @prime_retry_ms)

    {:noreply,
     state
     |> Map.put(:prime_connection, nil)
     |> Map.put(:prime_target, nil)
     |> Viewport.rerender()}
  end

  def handle_info(%Solve.Message{} = message, state) do
    updated = handle_message(message)

    if map_size(updated) == 0 do
      {:noreply, state}
    else
      {:ok, state} = handle_solve_updated(updated, state)
      {:noreply, state}
    end
  end

  def handle_info(_message, state), do: {:noreply, state}

  @impl Solve.Lookup
  def handle_solve_updated(_updated, state) do
    {:ok, Viewport.rerender(state)}
  end

  defp bootstrap_prime_target(state) do
    case ensure_prime_target(state) do
      {:ok, target, state} ->
        case connect_prime_source(target) do
          {:ok, connection} ->
            {:ok,
             %{
               state
               | prime_connection: connection,
                 prime_target: target,
                 prime_status: :waiting
             }}

          {:error, reason} ->
            {:error, reason, state}
        end

      {:error, reason, state} ->
        {:error, reason, state}
    end
  end

  defp ensure_prime_target(%{prime_target: %VideoTarget{} = target} = state),
    do: {:ok, target, state}

  defp ensure_prime_target(%{__emerge__: %{renderer: renderer}} = state)
       when not is_nil(renderer) do
    {width, height} = PrimeSource.dimensions()

    case EmergeSkia.video_target(renderer,
           id: "headless-prime-validation",
           width: width,
           height: height,
           mode: :prime
         ) do
      {:ok, target} -> {:ok, target, %{state | prime_target: target}}
      {:error, reason} -> {:error, reason, state}
    end
  end

  defp ensure_prime_target(state), do: {:error, :renderer_unavailable, state}

  defp connect_prime_source(target) do
    case Process.whereis(PrimeSource) do
      nil ->
        {:error, :source_unavailable}

      source ->
        Emerge.connect_video_output(source, target,
          notify: self(),
          acquire_sync: :sync_file
        )
    end
  end
end
