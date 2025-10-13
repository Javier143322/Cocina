-- ====================================================================
-- MÓDULO 4: LÓGICA DE CONSUMO (fx_items.lua)
-- Define qué hace la comida al ser USADA desde el inventario.
-- (Sin cambios, se mantiene la versión original)
-- ====================================================================

ESX = nil

-- Inicializar ESX
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- 1. Nuevo Evento del Cliente para Restaurar Salud
-- Este evento es activado por el servidor para ejecutar la función nativa GTA en el cliente.
RegisterNetEvent('esx_cocinacasera:restaurarSalud')
AddEventHandler('esx_cocinacasera:restaurarSalud', function(cantidad)
    local playerPed = PlayerPedId()
    local health = GetEntityHealth(playerPed)

    -- La salud máxima de un jugador a pie es 200 (100 de barra visible + 100 extra)
    -- math.min asegura que la salud no exceda el máximo (200)
    local newHealth = math.min(health + cantidad, 200) 

    -- Aplicar la nueva salud (Función nativa de GTA V)
    SetEntityHealth(playerPed, newHealth)
end)

-- 2. Handler para usar el 'guisado'
-- ESX.RegisterUsableItem corre en el servidor para mayor seguridad.
ESX.RegisterUsableItem('guisado', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)

    -- A. Quitar el ítem del inventario
    xPlayer.removeInventoryItem('guisado', 1)

    -- B. Aplicar el efecto (Llama al evento de cliente para restaurar salud)
    TriggerClientEvent('esx_cocinacasera:restaurarSalud', source, 50) -- Recupera 50 puntos de salud
    
    -- C. Mensaje de feedback
    TriggerClientEvent('esx:showNotification', source, '¡Te has comido el Guisado Casero y te sientes recuperado!')
end)

-- 3. Handler para usar la 'ensalada'
ESX.RegisterUsableItem('ensalada', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)

    -- A. Quitar el ítem del inventario
    xPlayer.removeInventoryItem('ensalada', 1)

    -- B. Aplicar el efecto (Menos recuperación)
    TriggerClientEvent('esx_cocinacasera:restaurarSalud', source, 25) -- Recupera 25 puntos de salud
    
    -- C. Mensaje de feedback
    TriggerClientEvent('esx:showNotification', source, '¡Qué refrescante estaba esa Ensalada! Te sientes mejor.')
end)