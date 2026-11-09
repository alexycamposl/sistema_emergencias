defmodule SistemaEmergencias.Servicios.Usuarios do
  @moduledoc """
  Servicio para la gestión de usuarios, registro, autenticación y control de sesión.
  """

  alias SistemaEmergencias.Modelos.Usuario
  alias SistemaEmergencias.Utilidades.Validaciones
  alias SistemaEmergencias.Utilidades.Persistencia

  @archivo "usuarios.txt"

  @doc "Carga todos los usuarios almacenados."
  def listar do
    {:ok, lista} = Persistencia.cargar_datos(@archivo)
    lista
  end

  @doc "Busca un usuario por su nombre de usuario."
  def buscar_por_username(username) do
    usuarios = listar()

    case Enum.find(usuarios, fn u -> u.nombre_usuario == username end) do
      nil -> {:error, "Usuario no encontrado"}
      usuario -> {:ok, usuario}
    end
  end

  @doc """
  Conecta a un usuario. Si no existe, lo registra automáticamente con rol por defecto (:ciudadano).
  Si existe, valida su contraseña.
  """
  def conectar(username, password, tipo \\ :ciudadano, zona \\ "centro") do
    case buscar_por_username(username) do
      {:error, _} ->
        # Registrar automáticamente si no existe
        registrar(username, password, username, tipo, zona)

      {:ok, usuario} ->
        # Validar contraseña si existe
        if usuario.contraseña == password do
          usuario_actualizado = %{usuario | estado: :conectado}
          actualizar_usuario(usuario_actualizado)
          {:ok, usuario_actualizado}
        else
          {:error, "Contraseña incorrecta"}
        end
    end
  end

  @doc "Desconecta un usuario del sistema."
  def desconectar(username) do
    case buscar_por_username(username) do
      {:ok, usuario} ->
        usuario_actualizado = %{usuario | estado: :desconectado}
        actualizar_usuario(usuario_actualizado)
        {:ok, usuario_actualizado}

      error ->
        error
    end
  end

  @doc "Registra un nuevo usuario en el sistema validando campos."
  def registrar(username, password, nombre_completo, tipo, zona) do
    usuarios = listar()

    with {:ok, username_val} <- Validaciones.validar_texto_no_vacio(username),
         {:ok, password_val} <- Validaciones.validar_texto_no_vacio(password),
         {:ok, tipo_val} <- Validaciones.validar_tipo_usuario(tipo),
         :ok <- validar_username_unico(usuarios, username_val) do

      nuevo_id = length(usuarios) + 1

      nuevo_usuario = %Usuario{
        id: nuevo_id,
        nombre_usuario: username_val,
        contraseña: password_val,
        nombre_completo: nombre_completo,
        tipo: tipo_val,
        zona_principal: zona,
        estado: :conectado
      }

      nuevos_usuarios = [nuevo_usuario | usuarios]
      Persistencia.guardar_datos(@archivo, nuevos_usuarios)
      {:ok, nuevo_usuario}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # Auxiliar para actualizar un usuario existente en la lista
  defp actualizar_usuario(usuario_actualizado) do
    usuarios = listar()

    nuevos_usuarios =
      Enum.map(usuarios, fn u ->
        if u.id == usuario_actualizado.id, do: usuario_actualizado, else: u
      end)

    Persistencia.guardar_datos(@archivo, nuevos_usuarios)
  end

  defp validar_username_unico(usuarios, username) do
    if Enum.any?(usuarios, fn u -> u.nombre_usuario == username end) do
      {:error, "El nombre de usuario ya se encuentra registrado"}
    else
      :ok
    end
  end
end
