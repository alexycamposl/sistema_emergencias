defmodule SistemaEmergencias.Modelos.Necesidad do

  defstruct id: 0,
            tipo: :otro,
            descripcion: "",
            cantidad: 0,
            zona: "",
            prioridad: :baja,
            responsable: "",
            estado: :pendiente

end
