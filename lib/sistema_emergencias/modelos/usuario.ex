defmodule SistemaEmergencias.Modelos.Usuario do

  defstruct id: 0,
            nombre_usuario: "",
            contraseña: "",
            nombre_completo: "",
            tipo: :ciudadano,
            zona_principal: "",
            estado: :desconectado

end
