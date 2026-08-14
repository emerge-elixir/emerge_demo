defmodule EmergeDemo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    opts = [strategy: :rest_for_one, name: EmergeDemo.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  def children(env \\ Mix.env())
  def children(:test), do: []
  def children(:dev), do: base_children() ++ [hot_reload_child()]
  def children(_other), do: base_children()

  def prime_validation?, do: config(:prime_validation?, true)

  def main_rendering_api, do: config(:main_rendering_api, :vulkan)

  def prime_source_rendering_api, do: config(:prime_source_rendering_api, :opengl)

  def prime_drm_node, do: config(:prime_drm_node, nil)

  defp config(key, default) do
    :emerge_demo
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key, default)
  end

  defp base_children do
    [
      EmergeDemo.Todo.App.child_spec([]),
      EmergeDemo.Showcase.App.child_spec([]),
      EmergeDemo.AppSelector.App.child_spec([])
    ] ++ prime_source_children() ++ [EmergeDemo]
  end

  defp prime_source_children do
    if prime_validation?(),
      do: [EmergeDemo.PrimeSource.child_spec(name: EmergeDemo.PrimeSource)],
      else: []
  end

  defp hot_reload_child do
    {Emerge.Runtime.CodeReloader,
     dirs: [
       Path.expand("..", __DIR__)
     ],
     reloadable_apps: [:emerge_demo]}
  end
end
