defmodule SistemaEmergencias.Utilidades.Persistencia do
  @moduledoc """
  Módulo encargado de la persistencia de datos en archivos de texto plano (.txt).
  Utiliza File, Path y Streams para transformar las entidades a formato persistente.
  """

  # Ruta base relativa a la aplicación Mix
  @dir_datos Path.join([File.cwd!(), "priv", "datos"])

  # ==========================================
  # FUNCIONES PÚBLICAS DE LECTURA Y ESCRITURA
  # ==========================================

  @doc """
  Guarda una lista de registros (structs o mapas) en un archivo .txt especificado.
  Cada línea corresponde a una entidad en formato serializado (formato Elixir inspeccionado o CSV plano).
  """
  def guardar_datos(nombre_archivo, lista_registros) when is_list(lista_registros) do
    ruta_completa = obtener_ruta_archivo(nombre_archivo)

    # Garantizar que el directorio exista
    File.mkdir_p!(@dir_datos)

    contenido =
      lista_registros
      |> Stream.map(&serializar_registro/1)
      |> Enum.join("\n")

    case File.write(ruta_completa, contenido) do
      :ok -> {:ok, "Datos guardados correctamente en #{nombre_archivo}"}
      {:error, razon} -> {:error, "Error al escribir en archivo: #{inspect(razon)}"}
    end
  end

  @doc """
  Lee un archivo .txt y retorna una lista con las líneas deserializadas.
  Si el archivo no existe, retorna una lista vacía `{:ok, []}` de forma segura.
  """
  def cargar_datos(nombre_archivo) do
    ruta_completa = obtener_ruta_archivo(nombre_archivo)

    if File.exists?(ruta_completa) do
      registros =
        ruta_completa
        |> File.stream!()
        |> Stream.map(&String.trim/1)
        |> Stream.reject(&(&1 == ""))
        |> Stream.map(&deserializar_registro/1)
        |> Enum.reject(&is_nil/1)

      {:ok, registros}
    else
      {:ok, []}
    end
  end

  # ==========================================
  # FUNCIONES PRIVADAS DE CONVERSIÓN Y RUTA
  # ==========================================

  defp obtener_ruta_archivo(nombre_archivo) do
    Path.join(@dir_datos, nombre_archivo)
  end

  # Transforma un struct/mapa de Elixir a una representación en texto evaluable
  defp serializar_registro(registro) do
    inspect(registro, limit: :infinity, printable_limit: :infinity)
  end

  # Convierte la línea de texto de vuelta a un término/struct de Elixir de forma segura
  defp deserializar_registro(linea_texto) do
    case Code.string_to_quoted(linea_texto) do
      {:ok, quoted} ->
        {resultado, _} = Code.eval_quoted(quoted)
        resultado
      _ ->
        nil
    end
  rescue
    _ -> nil
  end
end
