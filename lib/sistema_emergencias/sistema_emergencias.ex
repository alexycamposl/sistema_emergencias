defmodule SistemaEmergencias do
  @moduledoc """
  Módulo de entrada principal y fachada del Sistema Distribuido de Coordinación de Emergencias.
  Ofrece los comandos interactivos para la gestión multiusuario del sistema.
  """

  alias SistemaEmergencias.Servicios.{Usuarios, Zonas, Necesidades, Recursos, Personas, Comunicacion, Mascotas, Albergues}
  alias SistemaEmergencias.Procesos.{ServidorRecursos, ServidorNecesidades}

  # Variable de módulo para mantener la sesión activa simple
  @doc "Conecta a un usuario en el sistema. Registra automáticamente si no existe."
  def connect(username, password, tipo \\ :ciudadano, zona \\ "centro") do
    case Usuarios.conectar(username, password, tipo, zona) do
      {:ok, usuario} ->
        IO.puts("========== SESIÓN INICIADA ==========")
        IO.puts("Bienvenido(a) #{usuario.nombre_completo} [Rol: #{usuario.tipo} | Zona: #{usuario.zona_principal}]")
        {:ok, usuario}

      {:error, razon} ->
        IO.puts("Error de autenticación: #{razon}")
        {:error, razon}
    end
  end

  @doc "Desconecta la sesión de un usuario."
  def disconnect(username) do
    case Usuarios.desconectar(username) do
      {:ok, _} ->
        IO.puts("Sesión cerrada exitosamente.")
        :ok

      {:error, razon} ->
        IO.puts("Error al cerrar sesión: #{razon}")
        {:error, razon}
    end
  end

  # ==========================================
  # GESTIÓN DE ZONAS
  # ==========================================

  def register_zone(nombre, nivel_afectacion, sectores \\ []) do
    case Zonas.registrar(nombre, nivel_afectacion, sectores) do
      {:ok, zona} ->
        IO.puts("Zona '#{zona.nombre}' registrada correctamente (Nivel: #{zona.nivel_afectacion}).")
        {:ok, zona}

      {:error, razon} ->
        IO.puts("Error al registrar zona: #{razon}")
        {:error, razon}
    end
  end

  # ==========================================
  # GESTIÓN DE NECESIDADES Y RECURSOS CONCURRENTE
  # ==========================================

  def register_need(tipo, cantidad, prioridad, zona, descripcion, responsable \\ "anonimo") do
    case Necesidades.registrar(tipo, cantidad, prioridad, zona, descripcion, responsable) do
      {:ok, necesidad} ->
        IO.puts("Necesidad registrada con éxito -> ID: #{necesidad.id} [Prioridad: #{necesidad.prioridad}]")
        {:ok, necesidad}

      {:error, razon} ->
        IO.puts("Error al registrar necesidad: #{razon}")
        {:error, razon}
    end
  end

  def list_needs do
    necesidades = Necesidades.listar_ordenadas_por_prioridad()
    imprimir_tabla_necesidades(necesidades)
    necesidades
  end

  def register_resource(codigo, nombre, categoria, cantidad, unidad, ubicacion) do
    case Recursos.registrar(codigo, nombre, categoria, cantidad, unidad, ubicacion) do
      {:ok, recurso} ->
        # Notificar al GenServer para actualizar inventario en memoria
        ServidorRecursos.recargar_inventario()
        IO.puts("Recurso '#{recurso.nombre}' [#{recurso.codigo}] registrado con #{recurso.cantidad_disponible} #{recurso.unidad}.")
        {:ok, recurso}

      {:error, razon} ->
        IO.puts("Error al registrar recurso: #{razon}")
        {:error, razon}
    end
  end

  def list_resources do
    recursos = Recursos.listar()
    IO.puts("\n--- INVENTARIO GENERAL DE RECURSOS ---")
    Enum.each(recursos, fn r ->
      IO.puts("[#{r.codigo}] #{r.nombre}: #{r.cantidad_disponible} #{r.unidad} en #{r.ubicacion}")
    end)
    recursos
  end

  @doc "Asigna recursos a una necesidad usando el GenServer concurrente."
  def assign_resource(id_necesidad, codigo_recurso, cantidad) do
    case ServidorNecesidades.atender_necesidad(id_necesidad, codigo_recurso, cantidad) do
      {:ok, mensaje} ->
        IO.puts("ÉXITO: #{mensaje}")
        {:ok, mensaje}

      {:error, razon} ->
        IO.puts("RECHAZADO: #{razon}")
        {:error, razon}
    end
  end

  # ==========================================
  # PERSONAS Y COMUNICACIÓN FAMILIAR
  # ==========================================

  def report_person(documento, nombre, edad, zona, estado \\ :reportada) do
    Personas.registrar(documento, nombre, edad, zona, estado)
  end

  def find_person(documento) do
    case Personas.buscar_por_documento(documento) do
      {:ok, p} ->
        IO.puts("Persona encontrada: #{p.nombre} | Estado: #{p.estado} | Zona: #{p.zona}")
        {:ok, p}

      {:error, r} ->
        IO.puts(r)
        {:error, r}
    end
  end

  def send_family_message(destinatario, remitente, contenido) do
    Comunicacion.enviar_mensaje(remitente, destinatario, contenido)
  end

  def list_family_messages(destinatario) do
    mensajes = Comunicacion.listar_mensajes_destinatario(destinatario)
    IO.puts("\n--- MENSAJES PARA #{destinatario} ---")
    Enum.each(mensajes, fn m ->
      IO.puts("[#{m.fecha}] De #{m.remitente}: \"#{m.contenido}\" (#{m.estado})")
    end)
    mensajes
  end

  # ==========================================
  # MASCOTAS Y ALBERGUES
  # ==========================================

  def report_pet(tipo_reporte, especie, nombre, caracteristicas, color, tamaño, zona, contacto) do
    Mascotas.registrar(tipo_reporte, especie, nombre, caracteristicas, color, tamaño, zona, contacto)
  end

  def match_pets do
    coincidencias = Mascotas.buscar_coincidencias()
    IO.puts("\n--- BÚSQUEDA DE COINCIDENCIAS DE MASCOTAS ---")
    Enum.each(coincidencias, fn {p, e, score} ->
      IO.puts("Coincidencia (#{score}%): Perdida [ID:#{p.id} #{p.nombre}] <-> Encontrada [ID:#{e.id} en #{e.zona}]")
    end)
    coincidencias
  end

  def register_shelter(codigo, nombre, zona, capacidad_maxima) do
    Albergues.registrar(codigo, nombre, zona, capacidad_maxima)
  end

  # ==========================================
  # RESUMEN GLOBAL DEL SISTEMA (SUMMARY)
  # ==========================================

  @doc "Genera un resumen consolidado de todo el estado actual del sistema."
  def summary do
    IO.puts("\n=======================================================")
    IO.puts("     RESUMEN GLOBAL DE LA GESTIÓN DE EMERGENCIA")
    IO.puts("=======================================================")
    IO.puts("Zonas registradas: #{length(Zonas.listar())}")
    IO.puts("Necesidades pendientes: #{length(Necesidades.filtrar([{:estado, :pendiente}]))}")
    IO.puts("Recursos registrados: #{length(Recursos.listar())}")
    IO.puts("Personas registradas: #{length(Personas.listar())}")
    IO.puts("Mascotas registradas: #{length(Mascotas.listar())}")
    IO.puts("Albergues activos: #{length(Albergues.listar())}")
    IO.puts("=======================================================\n")
    :ok
  end

  defp imprimir_tabla_necesidades(necesidades) do
    IO.puts("\n--- LISTA DE NECESIDADES (ORDENADAS POR PRIORIDAD) ---")
    Enum.each(necesidades, fn n ->
      IO.puts("[#{n.id}] (#{n.prioridad}) #{n.tipo} x#{n.cantidad} en #{n.zona} - Estado: #{n.estado}")
    end)
  end
end
