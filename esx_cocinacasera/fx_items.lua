-- ====================================================================
-- MÓDULO 4: LÓGICA DE CONSUMO (fx_items.lua) - FINAL
-- Solo contiene el evento de cliente para restaurar la salud.
-- ====================================================================

ESX = nil

-- Inicializar ESX
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- 1. Evento del Cliente para Restaurar Salud
RegisterNetEvent('esx_cocinacasera:restaurarSalud')
AddEventHandler('esx_cocinacasera:restaurarSalud', function(cantidad)
    local playerPed = PlayerPedId()
    local health = GetEntityHealth(playerPed)

    -- La salud máxima de un jugador a pie es 200 (100 de barra visible + 100 extra)
    local newHealth = math.min(health + cantidad, 200) 

    SetEntityHealth(playerPed, newHealth)
end)

-- NOTA: ESX.RegisterUsableItem se maneja ahora de forma universal en server.lua