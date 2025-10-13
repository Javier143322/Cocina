-- ====================================================================
-- MÓDULO 3: LADO DEL SERVIDOR (server.lua) - FINAL (Progresión)
-- Añade: Bloqueo por Nivel, Cálculo de Falla Dinámico y Control de Cancelación.
-- ====================================================================

ESX = nil
-- Nuevo: Almacenar estado de cocina para prevenir exploits de cancelación
local PlayersCooking = {} 

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- 1. Las Recetas ahora se leen desde la tabla global 'Config.Recetas'

-- 2. Handler de la verificación de cocina (Llamado al abrir la barra)
ESX.RegisterServerCallback('esx_cocinacasera:cocinarPlato', function(source, cb, platoFinal, tiempo)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.job.name
    local jobGrade = xPlayer.job.grade or 0
    
    if Config.Recetas[platoFinal] then
        local receta = Config.Recetas[platoFinal]

        -- 2A. Bloqueo por Trabajo y Nivel
        if receta.trabajoRequerido and receta.trabajoRequerido ~= job then
            TriggerClientEvent('esx:showNotification', source, '¡~r~ERROR!~w~ No tienes el trabajo requerido para este plato.')
            cb(false)
            return
        end
        if jobGrade < receta.nivelRequerido then
            TriggerClientEvent('esx:showNotification', source, '¡~r~ERROR!~w~ Tu nivel (' .. jobGrade .. ') es insuficiente (Req: ' .. receta.nivelRequerido .. ').')
            cb(false)
            return
        end
        
        local puedeCocinar = true
        
        -- 2B. Verificación de Ingredientes
        for _, ing in pairs(receta.ingredientes) do
            if xPlayer.getInventoryItem(ing.item).count < ing.cantidad then
                puedeCocinar = false
                break
            end
        end

        -- 2C. Si puede cocinar, se inicia el proceso.
        if puedeCocinar then
            -- Marcamos al jugador como "cocinando"
            PlayersCooking[source] = true 
            
            -- Espera segura en el servidor.
            Citizen.Wait(tiempo) 
            
            cb(true) 
            return
        else
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

-- 3. Handler del procesamiento final (Llamado DESPUÉS de la animación)
RegisterServerEvent('esx_cocinacasera:procesarCocina')
AddEventHandler('esx_cocinacasera:procesarCocina', function(platoFinal)
    local xPlayer = ESX.GetPlayerFromId(source)
    local jobGrade = xPlayer.job.grade or 0
    local receta = Config.Recetas[platoFinal]
    
    -- Control de Cancelación: Si el jugador ya canceló, salimos.
    if not PlayersCooking[source] then
        return
    end
    
    -- CALCULAR PROBABILIDAD DE FALLA DINÁMICA
    -- La falla es: baseFalla - (nivel_jugador * 5). Ejemplo: 50 - (3 * 5) = 35%
    local FallaFinal = math.max(receta.baseFalla - (jobGrade * 5), 5) -- Mínimo 5% de falla
    local rand = math.random(1, 100) 
    
    -- Procesamos la receta (quitar ingredientes) antes de dar el plato
    for _, ing in pairs(receta.ingredientes) do
        xPlayer.removeInventoryItem(ing.item, ing.cantidad)
    end
    
    if rand <= FallaFinal then
        -- Falla
        TriggerClientEvent('esx:showNotification', source, '¡~r~FALLÓ!~w~ La receta se quemó (Prob: ' .. FallaFinal .. '%)')
    else
        -- ÉXITO
        xPlayer.addInventoryItem(platoFinal, 1)
        TriggerClientEvent('esx:showNotification', source, 'Has cocinado con éxito: ' .. receta.label .. '!')
    end
    
    -- Limpiamos el estado de cocinando
    PlayersCooking[source] = nil
end)

-- 4. Nuevo evento para manejar cancelaciones del cliente
RegisterServerEvent('esx_cocinacasera:cancelarCocina')
AddEventHandler('esx_cocinacasera:cancelarCocina', function()
    -- Si el cliente cancela, simplemente quitamos el estado de "cocinando"
    -- Esto evita que el plato se entregue después de la barra de progreso
    PlayersCooking[source] = nil
end)

-- 5. Handler para usar el ítem (Ahora también restaura Hambre/Sed)
-- Se mantiene aquí porque se beneficia de la lógica del servidor (ESX.GetPlayerFromId)
ESX.RegisterUsableItem('guisado', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local receta = Config.Recetas['guisado']

    xPlayer.removeInventoryItem('guisado', 1)

    -- Aplicar efectos
    TriggerClientEvent('esx_cocinacasera:restaurarSalud', source, receta.restoreHealth) 
    xPlayer.setHunger(receta.restoreHunger) -- Restaurar hambre
    xPlayer.setThirst(receta.restoreThirst) -- Restaurar sed
    
    TriggerClientEvent('esx:showNotification', source, '¡Te has comido el Guisado Casero y te sientes recuperado!')
end)

ESX.RegisterUsableItem('ensalada', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local receta = Config.Recetas['ensalada']

    xPlayer.removeInventoryItem('ensalada', 1)

    -- Aplicar efectos
    TriggerClientEvent('esx_cocinacasera:restaurarSalud', source, receta.restoreHealth) 
    xPlayer.setHunger(receta.restoreHunger) -- Restaurar hambre
    xPlayer.setThirst(receta.restoreThirst) -- Restaurar sed
    
    TriggerClientEvent('esx:showNotification', source, '¡Qué refrescante estaba esa Ensalada! Te sientes mejor.')
end)