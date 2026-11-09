defmodule SistemaEmergencias.Servicios.Necesidades do
  @moduledoc """
  Servicio para registrar, consultar y ordenar las necesidades reportadas durante la emergencia.
  """

  alias SistemaEmergencias.Modelos.Necesidad
  alias SistemaEmergencias.Utilidades.Validaciones
  alias SistemaEmergencias.Utilidades.Persistencia

  @archivo "necesidades.txt"

  @doc "Carga todas las necesidades almacenadas."
  def listar do
    {:ok, lista} = Persistencia.cargar_datos(@archivo)
    lista
  end

  @doc "Registra una necesidad de ayuda en el sistema."
  def registrar(tipo, cantidad, prioridad, zona, descripcion, responsable) do
    necesidades = listar()

    with {:ok, tipo_val} <- Validaciones.validar_tipo_necesidad(tipo),
         {:ok, cant_val} <- Validaciones.validar_cantidad_positiva(cantidad),
         {:ok, prio_val} <- Validaciones.validar_prioridad(prioridad),
         {:ok, desc_val} <- Validaciones.validar_texto_no_vacio(descripcion) do

      nuevo_id = "NEED" <> String.pad_leading(Integer.to_string(length(necesidades) + 1), 3, "0")

      nueva_necesidad = %Necesidad{
        id: nuevo_id,
        tipo: tipo_val,
        cantidad: cant_val,
        prioridad: prio_val,
        zona: zona,
        descripcion: desc_val,
        responsable: responsable,
        estado: :pendiente
      }

      Persistencia.guardar_datos(@archivo, [nueva_necesidad | necesidades])
      {:ok, nueva_necesidad}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc "Filtra y ordena las necesidades por prioridad (critica > alta > media > baja)."
  def listar_ordenadas_por_prioridad do
    pesos = %{critica: 4, alta: 3, media: 2, baja: 1}

    listar()
    |> Enum.sort_by(fn n -> Map.get(pesos, n.prioridad, 0) end, :desc)
  end

  @doc "Filtra necesidades por zona y/o prioridad usando Enum.filter y pattern matching."
  def filtrar(filtros) when is_list(filtros) do
    listar()
    |> Enum.filter(fn necesidad ->
      Enum.all?(filtros, fn
        {:zona, z} -> necesidad.zona == z
        {:prioridad, p} -> necesidad.prioridad == p
        {:estado, e} -> necesidad.estado == e
        {:tipo, t} -> necesidad.tipo == t
        _ -> true
      end)
    end)
  end

  @doc "Actualiza el estado de una necesidad garantizando transiciones válidas."
  def actualizar_estado(id_necesidad, nuevo_estado) do
    necesidades = listar()

    case Enum.find(necesidades, fn n -> n.id == id_necesidad end) do
      nil ->
        {:error, "Necesidad no encontrada"}

      necesidad ->
        case Validaciones.validar_transicion_necesidad(necesidad.estado, nuevo_estado) do
          {:ok, estado_val} ->
            necesidad_act = %{necesidad | estado: estado_val}
            nuevas = Enum.map(necesidades, fn n -> if n.id == id_necesidad, do: necesidad_act, else: n end)
            Persistencia.guardar_datos(@archivo, nuevas)
            {:ok, necesidad_act}

          error ->
            error
        end
    end
  end
end
