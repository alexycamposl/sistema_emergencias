defmodule SistemaEmergencias.Utilidades.Validaciones do
  @moduledoc """
  Módulo de utilidades para validación de datos de entrada y reglas de negocio.
  Aplica Pattern Matching, Guards y retorno de tuplas {:ok, dato} / {:error, razon}.
  """

  # ==========================================
  # VALIDACIONES GENERALES DE TEXTO Y NÚMEROS
  # ==========================================

  @doc "Valida que una cadena de texto no esté vacía ni contenga solo espacios."
  def validar_texto_no_vacio(texto) when is_binary(texto) do
    if String.trim(texto) == "" do
      {:error, "El campo de texto no puede estar vacío"}
    else
      {:ok, String.trim(texto)}
    end
  end

  def validar_texto_no_vacio(_), do: {:error, "El dato proporcionado debe ser un texto"}

  @doc "Valida que una cantidad numérica sea estrictamente mayor a cero."
  def validar_cantidad_positiva(numero) when is_number(numero) and numero > 0 do
    {:ok, numero}
  end

  def validar_cantidad_positiva(numero) when is_number(numero) and numero <= 0 do
    {:error, "La cantidad debe ser un número positivo mayor a cero"}
  end

  def validar_cantidad_positiva(_), do: {:error, "La cantidad debe ser numérica"}

  @doc "Valida que un número no sea negativo (permite cero)."
  def validar_no_negativo(numero) when is_number(numero) and numero >= 0 do
    {:ok, numero}
  end

  def validar_no_negativo(_), do: {:error, "El valor no puede ser negativo"}

  # ==========================================
  # VALIDACIONES DE DOMINIO ESPECÍFICAS
  # ==========================================

  @doc "Valida que el tipo de usuario pertenezca a los roles permitidos."
  def validar_tipo_usuario(tipo) when tipo in [:ciudadano, :voluntario, :coordinador, :administrador] do
    {:ok, tipo}
  end

  def validar_tipo_usuario(_), do: {:error, "Tipo de usuario no válido. Roles permitidos: :ciudadano, :voluntario, :coordinador, :administrador"}

  @doc "Valida que el nivel de afectación de una zona sea válido."
  def validar_nivel_afectacion(nivel) when nivel in [:critico, :alto, :medio, :bajo] do
    {:ok, nivel}
  end

  def validar_nivel_afectacion(_), do: {:error, "Nivel de afectación no válido. Permitidos: :critico, :alto, :medio, :bajo"}

  @doc "Valida los tipos de necesidad registrados."
  def validar_tipo_necesidad(tipo) when tipo in [:agua, :alimentos, :medicamentos, :primeros_auxilios, :refugio, :transporte, :rescate, :otro] do
    {:ok, tipo}
  end

  def validar_tipo_necesidad(_), do: {:error, "Tipo de necesidad no válido"}

  @doc "Valida la prioridad de una necesidad para ordenar la atención."
  def validar_prioridad(prioridad) when prioridad in [:critica, :alta, :media, :baja] do
    {:ok, prioridad}
  end

  def validar_prioridad(_), do: {:error, "Prioridad no válida. Permitidos: :critica, :alta, :media, :baja"}

  # ==========================================
  # TRANSICIONES DE ESTADO
  # ==========================================

  @doc "Valida que una necesidad no cambie a un estado no permitido (ej. una necesidad atendida no se reactiva)."
  def validar_transicion_necesidad(estado_actual, estado_nuevo) do
    transiciones_validas = %{
      pendiente: [:asignada, :cancelada],
      asignada: [:en_atencion, :cancelada],
      en_atencion: [:atendida, :cancelada],
      atendida: [],
      cancelada: []
    }

    permitidos = Map.get(transiciones_validas, estado_actual, [])

    if estado_nuevo in permitidos do
      {:ok, estado_nuevo}
    else
      {:error, "Transición no permitida de #{inspect(estado_actual)} a #{inspect(estado_nuevo)}"}
    end
  end

  @doc "Valida que la capacidad asignada a un albergue no sea superada por la ocupación actual."
  def validar_capacidad_albergue(ocupacion_actual, incremento, capacidad_maxima)
      when is_integer(ocupacion_actual) and is_integer(incremento) and is_integer(capacidad_maxima) do
    nueva_ocupacion = ocupacion_actual + incremento

    cond do
      nueva_ocupacion < 0 ->
        {:error, "La ocupación resultante no puede ser negativa"}

      nueva_ocupacion > capacidad_maxima ->
        {:error, "La operación supera la capacidad máxima del albergue (#{capacidad_maxima})"}

      true ->
        {:ok, nueva_ocupacion}
    end
  end
end
