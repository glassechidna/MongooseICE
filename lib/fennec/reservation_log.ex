defmodule Fennec.ReservationLog do
  @moduledoc false

  ## Runtime support for storing and fetching pending reservations.
  ## I.e. an ETS table owner process.

  alias Fennec.TURN.Reservation
  alias Jerboa.Format.Body.Attribute.ReservationToken

  @type name :: atom

  def start_link(base_name) do
    name = __MODULE__.name(base_name)
    Agent.start_link(fn -> init_db(name) end, name: name)
  end

  @spec register(name, Reservation.t) :: :ok | {:error, :exists}
  def register(name, %Reservation{} = r) do
    case :ets.insert_new(name, {r.token.value, r}) do
      false -> {:error, :exists}
      _ -> :ok
    end
  end

  @spec take(name, ReservationToken.t) :: Reservation.t | nil
  def take(name, %ReservationToken{} = token) do
    case :ets.take(name, token.value) do
      [] -> nil
      [r] -> r
    end
  end

  @spec name(name) :: name
  def name(base_name) do
    "#{base_name}.ReservationLog" |> String.to_atom()
  end

  defp init_db(table_name) do
    ## TODO: largely guesswork here, not load tested
    perf_opts = [write_concurrency: true]
    ^table_name = :ets.new(table_name, [:public, :named_table] ++ perf_opts)
  end

end