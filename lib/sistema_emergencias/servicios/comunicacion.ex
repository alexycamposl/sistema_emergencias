defmodule SistemaEmergencias.Servicios.Comunicacion do
  @moduledoc """
  Servicio  para la comunicación entre familiares y registro de mensajes.
  """

  alias SistemaEmergencias.Modelos.Mensaje
  alias SistemaEmergencias.Utilidades.Validaciones
  alias SistemaEmergencias.Utilidades.Persistencia

  @archivo "mensajes.txt"

  def listar do
    {:ok, lista} = Persistencia.cargar_datos(@archivo)
    lista
  end

  @doc "Envía/Registra un mensaje para un familiar o persona afectada."
  def enviar_mensaje(remitente, destinatario, contenido) do
    mensajes = listar()

    with {:ok, rem_val} <- Validaciones.validar_texto_no_vacio(remitente),
         {:ok, dest_val} <- Validaciones.validar_texto_no_vacio(destinatario),
         {:ok, cont_val} <- Validaciones.validar_texto_no_vacio(contenido) do

      nuevo_id = length(mensajes) + 1
      fecha_actual = Date.to_string(Date.utc_today())

      nuevo_mensaje = %Mensaje{
        id: nuevo_id,
        fecha: fecha_actual,
        remitente: rem_val,
        destinatario: dest_val,
        contenido: cont_val,
        estado: :pendiente
      }

      Persistencia.guardar_datos(@archivo, [nuevo_mensaje | mensajes])
      {:ok, nuevo_mensaje}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc "Lista todos los mensajes dirigidos a una persona (por documento o nombre)."
  def listar_mensajes_destinatario(destinatario) do
    listar()
    |> Enum.filter(fn m -> m.destinatario == destinatario end)
  end

  @doc "Marca un mensaje como entregado."
  def marcar_entregado(id_mensaje) do
    mensajes = listar()

    case Enum.find(mensajes, fn m -> m.id == id_mensaje end) do
      nil ->
        {:error, "Mensaje no encontrado"}

      mensaje ->
        mensaje_act = %{mensaje | estado: :entregado}
        nuevos = Enum.map(mensajes, fn m -> if m.id == id_mensaje, do: mensaje_act, else: m end)
        Persistencia.guardar_datos(@archivo, nuevos)
        {:ok, mensaje_act}
    end
  end
end
