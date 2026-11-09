defmodule SistemaEmergencias.Application do
  @moduledoc """
  Módulo de aplicación OTP que define la estrategia de supervisión
  y el arranque automático de los GenServer del sistema.
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Definición de los procesos que serán supervisados por el árbol OTP
    children = [
      {SistemaEmergencias.Procesos.ServidorRecursos, []},
      {SistemaEmergencias.Procesos.ServidorNecesidades, []}
    ]

    # Estrategia :one_for_one -> Si un servidor falla, solo ese servidor se reinicia
    opts = [strategy: :one_for_one, name: SistemaEmergencias.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
