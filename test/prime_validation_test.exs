defmodule EmergeDemo.PrimeValidationTest do
  use ExUnit.Case, async: true

  alias Emerge.Runtime.Viewport.State
  alias EmergeDemo.PrimeSource
  alias EmergeSkia.VideoTarget

  test "headless source configures a directly connectable PRIME viewport" do
    assert {:ok, opts} = PrimeSource.mount([])

    refute opts[:viewport]
    assert opts[:emerge_skia][:backend] == :headless
    assert opts[:emerge_skia][:rendering_api] == :opengl
    assert opts[:emerge_skia][:width] == 640
    assert opts[:emerge_skia][:height] == 420
    assert opts[:emerge_skia][:renderer_stats_log]
    assert opts[:emerge_skia][:headless][:target] == nil
    assert opts[:emerge_skia][:headless][:mode] == :prime
    assert opts[:emerge_skia][:headless][:prime][:max_in_flight] == 3
  end

  test "connection diagnostics update only the matching connection incarnation" do
    connection = make_ref()
    stale = make_ref()
    state = viewport_state(connection)

    assert {:noreply, streaming} =
             EmergeDemo.handle_info(
               {:emerge_video_output, self(), connection, {:first_frame_accepted, 7}},
               state
             )

    assert streaming.prime_status == :streaming

    assert {:noreply, ^streaming} =
             EmergeDemo.handle_info(
               {:emerge_video_output, self(), stale, {:error, :stale}},
               streaming
             )
  end

  test "terminal diagnostics preserve the error and retire the target incarnation" do
    connection = make_ref()
    state = viewport_state(connection)

    assert {:noreply, failed} =
             EmergeDemo.handle_info(
               {:emerge_video_output, self(), connection, {:error, :stale_target}},
               state
             )

    assert failed.prime_status == {:error, {:submit_failed, :stale_target}}

    assert {:noreply, disconnected} =
             EmergeDemo.handle_info(
               {:emerge_video_output, self(), connection, :disconnected},
               failed
             )

    assert disconnected.prime_connection == nil
    assert disconnected.prime_target == nil
    assert disconnected.prime_status == {:error, {:submit_failed, :stale_target}}
  end

  defp viewport_state(connection) do
    %{
      __emerge__: %State{module: EmergeDemo},
      prime_connection: connection,
      prime_status: :waiting,
      prime_target: %VideoTarget{
        id: "prime",
        width: 640,
        height: 360,
        mode: :prime,
        ref: make_ref()
      }
    }
  end
end
