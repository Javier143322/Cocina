-- ====================================================================
-- MÓDULO 3: LADO DEL SERVIDOR (server.lua) - FINAL (Profesional)
-- Añade: Lógica de Consumo Universal (Modularidad).
-- ====================================================================

ESX = nil
local PlayersCooking = {} 

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- 1. LÓGICA DE CONSUMO UNIVERSAL (Modularidad)
Citizen.CreateThread(function()
    -- Recorre TODAS las recetas definidas en config.lua
    for item, receta in pairs(Config.Recetas) do
        -- Registra un manejador de uso genérico para este ítem
        ESX.RegisterUsableItem(item, function(source)
            local xPlayer = ESX.GetPlayerFromId(source)

            -- 1. Quitar el ítem del inventario
            xPlayer.removeInventoryItem(item, 1)

            -- 2. Aplicar efectos (salud, hambre, sed)
            TriggerClientEvent('esx_cocinacasera:restaurarSalud', source, receta.restoreHealth) 
            xPlayer.setHunger(receta.restoreHunger) -- Restaurar hambre
            xPlayer.setThirst(receta.restoreThirst) -- Restaurar sed
            
            -- 3. Feedback
            TriggerClientEvent('esx:showNotification', source, '¡Disfrutaste de ' .. receta.label .. '!')
        end)
    end
end)


-- 2. Handler de la verificación de cocina (Llamado al abrir la barra)
ESX.RegisterServerCallback('esx_cocinacasera:cocinarPlato', function(source, cb, platoFinal, tiempo)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.job.name
    local jobGrade = xPlayer.job.grade or 0
    
    if Config.Recetas[platoFinal] then
        local receta = Config.Recetas[platoFinal]

        -- Bloqueo por Trabajo y Nivel
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
        
        -- Verificación de Ingredientes
        for _, ing in pairs(receta.ingredientes) do
            if xPlayer.getInventoryItem(ing.item).count < ing.cantidad then
                puedeCocinar = false
                break
            end
        end

        -- Si puede cocinar, se inicia el proceso.
        if puedeCocinar then
            PlayersCooking[source] = true 
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
    
    -- Control de Cancelación
    if not PlayersCooking[source] then
        return
    end
    
    -- CALCULAR PROBABILIDAD DE FALLA DINÁMICA
    local FallaFinal = math.max(receta.baseFalla - (jobGrade * 5), 5) 
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
    
    PlayersCooking[source] = nil
end)

-- 4. Evento para manejar cancelaciones del cliente
RegisterServerEvent('esx_cocinacasera:cancelarCocina')
AddEventHandler('esx_cocinacasera:cancelarCocina', function()
    PlayersCooking[source] = nil
end)