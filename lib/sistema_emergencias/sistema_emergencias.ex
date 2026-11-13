defmodule SistemaEmergencias do
  @moduledoc """
  Módulo de entrada principal y fachada del Sistema Distribuido de Coordinación de Emergencias.
  Ofrece los comandos interactivos y un menú CLI para la gestión multiusuario del sistema.
  """

  alias SistemaEmergencias.Servicios.{Usuarios, Zonas, Necesidades, Recursos, Personas, Comunicacion, Mascotas, Albergues}
  alias SistemaEmergencias.Procesos.{ServidorRecursos, ServidorNecesidades}

  # GESTIÓN DE SESIÓN DE USUARIOS
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

  # GESTIÓN DE ZONAS

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

  # GESTIÓN DE NECESIDADES Y RECURSOS CONCURRENTE

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

  # PERSONAS Y COMUNICACIÓN FAMILIAR

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

  # MASCOTAS Y ALBERGUES

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

  # RESUMEN GLOBAL DEL SISTEMA (SUMMARY)
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

  # ==========================================
  # MENÚ INTERACTIVO DE CONSOLA (CLI)
  # ==========================================

  @doc "Inicia el bucle recursivo del menú interactivo en terminal."
  def iniciar_menu do
    IO.puts("\n=======================================================")
    IO.puts("   SISTEMA DISTRIBUIDO DE GESTIÓN DE EMERGENCIAS")
    IO.puts("=======================================================")
    IO.puts(" 1. Conectar usuario")
    IO.puts(" 2. Registrar zona y sector inicial")
    IO.puts(" 3. Registrar necesidad de auxilio")
    IO.puts(" 4. Registrar recurso en inventario")
    IO.puts(" 5. Asignar recurso a necesidad (Atómico GenServer)")
    IO.puts(" 6. Reportar persona extraviada")
    IO.puts(" 7. Buscar persona por documento")
    IO.puts(" 8. Enviar mensaje entre familiares")
    IO.puts(" 9. Consultar mensajes de un familiar")
    IO.puts("10. Reportar mascota (perdida / encontrada)")
    IO.puts("11. Buscar coincidencias de mascotas")
    IO.puts("12. Registrar albergue de paso")
    IO.puts("13. Ver resumen consolidado del sistema")
    IO.puts(" 0. Salir del menú")
    IO.puts("=======================================================")

    opcion = IO.gets("Seleccione una opción: ") |> leer_linea()

    case opcion do
      "1" ->
        user = IO.gets("Nombre de usuario: ") |> leer_linea()
        pass = IO.gets("Contraseña: ") |> leer_linea()
        zona = IO.gets("Zona principal: ") |> leer_linea()
        connect(user, pass, :coordinador, zona)
        iniciar_menu()

      "2" ->
        nombre = IO.gets("Nombre de la zona: ") |> leer_linea()
        sector = IO.gets("Nombre del sector principal: ") |> leer_linea()
        afectados = IO.gets("Cantidad de personas afectadas: ") |> leer_entero()
        register_zone(nombre, :critico, [%{nombre: sector, personas_afectadas: afectados}])
        iniciar_menu()

      "3" ->
        tipo = IO.gets("Tipo (agua / alimentos / medicina / refugio): ") |> leer_atomo()
        cantidad = IO.gets("Cantidad requerida: ") |> leer_entero()
        prioridad = IO.gets("Prioridad (critica / alta / media / baja): ") |> leer_atomo()
        zona = IO.gets("Zona afectada: ") |> leer_linea()
        desc = IO.gets("Descripción breve: ") |> leer_linea()
        resp = IO.gets("Usuario responsable: ") |> leer_linea()
        register_need(tipo, cantidad, prioridad, zona, desc, resp)
        iniciar_menu()

      "4" ->
        cod = IO.gets("Código del recurso (ej. R_AGUA): ") |> leer_linea()
        nom = IO.gets("Nombre del recurso: ") |> leer_linea()
        cant = IO.gets("Cantidad disponible: ") |> leer_entero()
        unidad = IO.gets("Unidad de medida (ej. litros, cajas, kits): ") |> leer_linea()
        ubic = IO.gets("Ubicación / Centro de acopio: ") |> leer_linea()
        register_resource(cod, nom, :general, cant, unidad, ubic)
        iniciar_menu()

      "5" ->
        id_nec = IO.gets("ID de la necesidad (ej. NEED001 o número): ") |> leer_linea()
        cod_rec = IO.gets("Código del recurso a asignar: ") |> leer_linea()
        cant = IO.gets("Cantidad a descontar: ") |> leer_entero()
        assign_resource(id_nec, cod_rec, cant)
        iniciar_menu()

      "6" ->
        doc = IO.gets("Documento de identidad: ") |> leer_linea()
        nom = IO.gets("Nombre completo: ") |> leer_linea()
        edad = IO.gets("Edad: ") |> leer_entero()
        zona = IO.gets("Última zona vista: ") |> leer_linea()
        report_person(doc, nom, edad, zona, :reportada)
        iniciar_menu()

      "7" ->
        doc = IO.gets("Documento a buscar: ") |> leer_linea()
        find_person(doc)
        iniciar_menu()

      "8" ->
        dest = IO.gets("Documento o ID del destinatario: ") |> leer_linea()
        rem = IO.gets("Nombre del remitente: ") |> leer_linea()
        msg = IO.gets("Contenido del mensaje: ") |> leer_linea()
        send_family_message(dest, rem, msg)
        iniciar_menu()

      "9" ->
        dest = IO.gets("Documento o ID a consultar: ") |> leer_linea()
        list_family_messages(dest)
        iniciar_menu()

      "10" ->
        estado = IO.gets("Tipo de reporte (perdida / encontrada): ") |> leer_atomo()
        especie = IO.gets("Especie (perro / gato / otro): ") |> leer_linea()
        nombre = IO.gets("Nombre (o 'Desconocido'): ") |> leer_linea()
        desc = IO.gets("Rasgos particulares: ") |> leer_linea()
        color = IO.gets("Color predominante: ") |> leer_linea()
        tamano = IO.gets("Tamaño (pequeño / mediano / grande): ") |> leer_linea()
        zona = IO.gets("Zona donde se vio: ") |> leer_linea()
        tel = IO.gets("Teléfono de contacto: ") |> leer_linea()
        report_pet(estado, especie, nombre, desc, color, tamano, zona, tel)
        iniciar_menu()

      "11" ->
        match_pets()
        iniciar_menu()

      "12" ->
        cod = IO.gets("Código del albergue (ej. ALB_01): ") |> leer_linea()
        nombre = IO.gets("Nombre del albergue: ") |> leer_linea()
        zona = IO.gets("Zona de ubicación: ") |> leer_linea()
        cap = IO.gets("Capacidad máxima de personas: ") |> leer_entero()
        register_shelter(cod, nombre, zona, cap)
        iniciar_menu()

      "13" ->
        summary()
        iniciar_menu()

      "0" ->
        IO.puts("\nCerrando menú interactivo. Los datos quedaron persistidos en priv/datos/.\n")
        :ok

      _ ->
        IO.puts("\n[!] Opción no válida. Intente nuevamente.")
        iniciar_menu()
    end
  end

  # ==========================================
  # FUNCIONES PRIVADAS AUXILIARES
  # ==========================================

  defp imprimir_tabla_necesidades(necesidades) do
    IO.puts("\n--- LISTA DE NECESIDADES (ORDENADAS POR PRIORIDAD) ---")
    Enum.each(necesidades, fn n ->
      IO.puts("[#{n.id}] (#{n.prioridad}) #{n.tipo} x#{n.cantidad} en #{n.zona} - Estado: #{n.estado}")
    end)
  end

  defp leer_linea(:eof), do: ""
  defp leer_linea(texto), do: String.trim(texto)

  defp leer_atomo(entrada) do
    entrada |> leer_linea() |> String.downcase() |> String.to_atom()
  end

  defp leer_entero(entrada) do
    case entrada |> leer_linea() |> Integer.parse() do
      {num, _} -> num
      :error -> 0
    end
  end
end
