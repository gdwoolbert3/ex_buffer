defmodule ExBuffer.MixProject do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :ex_buffer,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: dialyzer(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      name: "ExBuffer",
      docs: docs(),
      aliases: aliases(),
      preferred_cli_env: preferred_cli_env(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer do
    [
      plt_file: {:no_warn, "dialyzer/dialyzer.plt"},
      plt_add_apps: [:ex_unit, :mix]
    ]
  end

  defp description do
    """
    A simple and lightweight data buffer for Elixir.
    """
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_url: "https://github.com/gdwoolbert3/ex_buffer",
      authors: ["Gordon Woolbert"]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Gordon Woolbert"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/gdwoolbert3/ex_buffer"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  defp aliases do
    [
      setup: [
        "local.hex --if-missing --force",
        "local.rebar --if-missing --force",
        "deps.get"
      ],
      ci: [
        "setup",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "test",
        "dialyzer --format github",
        "sobelow --config"
      ]
    ]
  end

  # Specifies the preferred env for mix commands.
  defp preferred_cli_env do
    [
      ci: :test
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchee, "~> 1.1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.30.8", only: :dev, runtime: false},
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13.0", only: [:dev, :test], runtime: false}
    ]
  end
end
