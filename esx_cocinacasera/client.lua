-- ====================================================================
-- MÓDULO 3: LADO DEL SERVIDOR (server.lua) - FINAL (Refactorizado)
-- Ahora lee toda la información desde el archivo 'config.lua'.
-- ====================================================================

ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- 1. Las Recetas ahora se leen desde la tabla global 'Config.Recetas'

-- 2. Handler (Manejador) de la verificación de cocina (Llamado al abrir la barra)
ESX.RegisterServerCallback('esx_cocinacasera:cocinarPlato', function(source, cb, platoFinal, tiempo)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.job.name
    
    -- A. Validación: ¿Existe la receta?
    if Config.Recetas[platoFinal] then
        local receta = Config.Recetas[platoFinal]

        -- Bloqueo por Trabajo
        if receta.trabajoRequerido and receta.trabajoRequerido ~= job then
            TriggerClientEvent('esx:showNotification', source, '¡~r~ERROR!~w~ No tienes el trabajo requerido para este plato.')
            cb(false)
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
            Citizen.Wait(tiempo) 
            cb(true) 
            return
        else
            -- Mensaje de Error (Faltan Ingredientes)
            TriggerClientEvent('esx:showNotification', source, '¡Te faltan ingredientes para cocinar ' .. receta.label .. '!')
            cb(false)
            return
        end

    else
        print(('ERROR: Plato %s no encontrado en las recetas!'):format(platoFinal))
        cb(false)
        return
    end
end)

-- 3. Handler (Manejador) del procesamiento final (Llamado después de la animación)
RegisterServerEvent('esx_cocinacasera:procesarCocina')
AddEventHandler('esx_cocinacasera:procesarCocina', function(platoFinal)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Usamos la configuración centralizada
    local receta = Config.Recetas[platoFinal]
    
    -- Lógica de Probabilidad de Falla
    local rand = math.random(1, 100) 
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