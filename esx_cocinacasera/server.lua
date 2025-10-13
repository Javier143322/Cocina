-- ====================================================================
-- MÓDULO 3: LADO DEL SERVIDOR (server.lua) - FINAL
-- Añade: Bloqueo por Trabajo, Probabilidad de Falla, y lógica de retraso.
-- ====================================================================

ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- 1. Definición de las recetas (¡DEBE COINCIDIR CON CLIENTE!)
local Recetas = {
    ['guisado'] = {
        label = 'Guisado Casero',
        ingredientes = {
            { item = 'carne', cantidad = 2 },
            { item = 'vegetales', cantidad = 1 },
            { item = 'sal', cantidad = 1 }
        },
        trabajoRequerido = 'chef', -- Necesita ser chef
        probabilidadFalla = 15 -- 15% de probabilidad de falla
    },
    ['ensalada'] = {
        label = 'Ensalada Refrescante',
        ingredientes = {
            { item = 'vegetales', cantidad = 3 }
        },
        trabajoRequerido = nil,
        probabilidadFalla = 5 -- 5% de probabilidad de falla
    }
}

-- 2. Handler (Manejador) de la verificación de cocina (Llamado al abrir la barra)
RegisterServerEvent('esx_cocinacasera:cocinarPlato')
AddEventHandler('esx_cocinacasera:cocinarPlato', function(platoFinal, tiempo)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.job.name
    
    -- A. Validación: ¿Existe la receta?
    if Recetas[platoFinal] then
        local receta = Recetas[platoFinal]

        -- Bloqueo por Trabajo
        if receta.trabajoRequerido and receta.trabajoRequerido ~= job then
            TriggerClientEvent('esx:showNotification', source, '¡~r~ERROR!~w~ No tienes el trabajo requerido para este plato.')
            return
        end
        
        local puedeCocinar = true
        
        -- B. Verificación de Ingredientes
        for _, ing in pairs(receta.ingredientes) do
            if xPlayer.getInventoryItem(ing.item).count < ing.cantidad then
                puedeCocinar = false
                break
            end
        end

        -- C. Si puede cocinar, detenemos el script por el tiempo de la animación.
        if puedeCocinar then
            -- Devolvemos TRUE al callback del cliente, permitiendo que inicie la animación
            -- La lógica de consumo y entrega se hace DESPUÉS del tiempo de espera.
            Citizen.Wait(tiempo) 
            
            -- Devolvemos el control al cliente para que sepa que la espera terminó
            -- El resultado TRUE indica que el proceso puede continuar.
            return true 
        else
            -- Mensaje de Error (Faltan Ingredientes)
            TriggerClientEvent('esx:showNotification', source, '¡Te faltan ingredientes para cocinar ' .. receta.label .. '!')
            return false
        end

    else
        print(('ERROR: Plato %s no encontrado en las recetas!'):format(platoFinal))
        return false
    end
end)

-- 3. Handler (Manejador) del procesamiento final (Llamado después de la animación)
RegisterServerEvent('esx_cocinacasera:procesarCocina')
AddEventHandler('esx_cocinacasera:procesarCocina', function(platoFinal)
    local xPlayer = ESX.GetPlayerFromId(source)
    local receta = Recetas[platoFinal]
    
    -- Lógica de Probabilidad de Falla
    local rand = math.random(1, 100) -- Genera un número del 1 al 100
    if rand <= receta.probabilidadFalla then
        -- Falla: Solo se consumen los ingredientes, no se da el plato
        for _, ing in pairs(receta.ingredientes) do
            xPlayer.removeInventoryItem(ing.item, ing.cantidad)
        end
        TriggerClientEvent('esx:showNotification', source, '¡~r~FALLÓ!~w~ La receta se quemó o la arruinaste. ¡Mejor suerte la próxima!')
        return
    end

    -- ÉXITO: Procesamiento de la Receta
    
    -- 1. Consumir Ingredientes
    for _, ing in pairs(receta.ingredientes) do
        xPlayer.removeInventoryItem(ing.item, ing.cantidad)
    end

    -- 2. Dar Plato Final al Jugador
    xPlayer.addInventoryItem(platoFinal, 1)

    -- 3. Mensaje de Éxito
    TriggerClientEvent('esx:showNotification', source, 'Has cocinado con éxito: ' .. receta.label .. '!')
end)