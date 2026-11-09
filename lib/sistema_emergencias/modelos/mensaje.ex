defmodule SistemaEmergencias.Modelos.Mensaje do

  defstruct id: 0,
            fecha: "",
            remitente: "",
            destinatario: "",
            contenido: "",
            estado: :pendiente

end
