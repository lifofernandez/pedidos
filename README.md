# pedidos
Gestor de pedidos de equipamiento para ATAM
Por cada pedido:
# notas / diseño

Si esta en en el inventario 

    Revisar integridad del de pedido
        Sanitizar/Normalizar pedido (mes: 0..12, dia: 0..DINAMICO, HORA: 0..24)+
    
        limitar duracion a 24 (mas adelante aceptaremos cosas como 72h o 3d)

        Y Armar una lista para cada hora (valor = index - duracion)

    Si tiene previos registros 
        Si todas las horas que abarca el pedido estan libres
                Agregar $pedido junto a los ya existentes (Registrar todas las horas)
        else
            Informar que el pedido pisa una reserva previa

    else
        Ingresar 1er $pedido (Registrar todas las horas)

else
    RECHAZAR

