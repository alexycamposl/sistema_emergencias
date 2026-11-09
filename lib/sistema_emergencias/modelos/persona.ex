defmodule SistemaEmergencias.Modelos.Persona do

  defstruct id: 0,
            nombre: "",
            documento: "",
            edad: 0,
            zona: "",
            estado: :reportada,
            historial: []

end
