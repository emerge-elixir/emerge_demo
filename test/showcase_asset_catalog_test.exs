defmodule EmergeDemo.Showcase.AssetCatalogTest do
  use ExUnit.Case, async: true

  alias EmergeDemo.Showcase.AssetCatalog

  test "renderer asset config exposes lobster font and runtime path policy" do
    assert [fonts: [font], runtime_paths: runtime_paths] = AssetCatalog.renderer_assets_config()

    assert font[:family] == "lobster-demo"
    assert font[:source].path == "demo_fonts/Lobster-Regular.ttf"
    assert runtime_paths[:enabled]
    assert runtime_paths[:allowlist] == [AssetCatalog.runtime_allowlist_root()]
    assert ".svg" in runtime_paths[:extensions]
  end

  test "runtime and blocked image sources point to existing files" do
    runtime_path = AssetCatalog.runtime_image_path()
    blocked_path = AssetCatalog.blocked_image_path()
    build_priv_dir = :code.priv_dir(:emerge_demo) |> List.to_string()

    assert File.regular?(runtime_path)
    assert File.regular?(blocked_path)
    refute String.starts_with?(blocked_path, AssetCatalog.runtime_allowlist_root())
    refute String.starts_with?(runtime_path, build_priv_dir)
  end
end
