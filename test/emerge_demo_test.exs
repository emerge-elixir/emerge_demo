defmodule EmergeDemoTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.AssetCatalog

  test "handle_solve_updated schedules viewport rerender" do
    state = %{
      __emerge__: %Emerge.Runtime.Viewport.State{module: EmergeDemo}
    }

    assert {:ok, next_state} =
             EmergeDemo.handle_solve_updated(%{EmergeDemo.Todo.App => [:entries]}, state)

    assert next_state.__emerge__.dirty?
    assert next_state.__emerge__.flush_scheduled?
    assert_receive {:"$gen_cast", {:emerge_viewport, :flush}}
  end

  test "mount configures the Wayland Vulkan renderer" do
    assert {:ok, %{video: {{:error, :prime_validation_disabled}, nil}}, opts} =
             EmergeDemo.mount([])

    assert opts[:emerge_skia] == [
             otp_app: :emerge_demo,
             backend: :wayland,
             title: "Emerge Example",
             rendering_api: :vulkan,
             assets: AssetCatalog.renderer_assets_config(),
             renderer_cache: [enabled: true],
             renderer_stats_log: true,
             render_log: false
           ]

    refute_receive :bootstrap_prime_target
  end

  test "PRIME source has an independently configured rendering API" do
    assert {:ok, opts} = EmergeDemo.PrimeSource.mount(video_output_target: self())
    renderer_opts = opts[:emerge_skia]

    assert renderer_opts[:rendering_api] == :opengl

    assert renderer_opts[:headless][:prime] == [
             max_in_flight: 3,
             on_backpressure: :drop_new
           ]
  end

  test "dev children include the hot reloader" do
    assert [{Emerge.Runtime.CodeReloader, opts}] =
             EmergeDemo.Application.children(:dev)
             |> Enum.filter(fn
               {Emerge.Runtime.CodeReloader, _opts} -> true
               _other -> false
             end)

    assert opts[:reloadable_apps] == [:emerge_demo]
    assert Enum.all?(opts[:dirs], &is_binary/1)
  end

  test "dev children omit PRIME production while matrix validation is disabled" do
    children = EmergeDemo.Application.children(:dev)

    assert children
           |> Enum.take(4)
           |> Enum.map(&child_module/1) == [
             EmergeDemo.Todo.App,
             EmergeDemo.Showcase.App,
             EmergeDemo.AppSelector.App,
             EmergeDemo
           ]

    refute Enum.any?(children, &(child_module(&1) == EmergeDemo.PrimeSource))
  end

  defp child_module(%{start: {module, :start_link, _args}}), do: module
  defp child_module({module, _opts}), do: module
  defp child_module(module) when is_atom(module), do: module
end
