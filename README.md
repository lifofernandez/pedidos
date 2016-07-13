# pedidos
Gestor de pedidos de equipamiento para ATAM

# notas / diseño
Por cada pedido:

Si esta en en el inventario 

* [ ] Revisar integridad del de pedido
    - [x] Sanitizar/Normalizar pedido (mes: 0..12, dia: 0..DINAMICO, HORA: 0..24)
    - [x] limitar duracion a 24 (mas adelante aceptaremos cosas como 72h o 3d)
    - [ ] Armar una par de valores retira-devuelve (devuelve = retira + duracion)
    - [ ] Si tiene previos registros 
        - [ ] Si en ese momento el item del pedido libres
            - [ ] Agregar $pedido junto a los ya existentes (Registrar todas las horas)
        - [ ] Si el item no esta disponible
            - [ ] Informar que el pedido pisa una reserva previa

    - [x] Si no hay registro para este item
        - [ ] Ingresar 1er $pedido (Registrar todas las horas)

* [x] Si el pedido NO esta bien formulado
    - [ ] RECHAZAR

