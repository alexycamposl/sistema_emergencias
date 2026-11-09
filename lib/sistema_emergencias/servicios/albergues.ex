defmodule SistemaEmergencias.Servicios.Albergues do
  @moduledoc """
  Servicio para la administración de albergues y control de cupos/ocupación.
  """

  alias SistemaEmergencias.Modelos.Albergue
  alias SistemaEmergencias.Utilidades.Validaciones
  alias SistemaEmergencias.Utilidades.Persistencia

  @archivo "albergues.txt"

  def listar do
    {:ok, lista} = Persistencia.cargar_datos(@archivo)
    lista
  end

  @doc "Registra un albergue en el sistema."
  def registrar(codigo, nombre, zona, capacidad_maxima) do
    albergues = listar()

    with {:ok, cod_val} <- Validaciones.validar_texto_no_vacio(codigo),
         {:ok, nom_val} <- Validaciones.validar_texto_no_vacio(nombre),
         {:ok, cap_val} <- Validaciones.validar_cantidad_positiva(capacidad_maxima),
         :ok <- validar_codigo_unico(albergues, cod_val) do

      nuevo_albergue = %Albergue{
        codigo: cod_val,
        nombre: nom_val,
        zona: zona,
        capacidad_maxima: cap_val,
        ocupacion_actual: 0,
        personas: []
      }

      Persistencia.guardar_datos(@archivo, [nuevo_albergue | albergues])
      {:ok, nuevo_albergue}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc "Busca un albergue por su código."
  def buscar_por_codigo(codigo) do
    case Enum.find(listar(), fn a -> a.codigo == codigo end) do
      nil -> {:error, "Albergue no encontrado"}
      albergue -> {:ok, albergue}
    end
  end

  @doc "Registra el ingreso de una persona al albergue respetando el límite de capacidad."
  def registrar_ingreso(codigo_albergue, documento_persona) do
    albergues = listar()

    case Enum.find(albergues, fn a -> a.codigo == codigo_albergue end) do
      nil ->
        {:error, "Albergue no encontrado"}

      albergue ->
        case Validaciones.validar_capacidad_albergue(albergue.ocupacion_actual, 1, albergue.capacidad_maxima) do
          {:ok, nueva_ocupacion} ->
            nuevas_personas = [documento_persona | albergue.personas]
            albergue_act = %{albergue | ocupacion_actual: nueva_ocupacion, personas: nuevas_personas}

            nuevos_albergues = Enum.map(albergues, fn a -> if a.codigo == codigo_albergue, do: albergue_act, else: a end)
            Persistencia.guardar_datos(@archivo, nuevos_albergues)
            {:ok, albergue_act}

          error ->
            error
        end
    end
  end

  @doc "Registra la salida de una persona del albergue."
  def registrar_salida(codigo_albergue, documento_persona) do
    albergues = listar()

    case Enum.find(albergues, fn a -> a.codigo == codigo_albergue end) do
      nil ->
        {:error, "Albergue no encontrado"}

      albergue ->
        if documento_persona in albergue.personas do
          nueva_ocupacion = max(0, albergue.ocupacion_actual - 1)
          nuevas_personas = List.delete(albergue.personas, documento_persona)
          albergue_act = %{albergue | ocupacion_actual: nueva_ocupacion, personas: nuevas_personas}

          nuevos_albergues = Enum.map(albergues, fn a -> if a.codigo == codigo_albergue, do: albergue_act, else: a end)
          Persistencia.guardar_datos(@archivo, nuevos_albergues)
          {:ok, albergue_act}
        else
          {:error, "La persona no se encuentra alojada en este albergue"}
        end
    end
  end

  @doc "Genera un reporte con los albergues de mayor ocupación."
  def reporte_mayor_ocupacion do
    listar()
    |> Enum.sort_by(fn a -> a.ocupacion_actual end, :desc)
  end

  defp validar_codigo_unico(albergues, codigo) do
    if Enum.any?(albergues, fn a -> a.codigo == codigo end) do
      {:error, "Ya existe un albergue con el mismo código"}
    else
      :ok
    end
  end
end
