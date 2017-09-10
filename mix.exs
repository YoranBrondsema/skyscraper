defmodule Skyscraper.Mixfile do
  use Mix.Project

  def project do
    [
      app: :skyscraper,
      version: "0.1.0",
      elixir: "~> 1.5",
      escript: escript(),
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      { :httpoison, "~> 0.13" },
      { :floki, "~> 0.18.0" },
      { :poison, "~> 3.1" }
    ]
  end

  defp escript do
    [
      main_module: Skyscraper.CLI
    ]
  end
end
