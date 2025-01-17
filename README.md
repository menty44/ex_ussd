# ExUssd

[![Actions Status](https://github.com/beamkenya/ex_ussd/workflows/Elixir%20CI/badge.svg)](https://github.com/beamkenya/ex_ussd/actions) ![Hex.pm](https://img.shields.io/hexpm/v/ex_ussd) ![Hex.pm](https://img.shields.io/hexpm/dt/ex_ussd)

Goals:

- An idiomatic, readable, and comfortable API for Elixir developers
- Extensibility based on small parts that do one thing well.
- Detailed error messages and documentation.
- A focus on robustness and production-level performance.

## Table of contents

- [Why Use ExUssd](#why-use-exussd)
- [Documentation](#documentation)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Contribution](#contribution)
- [Contributors](#contributors)
- [Licence](#licence)

## Why Use ExUssd?

 ExUssd lets you create simple, flexible, and customizable USSD interface.
 Under the hood ExUssd uses Elixir Registry to create and route individual USSD session.

https://user-images.githubusercontent.com/23293150/124460086-95ebf080-dd97-11eb-87ab-605f06291563.mp4

## Documentation

The docs can be found at [https://hexdocs.pm/ex_ussd](https://hexdocs.pm/ex_ussd)

## Installation

The package can be installed
by adding `ex_ussd` to your list of dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:ex_ussd, "~> 1.0.0"}
  ]
end
```

## Configuration

Add to your `config.exs`

 ```elixir
# config/config.exs
# TODO: This are example values, replace them with your own
config :ex_ussd,
  nav: [
    ExUssd.Nav.new(type: :home, name: "HOME", match: "00", reverse: true, orientation: :vertical),
    ExUssd.Nav.new(type: :back, name: "BACK", match: "0", right: 1),
    ExUssd.Nav.new(type: :next, name: "MORE", match: "98")
      ],
  delimiter: ").",
  default_error: "invalid input,try again\n"
```

## Usage

### ExUssd Callbacks

ExUssd provides you with 3 callbacks

#### Example

Create a new module:

```elixir
defmodule ApiWeb.HomeResolver do
  use ExUssd
  def ussd_init(menu, _) do
    ExUssd.set(menu, title: "Enter your PIN")
  end

  def ussd_callback(menu, payload, %{attempt: attempt}) do
    if payload.text == "5555" do
      ExUssd.set(menu, resolve: &success_menu/2)
    else
      ExUssd.set(menu, error: "Wrong PIN, #{3 - attempt} attempt left\n")
    end
  end

  def ussd_after_callback(%{error: true} = menu, _payload, %{attempt: 3}) do
    menu
    |> ExUssd.set(title: "Account is locked, Dial *234# to reset your account")
    |> ExUssd.set(should_close: true)
  end

  def success_menu(menu, _) do
    menu
    |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
    |> ExUssd.set(should_close: true)
  end
end
```

## Contribution

If you'd like to contribute, start by searching through the [issues](https://github.com/beamkenya/ex_ussd/issues) and [pull requests](https://github.com/beamkenya/ex_ussd/pulls) to see whether someone else has raised a similar idea or question.
If you don't see your idea listed, [Open an issue](https://github.com/beamkenya/ex_ussd/issues).

Check the [Contribution guide](contributing.md) on how to contribute.

## Contributors

Auto-populated from:
[contributors-img](https://contributors-img.firebaseapp.com/image?repo=beamkenya/ex_ussd)

<a href="https://github.com/beamkenya/ex_pesa/graphs/contributors">
  <img src="https://contributors-img.firebaseapp.com/image?repo=beamkenya/ex_ussd" />
</a>

## Licence

ExUssd is released under [MIT License](https://github.com/appcues/exsentry/blob/master/LICENSE.txt)

[![license](https://img.shields.io/github/license/mashape/apistatus.svg?style=for-the-badge)](#)
