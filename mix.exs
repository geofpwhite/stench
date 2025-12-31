defmodule Stench.MixProject do
  use Mix.Project

  def project do
    [
      app: :stench,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      # default_task: "Stench.CLI.main"
      test_coverage: [
        ignore_modules: [
          Operators,
          Keywords,
          Stench.CLI
        ]
      ],
      description: "An interpreter I wrote that's toilet themed",
      package: package()
    ]
  end

  defp escript do
    [main_module: Stench.CLI, name: "stench"]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/geofpwhite/stench",
        "Docs" => "https://hexdocs.pm/stench"
      }
    ]
  end
end
