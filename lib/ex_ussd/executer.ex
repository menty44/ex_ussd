defmodule ExUssd.Executer do
  @moduledoc false

  @doc """
  'execute_navigate/2' function
  It invoke's anonymous function set on navigate field.
  """

  alias ExUssd.Utils

  @spec execute_navigate(ExUssd.t(), map()) :: ExUssd.t()
  def execute_navigate(menu, payload)

  def execute_navigate(%ExUssd{navigate: navigate} = menu, payload)
      when is_function(navigate) do
    case apply(navigate, [menu, payload]) do
      %ExUssd{} = menu -> %{menu | navigate: nil}
      _ -> menu
    end
  end

  def execute_navigate(%ExUssd{} = menu, _), do: menu

  @doc """
   It invoke's the init callback function on the resolve field.
  """
  @spec execute_init_callback(ExUssd.t(), map()) :: {:ok, ExUssd.t()}
  def execute_init_callback(menu, payload)

  def execute_init_callback(%ExUssd{resolve: resolve} = menu, payload)
      when is_function(resolve) do
    if is_function(resolve, 2) do
      with %ExUssd{} = menu <- apply(resolve, [menu, payload]), do: {:ok, menu}
    else
      raise %BadArityError{function: resolve, args: [menu, payload]}
    end
  end

  def execute_init_callback(%ExUssd{name: name, resolve: resolve} = menu, payload)
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_init, 2) do
      with %ExUssd{} = menu <- apply(resolve, :ussd_init, [menu, payload]),
           do: {:ok, menu}
    else
      raise %ArgumentError{message: "resolve module for #{name} does not export ussd_init/2"}
    end
  end

  def execute_init_callback(%ExUssd{name: name, resolve: resolve}, _payload),
    do:
      raise(
        ArgumentError,
        "resolve for #{name} should be a function or a module, found #{inspect(resolve)}"
      )

  def execute_init_callback(menu, _payload),
    do: raise(ArgumentError, "expected a ExUssd struct found #{inspect(menu)}")

  @spec execute_init_callback!(ExUssd.t(), map()) :: ExUssd.t()
  def execute_init_callback!(menu, payload) do
    {:ok, menu} = execute_init_callback(menu, payload)
    menu
  end

  @doc """
   It invoke's 'ussd_callback/3' callback function on the resolver module.
  """

  @spec execute_callback(%ExUssd{}, map(), keyword()) :: {:ok, ExUssd.t()} | any()
  def execute_callback(menu, payload, opts \\ [state: true])

  def execute_callback(%ExUssd{navigate: navigate} = menu, payload, opts)
      when not is_nil(navigate) do
    menu
    |> Map.put(:resolve, navigate)
    |> get_next_menu(payload, opts)
  end

  def execute_callback(%ExUssd{resolve: resolve} = menu, payload, opts)
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_callback, 3) do
      metadata =
        if(Keyword.get(opts, :state),
          do: Utils.fetch_metadata(payload),
          else:
            Map.merge(
              %{
                route: "*test#",
                invoked_at: DateTime.truncate(DateTime.utc_now(), :second),
                attempt: 1
              },
              payload
            )
        )

      try do
        with %ExUssd{error: error} = current_menu <-
               apply(resolve, :ussd_callback, [%{menu | resolve: nil}, payload, metadata]) do
          if is_bitstring(error) do
            build_response_menu(:halt, current_menu, menu, payload, opts)
          else
            build_response_menu(:ok, current_menu, menu, payload, opts)
            |> get_next_menu(payload, opts)
          end
        end
      rescue
        FunctionClauseError ->
          nil
      end
    end
  end

  def execute_callback(_menu, _payload, _opts), do: nil

  @spec execute_callback!(ExUssd.t(), map(), keyword()) :: ExUssd.t() | nil
  def execute_callback!(menu, payload, opts \\ [state: true]) do
    case execute_callback(menu, payload, opts) do
      {_, menu} -> menu
      nil -> nil
    end
  end

  @doc """
   It invoke's 'ussd_after_callback/3' callback function on the resolver module.
  """

  @spec execute_after_callback(%ExUssd{}, map()) :: {:ok | :halt, ExUssd.t()} | any()
  def execute_after_callback(menu, payload, opts \\ [state: true])

  def execute_after_callback(
        %ExUssd{error: original_error, resolve: resolve} = menu,
        payload,
        opts
      )
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_after_callback, 3) do
      error_state = if is_bitstring(original_error), do: true

      metadata =
        if(Keyword.get(opts, :state),
          do: Utils.fetch_metadata(payload),
          else:
            Map.merge(
              %{
                route: "*test#",
                invoked_at: DateTime.truncate(DateTime.utc_now(), :second),
                attempt: 3
              },
              payload
            )
        )

      try do
        with %ExUssd{error: error} = current_menu <-
               apply(resolve, :ussd_after_callback, [
                 %{menu | resolve: nil, error: error_state},
                 payload,
                 metadata
               ]) do
          if is_bitstring(error) do
            build_response_menu(:halt, current_menu, menu, payload, opts)
          else
            build_response_menu(:ok, current_menu, menu, payload, opts)
            |> get_next_menu(payload, opts)
          end
        end
      rescue
        FunctionClauseError ->
          nil
      end
    end
  end

  def execute_after_callback(_menu, _payload, _opts), do: nil

  @spec execute_after_callback!(ExUssd.t(), map(), keyword()) :: ExUssd.t() | nil
  def execute_after_callback!(menu, payload, opts \\ [state: true]) do
    case execute_after_callback(menu, payload, opts) do
      {_, menu} -> menu
      nil -> nil
    end
  end

  defp build_response_menu(:halt, current_menu, %{resolve: resolve}, _payload, _opts),
    do: {:halt, %{current_menu | resolve: resolve}}

  defp build_response_menu(:ok, current_menu, menu, payload, opts) do
    if Keyword.get(opts, :state) do
      %{route: route} = ExUssd.Route.get_route(payload)
      %{session_id: session} = payload
      ExUssd.Registry.add_route(session, route)
    end

    {:ok, %{current_menu | parent: fn -> menu end}}
  end

  defp get_next_menu(menu, payload, opts) do
    fun = fn
      %ExUssd{orientation: orientation, data: data, resolve: resolve} ->
        new_menu =
          ExUssd.new(
            orientation: orientation,
            name: "#{inspect(resolve)}",
            resolve: resolve,
            data: data
          )

        current_menu = execute_init_callback!(new_menu, payload)

        build_response_menu(:ok, current_menu, menu, payload, opts)

      response ->
        response
    end

    current_response =
      case menu do
        {:ok, %ExUssd{resolve: resolve} = menu} when not is_nil(resolve) ->
          menu

        %ExUssd{} = menu ->
          menu

        menu ->
          menu
      end

    apply(fun, [current_response])
  end
end
