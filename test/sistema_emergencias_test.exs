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
    Recursos.registrar("R_TEST_01", "Agua Embotellada", "hidratacion", 50, "litros", "centro_1")
    ServidorRecursos.recargar_inventario()

    task_a = Task.async(fn -> ServidorRecursos.asignar_recurso("R_TEST_01", 30) end)
    task_b = Task.async(fn -> ServidorRecursos.asignar_recurso("R_TEST_01", 25) end)

    res_a = Task.await(task_a)
    res_b = Task.await(task_b)

    exitos = Enum.count([res_a, res_b], fn {:ok, _} -> true; _ -> false end)
    errores = Enum.count([res_a, res_b], fn {:error, _} -> true; _ -> false end)

    assert exitos == 1
    assert errores == 1
  end
end
