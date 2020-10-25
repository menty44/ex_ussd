# ExUssd

[![Actions Status](https://github.com/beamkenya/ex_ussd/workflows/Elixir%20CI/badge.svg)](https://github.com/beamkenya/ex_ussd/actions) ![Hex.pm](https://img.shields.io/hexpm/v/ex_ussd) ![Hex.pm](https://img.shields.io/hexpm/dt/ex_ussd)
[![Coverage Status](https://coveralls.io/repos/github/beamkenya/ex_ussd/badge.svg?branch=develop)](https://coveralls.io/github/beamkenya/ex_ussd?branch=develop)

## Introduction

> ExUssd lets you create simple, flexible, and customizable USSD interface.
> Under the hood ExUssd uses Elixir Registry to create and route individual USSD session.

## Sections

- [Installation](#Installation)
- [Gateway Providers](#providers)
- [Configuration](#Configuration)
- [Documentation](#Documentation)
- [Contribution](#contribution)
- [Contributors](#contributors)
- [Licence](#licence)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_ussd` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_ussd, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_ussd](https://hexdocs.pm/ex_ussd).

## Providers

ExUssd currently supports

[Africastalking API](https://africastalking.com)

[Infobip API](https://www.infobip.com/)

## Configuration

To Use One of the above gateway providers for your project
Create a copy of `config/dev.exs` or `config/prod.exs` from `config/dev.sample.exs`
Use the `gateway` key to set the ussd vendor.

### AfricasTalking

Add below config to dev.exs / prod.exs files

```elixir
config :ex_ussd, :gateway, AfricasTalking
```

### Infobip

Add below config to dev.exs / prod.exs files

```elixir
config :ex_ussd, :gateway, Infobip
```

## Documentation

ExUssd supports Ussd customizations through `Menu` struct via the render function

- `handler` - This is a callback function that returns the menu struct, ussd api_parameters map and should_handle boolean.

  - menu - The menu struct is modified to produce ussd menu struct
  - api_parameters - This a map of ussd response call
  - should_handle - a check value, where ExUssd allows the developer to handle client input, more on `handle`, default is `false`

- `name` - This is the value display when Menu is rendered as menu_list. check more on `menu_list`.

- `title` - Outputs the ussd's title,

```elixir
ExUssd.Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu |> Map.put(:title, "Welcome")
        end
        )
{:ok, "CON Welcome"}
```

- `menu_list` - Takes a list of Ussd Menu

```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Product A",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product a")
            end),
            Menu.render(
              name: "Product B",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product b")
            end)]
          )
      end)
  {:ok, "CON Welcome\n1:Product A\n2:Product B"}
  # simulate 1
  {:ok, "CON selected product a\n0:BACK"}
```

- `should_close` - This triggers ExUssd to end the current registry session and correct preffix the menu string

```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Product A",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product a")
                |> Map.put(:should_close, true)
            end),
            Menu.render(
              name: "Product B",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product b")
                |> Map.put(:should_close, true)
            end)]
          )
      end)
  {:ok, "CON Welcome\n1:Product A\n2:Product B"}
  # simulate 1
  {:ok, "END selected product a"}
```

- `default_error_message` - This the default error message shown on invalid input. default `"Invalid Choice\n"`

```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu
            |> Map.put(:default_error_message, "Invalid selection, try again\n")
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Product A",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product a")
            end),
            Menu.render(
              name: "Product B",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product b")
            end)]
          )
      end)
  {:ok, "CON Welcome\n1:Product A\n2:Product B"}
  # simulate 11
  {:ok, "CON Invalid selection, try again\nWelcome\n1:Product A\n2:Product B"}
```

- `display_style` - Used change the default's display style ":"

```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu
            |> Map.put(:display_style, ")")
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Product A",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product a")
            end),
            Menu.render(
              name: "Product B",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product b")
            end)]
          )
      end)
  {:ok, "CON Welcome\n1)Product A\n2)Product B"}
```

- `split` - This is used to set the chunk size value when rendering menu_list. default value size `7`

```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu
            |> Map.put(:split, 2)
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Product A",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product a")
            end),
            Menu.render(
              name: "Product B",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product b")
            end),
            Menu.render(
              name: "Product C",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product c")
            end)]
          )
      end)
  {:ok, "CON Welcome\n1:Product A\n2:Product B\n98:MORE"}
  # simulate 98
  {:ok, "CON Welcome\n3:Product C\n0:BACK"}
```

- `next` - Used render the next menu chunk, default `"98"`
- `previous` - Ussd to navigate to the previous menu, default "0"
- `handle` - To let ExUssd allow the developer to validate the client input, before navigating to the next menu.

```elixir
  iex> ExUssd.Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Enter Pin Number")
          |> Map.put(:handle, true)
          |> Map.put(
            :validation_menu,
            ExUssd.Menu.render(
              name: "",
              handler: fn menu, api_parameters, should_handle ->
                case should_handle do
                  true ->
                    case api_parameters.text == "5555" do
                      true ->
                        menu
                        |> Map.put(:title, "success, thank you.")
                        |> Map.put(:should_close, true)
                        |> Map.put(:success, true)

                      _ ->
                        menu |> Map.put(:error, "Wrong pin number\n")
                    end

                  false ->
                    menu
                end
              end
            )
          )
        end
      )
    {:ok, "CON Enter Pin Number"}
    ## simulate 5555
    {:ok, "END success, thank you."}
    ## simulate 2342
    {:ok, "CON Wrong pin number\nEnter Pin Number"}
```

- `error` - custom error message on failed validation/handling,
- `success` - allows ExUssd to Render next menu on successful validation/handling
- `show_options` - hides menu list on false
- `show_navigation` - set to false to hide navigation menu

### Render Menu

ExUssd to render `Menu` struct for different ussd providers. ExUssd provides `goto` function that starts and manages the ussd sessions.
The `goto` function receives the following parameters.

- `internal_routing` - it takes a map with ussd text, session_id and serive_code
- `menu` - Menu struct
- `api_parameters` - api_parameters

```elixir
  iex> menu = ExUssd.Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu |> Map.put(:title, "Welcome")
        end
        )
  iex> ExUssd.goto(
        internal_routing: %{text: "", session_id: "session_01", service_code: "*544#"},
        menu: menu,
       api_parameters: %{
        "sessionId" => "session_01",
        "phoneNumber" => "254722000000",
        "networkCode" => "Safaricom",
        "serviceCode" => "*544#",
        "text" => ""
        }
      )
  {:ok, "CON Welcome"}
```

### Testing
To test your USSD menu, ExUssd provides a `simulate` function that helps you test menu rendering and logic implemented by mimicking USSD gateway callback.

```elixir
  iex> menu = ExUssd.Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu |> Map.put(:title, "Welcome")
        end
        )
  iex> ExUssd.simulate(menu: menu, text: "")

  {:ok, "CON Welcome"}
```
## Contribution

If you'd like to contribute, start by searching through the [issues](https://github.com/beamkenya/ex_ussd/issues) and [pull requests](https://github.com/beamkenya/ex_ussd/pulls) to see whether someone else has raised a similar idea or question.
If you don't see your idea listed, [Open an issue](https://github.com/beamkenya/ex_ussd/issues).

Check the [Contribution guide](contributing.md) on how to contribute.

## Contributors

Auto-populated from:
[contributors-img](https://contributors-img.firebaseapp.com/image?repo=beamkenya/ex_ussd)

<a href="https://github.com/beamkenya/ex_ussd/graphs/contributors">
  <img src="https://contributors-img.firebaseapp.com/image?repo=beamkenya/ex_ussd" />
</a>

## Licence

ExPesa is released under [MIT License](https://github.com/appcues/exsentry/blob/master/LICENSE.txt)

[![license](https://img.shields.io/github/license/mashape/apistatus.svg?style=for-the-badge)](#)