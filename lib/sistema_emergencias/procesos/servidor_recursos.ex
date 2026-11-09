defmodule SistemaEmergencias.Procesos.ServidorRecursos do
  @moduledoc """
  GenServer para la gestión concurrente y atómica del inventario de recursos.
  Garantiza que múltiples solicitudes simultáneas nunca sobrepasen la cantidad física disponible.
  """

  use GenServer
  alias SistemaEmergencias.Servicios.Recursos

  # ==========================================
  # API PÚBLICA / CLIENTE
  # ==========================================

  @doc "Inicia el GenServer registrado globalmente bajo el módulo actual."
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.merge([name: __MODULE__], opts))
  end

  @doc "Asigna una cantidad de un recurso de forma atómica."
  def asignar_recurso(codigo_recurso, cantidad_solicitada) do
    GenServer.call(__MODULE__, {:asignar, codigo_recurso, cantidad_solicitada})
  end

  @doc "Consulta el inventario actual de un recurso directo desde el estado del proceso."
  def consultar_disponibilidad(codigo_recurso) do
    GenServer.call(__MODULE__, {:consultar, codigo_recurso})
  end

  @doc "Recarga el estado en memoria desde el almacenamiento persistente (.txt)."
  def recargar_inventario do
    GenServer.cast(__MODULE__, :recargar)
  end

  # ==========================================
  # CALLBACKS DE GENSERVER (SERVIDOR)
  # ==========================================

  @impl true
  def init(:ok) do
    # Al arrancar, cargamos los recursos iniciales desde el servicio de persistencia
    estado_inicial = Recursos.listar()
    {:ok, estado_inicial}
  end

  @impl true
  def handle_call({:asignar, codigo, cantidad}, _from, recursos) do
    case Enum.find(recursos, fn r -> r.codigo == codigo end) do
      nil ->
        {:reply, {:error, "Recurso no encontrado"}, recursos}

      recurso ->
        if recurso.cantidad_disponible >= cantidad do
          nueva_cantidad = recurso.cantidad_disponible - cantidad
          recurso_actualizado = %{recurso | cantidad_disponible: nueva_cantidad}

          nuevos_recursos =
            Enum.map(recursos, fn r ->
              if r.codigo == codigo, do: recurso_actualizado, else: r
            end)

          # Guardar en persistencia el nuevo estado
          SistemaEmergencias.Utilidades.Persistencia.guardar_datos("recursos.txt", nuevos_recursos)

          {:reply, {:ok, recurso_actualizado}, nuevos_recursos}
        else
          {:reply, {:error, "Inventario insuficiente. Disponible: #{recurso.cantidad_disponible}"}, recursos}
        end
    end
  end

  @impl true
  def handle_call({:consultar, codigo}, _from, recursos) do
    case Enum.find(recursos, fn r -> r.codigo == codigo end) do
      nil -> {:reply, {:error, "Recurso no encontrado"}, recursos}
      recurso -> {:reply, {:ok, recurso.cantidad_disponible}, recursos}
    end
  end

  @impl true
  def handle_cast(:recargar, _recursos) do
    nuevo_estado = Recursos.listar()
    {:noreply, nuevo_estado}
  end
end
