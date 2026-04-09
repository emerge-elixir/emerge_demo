defmodule EmergeDemo do
  @moduledoc """
  Desktop example shell built with `Emerge` and `Solve`.
  """

  use Emerge
  use Solve.Lookup

  alias EmergeDemo.Showcase.AssetCatalog

  @impl Viewport
  def mount(opts) do
    {:ok,
     Keyword.merge(
       [
         emerge_skia: [
           otp_app: :emerge_demo,
           title: "Emerge Example",
           assets: AssetCatalog.renderer_assets_config()
         ]
       ],
       opts
     )}
  end

  @impl Viewport
  def render() do
    EmergeDemo.AppSelector.View.layout()
  end

  @impl Solve.Lookup
  def handle_solve_updated(_updated, state) do
    {:ok, Viewport.rerender(state)}
  end
end
