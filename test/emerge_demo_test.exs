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

  test "mount configures example renderer defaults" do
    assert {:ok, opts} = EmergeDemo.mount([])

    assert opts[:emerge_skia] == [
             otp_app: :emerge_demo,
             title: "Emerge Example",
             assets: AssetCatalog.renderer_assets_config()
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

  test "dev children start solve apps before the viewport" do
    assert EmergeDemo.Application.children(:dev)
           |> Enum.take(4)
           |> Enum.map(&child_module/1) == [
             EmergeDemo.Todo.App,
             EmergeDemo.Showcase.App,
             EmergeDemo.AppSelector.App,
             EmergeDemo
           ]
  end

  defp child_module(%{start: {module, :start_link, _args}}), do: module
  defp child_module({module, _opts}), do: module
  defp child_module(module) when is_atom(module), do: module
end
