defmodule SistemaEmergencias.Servicios.Mascotas do
  @moduledoc """
  Servicio para la gestión de mascotas perdidas y encontradas.
  Calcula un puntaje de similitud entre reportes para emparejar animales extraviados.
  """

  alias SistemaEmergencias.Modelos.Mascota
  alias SistemaEmergencias.Utilidades.Validaciones
  alias SistemaEmergencias.Utilidades.Persistencia

  @archivo "mascotas.txt"

  def listar do
    {:ok, lista} = Persistencia.cargar_datos(@archivo)
    lista
  end

  @doc "Registra un reporte de mascota perdida o encontrada."
  def registrar(tipo_reporte, especie, nombre, caracteristicas, color, tamaño, zona, contacto) do
    mascotas = listar()

    with {:ok, esp_val} <- Validaciones.validar_texto_no_vacio(especie),
         {:ok, zona_val} <- Validaciones.validar_texto_no_vacio(zona),
         :ok <- validar_tipo_reporte(tipo_reporte) do

      nuevo_id = length(mascotas) + 1

      nueva_mascota = %Mascota{
        id: nuevo_id,
        tipo_reporte: tipo_reporte,
        especie: String.downcase(esp_val),
        nombre: nombre,
        caracteristicas: caracteristicas,
        color: String.downcase(color),
        tamaño: String.downcase(tamaño),
        zona: zona_val,
        contacto: contacto,
        estado: :activa
      }

      Persistencia.guardar_datos(@archivo, [nueva_mascota | mascotas])
      {:ok, nueva_mascota}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ==========================================
  # ALGORITMO DE COINCIDENCIAS Y COINCIDENCIA DE ATRIBUTOS
  # ==========================================

  @doc """
  Busca posibles coincidencias entre mascotas perdidas y encontradas.
  Retorna una lista de tuplas {mascota_perdida, mascota_encontrada, puntaje}.
  """
  def buscar_coincidencias do
    reportes = listar()
    perdidas = Enum.filter(reportes, fn m -> m.tipo_reporte == :perdida and m.estado == :activa end)
    encontradas = Enum.filter(reportes, fn m -> m.tipo_reporte == :encontrada and m.estado == :activa end)

    for p <- perdidas, e <- encontradas, p.especie == e.especie do
      puntaje = calcular_puntaje_similitud(p, e)
      {p, e, puntaje}
    end
    |> Enum.filter(fn {_p, _e, puntaje} -> puntaje >= 50 end)
    |> Enum.sort_by(fn {_p, _e, puntaje} -> puntaje end, :desc)
  end

  @doc "Calcula el puntaje de similitud (0 a 100) basándose en atributos compartidos."
  def calcular_puntaje_similitud(m1, m2) do
    puntos_especie = if m1.especie == m2.especie, do: 30, else: 0
    puntos_zona = if m1.zona == m2.zona, do: 25, else: 0
    puntos_color = if m1.color == m2.color, do: 20, else: 0
    puntos_tamaño = if m1.tamaño == m2.tamaño, do: 15, else: 0
    puntos_nombre = if m1.nombre != "" and m1.nombre == m2.nombre, do: 10, else: 0

    puntos_especie + puntos_zona + puntos_color + puntos_tamaño + puntos_nombre
  end

  @doc "Confirma la coincidencia entre dos reportes y los marca como resueltos."
  def confirmar_coincidencia(id_perdida, id_encontrada) do
    mascotas = listar()

    mascotas_actualizadas =
      Enum.map(mascotas, fn m ->
        if m.id == id_perdida or m.id == id_encontrada do
          %{m | estado: :resuelta}
        else
          m
        end
      end)

    Persistencia.guardar_datos(@archivo, mascotas_actualizadas)
    {:ok, "Coincidencia confirmada. Ambos reportes fueron cerrados."}
  end

  defp validar_tipo_reporte(tipo) when tipo in [:perdida, :encontrada], do: :ok
  defp validar_tipo_reporte(_), do: {:error, "Tipo de reporte debe ser :perdida o :encontrada"}
end
