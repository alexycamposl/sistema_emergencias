defmodule SistemaEmergenciasTest do
  use ExUnit.Case
  alias SistemaEmergencias.Servicios.{Zonas, Mascotas, Recursos}
  alias SistemaEmergencias.Procesos.ServidorRecursos

  test "Algoritmo recursivo calcula correctamente los afectados en sectores anidados" do
    sectores = [
      %{nombre: "Sector 1", personas_afectadas: 120},
      %{nombre: "Sector 2", subsectores: [
        %{nombre: "Punto A", personas_afectadas: 50},
        %{nombre: "Punto B", personas_afectadas: 30}
      ]}
    ]

    total = Zonas.contar_afectados_recursivo(sectores)
    assert total == 200
  end

  test "Algoritmo de coincidencias de mascotas calcula puntaje de similitud" do
    m1 = %SistemaEmergencias.Modelos.Mascota{
      especie: "perro", zona: "norte", color: "negro", tamaño: "mediano", nombre: "Luna"
    }
    m2 = %SistemaEmergencias.Modelos.Mascota{
      especie: "perro", zona: "norte", color: "negro", tamaño: "mediano", nombre: "Desconocido"
    }

    puntaje = Mascotas.calcular_puntaje_similitud(m1, m2)
    assert puntaje == 90
  end

  test "Resolución de conflicto concurrente en ServidorRecursos" do
    codigo = "R_TEST_#{System.unique_integer([:positive])}"

    on_exit(fn ->
      {:ok, recursos} = SistemaEmergencias.Utilidades.Persistencia.cargar_datos("recursos.txt")
      recursos_limpios = Enum.reject(recursos, fn r -> String.starts_with?(r.codigo, "R_TEST_") end)
      SistemaEmergencias.Utilidades.Persistencia.guardar_datos("recursos.txt", recursos_limpios)
      ServidorRecursos.recargar_inventario()
    end)

    Recursos.registrar(codigo, "Agua Embotellada", "hidratacion", 50, "litros", "centro_1")
    ServidorRecursos.recargar_inventario()
    :sys.get_state(ServidorRecursos)

    task_a = Task.async(fn -> ServidorRecursos.asignar_recurso(codigo, 30) end)
    task_b = Task.async(fn -> ServidorRecursos.asignar_recurso(codigo, 25) end)

    res_a = Task.await(task_a)
    res_b = Task.await(task_b)

    exitos = Enum.count([res_a, res_b], fn {:ok, _} -> true; _ -> false end)
    errores = Enum.count([res_a, res_b], fn {:error, _} -> true; _ -> false end)

    assert exitos == 1
    assert errores == 1
  end
end
