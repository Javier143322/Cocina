
-- ====================================================================
-- SISTEMA DE CONSUMO - CLIENTE MEJORADO
-- ====================================================================

ESX = nil
local LastHealthRestore = 0
local HealthRestoreCooldown = 1000 -- 1 segundo entre curaciones

-- ====================================================================
-- 1. INICIALIZACIÓN
-- ====================================================================

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) 
            ESX = obj 
        end)
        Citizen.Wait(100)
    end
    
    if Config.Debug then
        print('^2[COCINA-CONSUMO]^7 Cliente de consumo inicializado')
    end
end)

-- ====================================================================
-- 2. EVENTO DE RESTAURACIÓN DE SALUD MEJORADO
-- ====================================================================

RegisterNetEvent('esx_cocinacasera:restaurarSalud')
AddEventHandler('esx_cocinacasera:restaurarSalud', function(cantidad)
    local currentTime = GetGameTimer()
    
    -- Rate limiting para prevenir spam
    if currentTime - LastHealthRestore < HealthRestoreCooldown then
        if Config.Debug then
            print('^3[COCINA-CONSUMO]^7 Rate limit alcanzado, ignorando curación')
        end
        return
    end
    
    LastHealthRestore = currentTime
    
    -- Validar parámetros
    if not cantidad or type(cantidad) ~= 'number' then
        if Config.Debug then
            print('^1[COCINA-CONSUMO]^7 Cantidad de salud inválida: ' .. tostring(cantidad))
        end
        return
    end
    
    cantidad = math.floor(cantidad)
    
    if cantidad <= 0 then
        if Config.Debug then
            print('^3[COCINA-CONSUMO]^7 Cantidad de salud no positiva: ' .. cantidad)
        end
        return
    end
    
    local playerPed = PlayerPedId()
    
    -- Verificar que el jugador existe y está vivo
    if not DoesEntityExist(playerPed) or IsEntityDead(playerPed) then
        if Config.Debug then
            print('^3[COCINA-CONSUMO]^7 Jugador no existe o está muerto')
        end
        return
    end
    
    -- Obtener salud actual
    local healthActual = GetEntityHealth(playerPed)
    
    -- Si el jugador está muerto, no curar
    if healthActual <= 0 then
        if Config.Debug then
            print('^3[COCINA-CONSUMO]^7 Jugador está muerto, no se puede curar')
        end
        return
    end
    
    -- Calcular nueva salud (máximo 200 en GTA V)
    local nuevaSalud = math.min(healthActual + cantidad, GetEntityMaxHealth(playerPed))
    
    -- Aplicar curación con efectos
    ApplyHealthRestoration(playerPed, healthActual, nuevaSalud, cantidad)
    
    if Config.Debug then
        print('^2[COCINA-CONSUMO]^7 Salud restaurada: ' .. healthActual .. ' -> ' .. nuevaSalud .. ' (+' .. cantidad .. ')')
    end
end)

-- ====================================================================
-- 3. SISTEMA DE EFECTOS VISUALES Y DE SONIDO
-- ====================================================================

function ApplyHealthRestoration(playerPed, healthActual, nuevaSalud, cantidad)
    -- Efecto de sonido si está habilitado
    if Config.Sonidos.activado then
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
    
    -- Efectos visuales progresivos
    local curacionPequena = cantidad < 30
    local curacionMedia = cantidad >= 30 and cantidad < 60
    local curacionGrande = cantidad >= 60
    
    if curacionGrande then
        -- Efecto visual para curaciones grandes
        StartScreenEffect("HealthGain", 1000, false)
        TriggerScreenblurFadeIn(500)
        Citizen.Wait(500)
        TriggerScreenblurFadeOut(500)
        
    elseif curacionMedia then
        -- Efecto visual para curaciones medianas
        StartScreenEffect("MinigameEndNeutral", 500, false)
    end
    
    -- Aplicar la curación de forma progresiva para mejor feedback
    ApplyProgressiveHealing(playerPed, healthActual, nuevaSalud)
    
    -- Mostrar flotante de curación
    ShowFloatingHealingText(cantidad)
    
    -- Notificación de curación (opcional)
    if Config.EnableNotifications then
        ESX.ShowNotification('❤️ Restaurado: +' .. cantidad .. ' de salud')
    end
end

function ApplyProgressiveHealing(playerPed, healthActual, nuevaSalud)
    -- Curar de forma inmediata para gameplay fluido
    SetEntityHealth(playerPed, nuevaSalud)
    
    -- Efecto visual progresivo opcional (para curaciones grandes)
    if nuevaSalud - healthActual > 50 then
        Citizen.CreateThread(function()
            local incremento = 5
            local saludTemporal = healthActual
            
            while saludTemporal < nuevaSalud do
                saludTemporal = math.min(saludTemporal + incremento, nuevaSalud)
                SetEntityHealth(playerPed, saludTemporal)
                Citizen.Wait(50)
            end
        end)
    end
end

