defmodule SistemaEmergencias.Servicios.Personas do
  @moduledoc """
  Servicio para registrar y consultar personas afectadas tras la emergencia.
  """

  alias SistemaEmergencias.Modelos.Persona
  alias SistemaEmergencias.Utilidades.Validaciones
  alias SistemaEmergencias.Utilidades.Persistencia

  @archivo "personas.txt"

  def listar do
    {:ok, lista} = Persistencia.cargar_datos(@archivo)
    lista
  end

  @doc "Registra un reporte de persona afectada."
  def registrar(documento, nombre, edad, zona, estado \\ :reportada) do
    personas = listar()

    with {:ok, doc_val} <- Validaciones.validar_texto_no_vacio(documento),
         {:ok, nom_val} <- Validaciones.validar_texto_no_vacio(nombre),
         {:ok, edad_val} <- Validaciones.validar_no_negativo(edad) do

      nuevo_id = length(personas) + 1
      historial_inicial = [{DateTime.utc_now(), estado}]

      nueva_persona = %Persona{
        id: nuevo_id,
        documento: doc_val,
        nombre: nom_val,
        edad: edad_val,
        zona: zona,
        estado: estado,
        historial: historial_inicial
      }

      Persistencia.guardar_datos(@archivo, [nueva_persona | personas])
      {:ok, nueva_persona}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc "Busca una persona por su número de documento o nombre."
  def buscar_por_documento(documento) do
    case Enum.find(listar(), fn p -> p.documento == documento end) do
      nil -> {:error, "Persona no encontrada"}
      persona -> {:ok, persona}
    end
  end

  @doc "Actualiza el estado de la persona guardando el cambio en el historial."
  def actualizar_estado(documento, nuevo_estado) do
    personas = listar()

    case Enum.find(personas, fn p -> p.documento == documento end) do
      nil ->
        {:error, "Persona no encontrada"}

      persona ->
        nuevo_historial = [{DateTime.utc_now(), nuevo_estado} | persona.historial]
        persona_act = %{persona | estado: nuevo_estado, historial: nuevo_historial}

        nuevas = Enum.map(personas, fn p -> if p.documento == documento, do: persona_act, else: p end)
        Persistencia.guardar_datos(@archivo, nuevas)
        {:ok, persona_act}
    end
  end
end
