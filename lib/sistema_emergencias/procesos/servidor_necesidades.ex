defmodule SistemaEmergencias.Procesos.ServidorNecesidades do
  @moduledoc """
  GenServer para coordinar de forma concurrente la atención y asignación de necesidades.
  Evita que dos procesos atiendan o cierren simultáneamente una misma solicitud.
  """

  use GenServer
  alias SistemaEmergencias.Servicios.Necesidades
  alias SistemaEmergencias.Procesos.ServidorRecursos

  # ==========================================
  # API PÚBLICA / CLIENTE
  # ==========================================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.merge([name: __MODULE__], opts))
  end

  @doc """
  Atiende una necesidad asignándole insumos desde el ServidorRecursos de forma segura.
  """
  def atender_necesidad(id_necesidad, codigo_recurso, cantidad) do
    GenServer.call(__MODULE__, {:atender, id_necesidad, codigo_recurso, cantidad})
  end

  # ==========================================
  # CALLBACKS DE GENSERVER (SERVIDOR)
  # ==========================================

  @impl true
  def init(:ok) do
    estado_inicial = Necesidades.listar()
    {:ok, estado_inicial}
  end

  @impl true
  def handle_call({:atender, id_necesidad, codigo_recurso, cantidad}, _from, necesidades) do
    case Enum.find(necesidades, fn n -> n.id == id_necesidad end) do
      nil ->
        {:reply, {:error, "Necesidad no encontrada"}, necesidades}

      necesidad when necesidad.estado in [:atendida, :cancelada] ->
        {:reply, {:error, "La necesidad ya fue procesada anteriormente (#{necesidad.estado})"}, necesidades}

      necesidades ->
        # Intentar reservar el recurso de manera concurrente segura
        case ServidorRecursos.asignar_recurso(codigo_recurso, cantidad) do
          {:ok, _recurso_actualizado} ->
            # Actualizar estado de la necesidad a :atendida
            case Necesidades.actualizar_estado(id_necesidad, :atendida) do
              {:ok, necesidad_act} ->
                nuevas_necesidades =
                  Enum.map(necesidades, fn n ->
                    if n.id == id_necesidad, do: necesidad_act, else: n
                  end)

                {:reply, {:ok, "Necesidad #{id_necesidad} atendida con éxito"}, nuevas_necesidades}

              {:error, razon} ->
                {:reply, {:error, razon}, necesidades}
            end

          {:error, razon} ->
            {:reply, {:error, "No se pudo asignar el recurso: #{razon}"}, necesidades}
        end
    end
  end
end
