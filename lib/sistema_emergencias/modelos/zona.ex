defmodule SistemaEmergencias.Modelos.Zona do

  defstruct id: 0,
            nombre: "",
            nivel_afectacion: :bajo,
            sectores: []

end
defmodule SistemaEmergencias.Zonas.Sector do

  defstruct [
    :id,
    :nombre,
    puntos_atencion: []
  ]

end
defmodule SistemaEmergencias.Zonas.PuntoAtencion do

  defstruct [
    :id,
    :nombre,
    :ubicacion
  ]

end
