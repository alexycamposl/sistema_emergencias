defmodule Mix.Tasks.Demo do
  @moduledoc """
  Tarea personalizada de Mix para ejecutar la demostración completa del sistema con un solo comando.
  Ejecución: mix demo
  """
  use Mix.Task

  @shortdoc "Ejecuta la demostración interactiva del sistema de emergencias"

  @impl Mix.Task
  def run(_args) do
    # 1. Iniciar las aplicaciones del proyecto (arranca el Supervisor y GenServers)
    Mix.Task.run("app.start")

    IO.puts("\n=======================================================")
    IO.puts("    INICIANDO DEMOSTRACIÓN AUTOMATIZADA DEL SISTEMA")
    IO.puts("=======================================================\n")

    # 2. Autenticar coordinador
    SistemaEmergencias.connect("admin", "1234", :coordinador, "Zona Centro")

    # 3. Registrar zona con sectores anidados (Demostración de Recursividad)
    IO.puts("\n---> [1/5] Registrando zona con sectores anidados...")
    SistemaEmergencias.register_zone("Zona Centro", :critico, [
      %{nombre: "Sector Plaza", personas_afectadas: 150},
      %{nombre: "Sector Hospital", subsectores: [
        %{nombre: "Punto Urgencias", personas_afectadas: 80}
      ]}
    ])

    # 4. Registrar recurso e inventario
    IO.puts("\n---> [2/5] Registrando inventario de recursos...")
    SistemaEmergencias.register_resource("R_AGUA", "Agua Potable", :hidratacion, 50, "litros", "Punto_Centro")

    # 5. Registrar necesidad
    IO.puts("\n---> [3/5] Registrando necesidad de auxilio...")
    SistemaEmergencias.register_need(:agua, 30, :critica, "Zona Centro", "Agua urgente para albergue", "admin")

    # 6. Demostración de Concurrencia (GenServer)
    IO.puts("\n---> [4/5] Probando asignación concurrente en GenServer (2 peticiones simultáneas)...")
    t1 = Task.async(fn -> SistemaEmergencias.assign_resource(1, "R_AGUA", 30) end)
    t2 = Task.async(fn -> SistemaEmergencias.assign_resource(1, "R_AGUA", 25) end)
    Task.await(t1)
    Task.await(t2)

    # 7. Comunicación entre familiares
    IO.puts("\n---> [5/5] Enviando y consultando mensajes entre familiares...")
    SistemaEmergencias.send_family_message("1094888999", "Carlos Pérez", "Hola María, me encuentro en el Albergue Central a salvo.")
    SistemaEmergencias.list_family_messages("1094888999")

    # 8. Resumen global
    SistemaEmergencias.summary()

    IO.puts("=======================================================")
    IO.puts("       DEMOSTRACIÓN COMPLETADA EXITOSAMENTE")
    IO.puts("=======================================================\n")
  end
end
