defmodule SistemaEmergencias.Servicios.Recursos do
  @moduledoc """
  Servicio para gestionar el inventario de recursos y transferencias entre puntos de atención.
  """

  alias SistemaEmergencias.Modelos.Recurso
  alias SistemaEmergencias.Utilidades.Validaciones
  alias SistemaEmergencias.Utilidades.Persistencia

  @archivo "recursos.txt"

  def listar do
    {:ok, lista} = Persistencia.cargar_datos(@archivo)
    lista
  end

  @doc "Registra un nuevo recurso en el sistema."
  def registrar(codigo, nombre, categoria, cantidad, unidad, ubicacion) do
    recursos = listar()

    with {:ok, cod_val} <- Validaciones.validar_texto_no_vacio(codigo),
         {:ok, nom_val} <- Validaciones.validar_texto_no_vacio(nombre),
         {:ok, cant_val} <- Validaciones.validar_no_negativo(cantidad),
         :ok <- validar_codigo_unico(recursos, cod_val) do

      nuevo_recurso = %Recurso{
        codigo: cod_val,
        nombre: nom_val,
        categoria: categoria,
        cantidad_disponible: cant_val,
        unidad: unidad,
        ubicacion: ubicacion
      }

      Persistencia.guardar_datos(@archivo, [nuevo_recurso | recursos])
      {:ok, nuevo_recurso}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc "Busca un recurso por su código."
  def buscar_por_codigo(codigo) do
    case Enum.find(listar(), fn r -> r.codigo == codigo end) do
      nil -> {:error, "Recurso no encontrado"}
      recurso -> {:ok, recurso}
    end
  end

  @doc "Transfiere inventario de un recurso desde una ubicación hacia otra."
  def transferir(codigo_recurso, origen, destino, cantidad) do
    recursos = listar()

    with {:ok, cant_val} <- Validaciones.validar_cantidad_positiva(cantidad),
         {:ok, recurso} <- buscar_por_codigo(codigo_recurso),
         :ok <- validar_origen(recurso, origen),
         :ok <- validar_disponibilidad(recurso, cant_val) do

      # Restar origen y actualizar lista
      recursos_actualizados =
        recursos
        |> Enum.map(fn r ->
          if r.codigo == codigo_recurso and r.ubicacion == origen do
            %{r | cantidad_disponible: r.cantidad_disponible - cant_val}
          else
            r
          end
        end)

      # Agregar/actualizar en destino
      recurso_destino = %{recurso | ubicacion: destino, cantidad_disponible: cant_val}
      nuevos_recursos = [recurso_destino | recursos_actualizados]

      Persistencia.guardar_datos(@archivo, nuevos_recursos)
      {:ok, "Transferencia de #{cant_val} #{recurso.unidad} realizada exitosamente"}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  defp validar_codigo_unico(recursos, codigo) do
    if Enum.any?(recursos, fn r -> r.codigo == codigo end) do
      {:error, "Ya existe un recurso con ese código"}
    else
      :ok
    end
  end

  defp validar_origen(recurso, origen) do
    if recurso.ubicacion == origen do
      :ok
    else
      {:error, "El recurso no se encuentra en la ubicación de origen"}
    end
  end

  defp validar_disponibilidad(recurso, cantidad) do
    if recurso.cantidad_disponible >= cantidad do
      :ok
    else
      {:error, "Inventario insuficiente para la transferencia"}
    end
  end
end
