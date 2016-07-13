# pedidos
Gestor de pedidos de equipamiento para ATAM

# notas / diseño
Por cada pedido:

* [x] Si el item ESTÁ en en el inventario 
    - [x] Revisar integridad del de pedido
        + [x] Sanitizar/Normalizar pedido (mes: 0..12, dia: 0..DINAMICO, HORA: 0..23)
        + [x] Limitar duracion a 24 (mas adelante aceptaremos cosas como 72h o 3d)

        + [x] Si el pedido esta BIEN formulado
            * [x] Obtener timestamp del pedido
            * [x] Calcuar cuando lo devuelve (devuelve = retira + duracion)
            * [ ] Armar una par de valores retira-devuelve 
            * [ ] Si tiene previos registros 
                * [ ] Si en ese momento el item del pedido esta LIBRE
                    * [ ] Agregar $pedido junto a los ya existentes
                * [ ] Si el item no esta disponible
                    * [ ] RECHAZAR: Informando que el pedido pisa una reserva previa

            * [x] Si no hay registro para este item
                * [ ] Ingresar 1er $pedido (Registrar todas las horas)

        + [x] Si el pedido esta MAL formulado
            * [x] RECHAZAR

* [x] Si el item NO está en en el inventario
    - [x] RECHAZAR




# Estructura 

item
    ID:{entra=>'13423',sale=>'13423',quien,comentario,cuando}
    ID:{entra=>'13423',sale=>'13423',quien,comentario,cuando}
    

item
    resrvas
        ID:[entra,sale]
        ID:[entra,sale]