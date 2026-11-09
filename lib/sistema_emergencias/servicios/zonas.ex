defmodule SistemaEmergencias.Servicios.Zonas do
  @moduledoc """
  Servicio para gestionar zonas afectadas.
  Incluye algoritmos recursivos sobre la estructura de Zonas -> Sectores -> Puntos de atención.
  """

  alias SistemaEmergencias.Modelos.Zona
  alias SistemaEmergencias.Utilidades.Validaciones
  alias SistemaEmergencias.Utilidades.Persistencia

  @archivo "zonas.txt"

  @doc "Carga todas las zonas almacenadas."
  def listar do
    {:ok, lista} = Persistencia.cargar_datos(@archivo)
    lista
  end

  @doc "Registra una nueva zona afectada."
  def registrar(nombre, nivel_afectacion, sectores \\ []) do
    zonas = listar()

    with {:ok, nombre_val} <- Validaciones.validar_texto_no_vacio(nombre),
         {:ok, nivel_val} <- Validaciones.validar_nivel_afectacion(nivel_afectacion) do

      nuevo_id = length(zonas) + 1

      nueva_zona = %Zona{
        id: nuevo_id,
        nombre: nombre_val,
        nivel_afectacion: nivel_val,
        sectores: sectores
      }

      Persistencia.guardar_datos(@archivo, [nueva_zona | zonas])
      {:ok, nueva_zona}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc "Busca una zona por su nombre."
  def buscar_por_nombre(nombre) do
    case Enum.find(listar(), fn z -> z.nombre == nombre end) do
      nil -> {:error, "Zona no encontrada"}
      zona -> {:ok, zona}
    end
  end

  # ==========================================
  # ALGORITMOS RECURSIVOS OBLIGATORIOS (TEMA 08)
  # Recorrido recursivo: Zonas -> Sectores -> Puntos de Atención
  # ==========================================

  @doc """
  Calcula recursivamente el total estimado de personas afectadas en una lista de sectores
  o puntos de atención anidados.
  """
  def contar_afectados_recursivo([]), do: 0

  def contar_afectados_recursivo([head | tail]) do
    personas_en_elemento(head) + contar_afectados_recursivo(tail)
  end

  # Caso base de elemento individual (sector o punto de atención)
  defp personas_en_elemento(%{personas_afectadas: num}) when is_number(num), do: num
  defp personas_en_elemento(%{subsectores: sub}) when is_list(sub), do: contar_afectados_recursivo(sub)
  defp personas_en_elemento(_), do: 0

  @doc "Obtiene las estadísticas acumuladas de una zona procesando sus sectores recursivamente."
  def obtener_estadisticas_zona(nombre_zona) do
    case buscar_por_nombre(nombre_zona) do
      {:ok, zona} ->
        total_afectados = contar_afectados_recursivo(zona.sectores)
        total_sectores = contar_elementos_recursivo(zona.sectores)

        {:ok, %{
          zona: zona.nombre,
          nivel: zona.nivel_afectacion,
          total_sectores: total_sectores,
          estimado_personas_afectadas: total_afectados
        }}

      error ->
        error
    end
  end

  @doc "Función recursiva para contar la cantidad total de subsectores y puntos anidados."
  def contar_elementos_recursivo([]), do: 0

  def contar_elementos_recursivo([head | tail]) do
    1 + contar_subelementos(head) + contar_elementos_recursivo(tail)
  end

  defp contar_subelementos(%{subsectores: sub}) when is_list(sub), do: contar_elementos_recursivo(sub)
  defp contar_subelementos(_), do: 0
end
