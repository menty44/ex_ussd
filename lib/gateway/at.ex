defmodule AfricasTalking do
  alias ExUssd.State.Registry

  @behaviour ExUssd.Ussd

  @doc """
  Africa's talking

  ## Configuration
  Add below config to dev.exs / prod.exs files

  `config.exs`
    ```elixir
      config :ex_ussd :provider, AfricasTalking
    ```
  ## Example

      iex> defmodule DefaultHandler do
      ...>   @behaviour ExUssd.Handler
      ...>  def handle_menu(menu, _api_parameters) do
      ...>    menu |> Map.put(:title, "Welcome")
      ...>  end
      ...>end
      iex> menu = ExUssd.Menu.render(name: "Home", handler: DefaultHandler)
      iex> AfricasTalking.goto(
      ...>  internal_routing: %{text: "", session_id: "session_01", service_code: "*544#"},
      ...>  menu: menu,
      ...>  api_parameters: %{
      ...>      "sessionId" => "session_01",
      ...>      "phoneNumber" => "254722000000",
      ...>      "networkCode" => "Safaricom",
      ...>      "serviceCode" => "*544#",
      ...>      "text" => ""
      ...>    }
      ...>  )
      {:ok, "CON Welcome"}
  """
  @impl true
  def goto(internal_routing: internal_routing, menu: menu, api_parameters: api_parameters) do

    Registry.start(internal_routing.session_id)

    processed_text =  process_text(internal_routing)

    route =
      ExUssd.Routes.get_route(%{text: processed_text, service_code: internal_routing.service_code})

    %{menu: current_menu, display: menu_string} =
      EXUssd.Common.goto(
        internal_routing: %{internal_routing | text: processed_text},
        menu: menu,
        api_parameters: api_parameters,
        route: route
      )

    output(internal_routing, current_menu, menu_string)
  end

  @doc """
  End session by ID
  ## Example
      iex> AfricasTalking.end_session(session_id: "session_01")
      {:error, :not_found}
  """
  @impl true
  def end_session(session_id: _session_id) do
    {:error, :not_found}
  end

  @impl true
  def get_menu(session_id: session_id) do
    ExUssd.State.Registry.get_menu(session_id)
  end

  def process_text(internal_routing) do
    text_value = internal_routing.text |> String.replace("#", "")
    service_code_value = internal_routing.service_code |> String.replace("#", "")
    case ExUssd.State.Registry.get_current_menu(internal_routing.session_id) do
      nil ->
        case internal_routing.text do
          "" ->
            ""

          _ ->
            cond do
              text_value =~ service_code_value ->
                text_value

              true ->
                service_code_value <> "*" <> internal_routing.text
            end
        end

      _ ->
        cond do
          text_value == service_code_value ->
            ""

          text_value =~ service_code_value ->
            text_value

          true ->
            case internal_routing.text |> String.split("*") do
              value when length(value) == 1 -> value |> hd
              value -> Enum.reverse(value) |> hd
            end
        end
    end
  end

  def output(internal_routing, current_menu, menu_string) do
    %{should_close: should_close} = current_menu

    output =
      case should_close do
        false ->
          "CON " <> menu_string

        true ->
          Registry.stop(internal_routing.session_id)
          "END " <> menu_string
      end

    {:ok, output}
  end
end