function ShowFloatingHealingText(cantidad)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Texto flotante sobre el jugador
    Citizen.CreateThread(function()
        local text = "+" .. cantidad
        local color = {r = 0, g = 255, b = 0, a = 255} -- Verde
        
        -- Determinar color basado en la cantidad
        if cantidad < 30 then
            color = {r = 144, g = 238, b = 144, a = 255} -- Verde claro
        elseif cantidad < 60 then
            color = {r = 50, g = 205, b = 50, a = 255}   -- Verde lima
        else
            color = {r = 0, g = 255, b = 0, a = 255}     -- Verde brillante
        end
        
        local heightOffset = 0.0
        local duration = 2000 -- 2 segundos
        
        for i = 1, duration / 50 do
            heightOffset = heightOffset + 0.01
            local textCoords = vector3(playerCoords.x, playerCoords.y, playerCoords.z + 1.0 + heightOffset)
            
            -- Verificar si las coordenadas son visibles en la cámara
            if #(GetGameplayCamCoords() - textCoords) < 100.0 then
                DrawText3D(textCoords, text, color, 0.35)
            end
            
            Citizen.Wait(50)
        end
    end)
end

-- ====================================================================
-- 4. FUNCIÓN DE TEXTO 3D MEJORADA
-- ====================================================================

function DrawText3D(coords, text, color, scale)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoords()
    local distance = #(coords - camCoords)
    
    scale = scale or 0.35
    
    if distance < 10.0 then
        scale = scale * (1.0 / distance)
    else
        scale = scale * (10.0 / distance)
    end
    
    scale = math.min(scale, 1.0)
    
    if onScreen then
        SetTextScale(0.0, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

-- ====================================================================
-- 5. SISTEMA DE DEBUG Y ADMINISTRACIÓN
-- ====================================================================

if Config.Debug then
    -- Comando para probar el sistema de curación
    RegisterCommand('test_curacion', function(source, args)
        local cantidad = tonumber(args[1]) or 50
        TriggerEvent('esx_cocinacasera:restaurarSalud', cantidad)
        print('^2[COCINA-CONSUMO]^7 Probando curación: +' .. cantidad .. ' HP')
    end, false)
    
    -- Comando para ver estado de salud actual
    RegisterCommand('estado_salud', function(source, args)
        local playerPed = PlayerPedId()
        local health = GetEntityHealth(playerPed)
        local maxHealth = GetEntityMaxHealth(playerPed)
        
        print('^2[COCINA-CONSUMO]^7 Estado de salud:')
        print('Salud actual: ' .. health)
        print('Salud máxima: ' .. maxHealth)
        print('Porcentaje: ' .. math.floor((health / maxHealth) * 100) .. '%')
    end, false)
end

-- ====================================================================
-- 6. COMPATIBILIDAD CON SISTEMAS DE STATUS
-- ====================================================================

-- Evento para integración con esx_status u otros sistemas
RegisterNetEvent('esx_cocinacasera:aplicarEfectosCompletos')
AddEventHandler('esx_cocinacasera:aplicarEfectosCompletos', function(efectos)
    if not efectos then return end
    
    -- Salud
    if efectos.salud then
        local cantidadSalud = math.random(efectos.salud.min, efectos.salud.max)
        TriggerEvent('esx_cocinacasera:restaurarSalud', cantidadSalud)
    end
    
    -- Efectos de stamina (si el framework lo soporta)
    if efectos.stamina then
        local cantidadStamina = math.random(efectos.stamina.min, efectos.stamina.max)
        RestorePlayerStamina(cantidadStamina)
    end
    
    -- Efectos de armadura (opcional)
    if efectos.armadura then
        local cantidadArmadura = math.random(efectos.armadura.min, efectos.armadura.max)
        AddArmorToPlayer(cantidadArmadura)
    end
end)

-- Función para restaurar stamina (placeholder para integración)
function RestorePlayerStamina(cantidad)
    -- Integrar con tu sistema de stamina preferido
    -- Ejemplo para esx_status:
    -- TriggerEvent('esx_status:add', 'stamina', cantidad * 10000)
    
    if Config.Debug then
        print('^2[COCINA-CONSUMO]^7 Stamina restaurada: +' .. cantidad)
    end
end

-- Función para agregar armadura (placeholder para integración)
function AddArmorToPlayer(cantidad)
    local playerPed = PlayerPedId()
    local armaduraActual = GetPedArmour(playerPed)
    local nuevaArmadura = math.min(armaduraActual + cantidad, 100)
    
    SetPedArmour(playerPed, nuevaArmadura)
    
    if Config.Debug then
        print('^2[COCINA-CONSUMO]^7 Armadura restaurada: ' .. armaduraActual .. ' -> ' .. nuevaArmadura)
    end
end

-- ====================================================================
-- 7. CLEANUP Y SEGURIDAD
-- ====================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Detener todos los efectos de pantalla activos
        StopAllScreenEffects()
        
        if Config.Debug then
            print('^2[COCINA-CONSUMO]^7 Cliente de consumo detenido')
        end
    end
end)

print('^2[COCINA-CONSUMO]^7 Sistema de consumo cliente cargado - Listo para restaurar salud')