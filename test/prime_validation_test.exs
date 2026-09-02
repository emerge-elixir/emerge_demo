defmodule EmergeDemo.PrimeValidationTest do
  use ExUnit.Case, async: false

  alias EmergeDemo.PrimeSource

  test "headless source sends PRIME VideoInterop frames to the Membrane ingress" do
    assert {:ok, opts} = PrimeSource.mount(video_output_target: self())

    refute opts[:viewport]
    assert opts[:emerge_skia][:backend] == :headless
    assert opts[:emerge_skia][:rendering_api] == :opengl
    assert opts[:emerge_skia][:width] == 640
    assert opts[:emerge_skia][:height] == 420
    assert opts[:emerge_skia][:renderer_stats_log]
    assert opts[:emerge_skia][:headless][:target] == self()
    assert opts[:emerge_skia][:headless][:mode] == :prime
    assert opts[:emerge_skia][:headless][:prime][:max_in_flight] == 3
  end

  test "main viewport uses the atom video target rendered by the Membrane sink" do
    config = Application.get_env(:emerge_demo, EmergeDemo.Application, [])
    Application.put_env(:emerge_demo, EmergeDemo.Application, prime_validation?: true)
    on_exit(fn -> Application.put_env(:emerge_demo, EmergeDemo.Application, config) end)

    assert {:ok, state, _opts} = EmergeDemo.mount([])
    assert state.video == {:streaming, :headless_prime_validation}
  end

  test "pipeline callback consumes frames while the viewport is unavailable" do
    frame =
      VideoInterop.Frame.binary(<<0, 0, 0, 255>>,
        width: 1,
        height: 1,
        pixel_format: :rgba8888
      )

    assert {:error, :viewport_unavailable} =
             EmergeDemo.VideoPipeline.submit(frame, :headless_prime_validation)
  end
end
