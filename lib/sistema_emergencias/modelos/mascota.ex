defmodule SistemaEmergencias.Modelos.Mascota do

  defstruct id: 0,
            tipo_reporte: :perdida,
            especie: "",
            nombre: "",
            caracteristicas: "",
            color: "",
            tamaño: "",
            zona: "",
            contacto: "",
            estado: :activa

end
