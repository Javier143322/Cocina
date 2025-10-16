
-- ====================================================================
-- SISTEMA DE MISIONES DE COCINA
-- ====================================================================

ESX = nil
local ActiveMissions = {}
local DailyMissions = {}
local MissionRewards = {}

-- ====================================================================
-- 1. INICIALIZACIÓN
-- ====================================================================

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
    
    -- Generar misiones diarias al iniciar
    GenerateDailyMissions()
    
    if Config.Debug then
        print('^2[COCINA-MISSIONS]^7 Sistema de misiones inicializado')
    end
end)

-- ====================================================================
-- 2. CONFIGURACIÓN DE MISIONES
-- ====================================================================

Config.Misiones = {
    diarias = {
        { tipo = "cocinar", objetivo = 5, receta = "ensalada_fresca", recompensa = { dinero = 500, exp = 100 } },
        { tipo = "cocinar", objetivo = 3, receta = "guisado_casero", recompensa = { dinero = 800, exp = 150 } },
        { tipo = "consumir", objetivo = 10, recompensa = { dinero = 300, exp = 80 } },
        { tipo = "sin_fallas", objetivo = 8, recompensa = { dinero = 1000, exp = 200 } },
        { tipo = "categoria", objetivo = 4, categoria = "postre", recompensa = { dinero = 600, exp = 120 } }
    },
    semanales = {
        { tipo = "cocinar", objetivo = 25, recompensa = { dinero = 5000, exp = 1000 } },
        { tipo = "experto", objetivo = 10, dificultad = "alta", recompensa = { dinero = 3000, exp = 800 } },
        { tipo = "variedad", objetivo = 8, recetas_diferentes = true, recompensa = { dinero = 4000, exp = 900 } }
    },
    especiales = {
        { id = "chef_master", nombre = "Maestro Chef", objetivo = 50, recompensa = { dinero = 10000, exp = 2000, item = "trofeo_chef" } }
    }
}

-- ====================================================================
-- 3. GENERACIÓN DE MISIONES DIARIAS
-- ====================================================================

function GenerateDailyMissions()
    DailyMissions = {}
    local fechaHoy = os.date("%Y-%m-%d")
    
    -- Seleccionar 3 misiones diarias aleatorias
    for i = 1, 3 do
        local mision = Config.Misiones.diarias[math.random(1, #Config.Misiones.diarias)]
        mision.id = "diaria_" .. i .. "_" .. fechaHoy
        mision.progreso = 0
        mision.completada = false
        table.insert(DailyMissions, mision)
    end
    
    if Config.Debug then
        print('^2[COCINA-MISSIONS]^7 Misiones diarias generadas: ' .. #DailyMissions)
    end
end

-- ====================================================================
-- 4. EVENTOS PARA PROGRESO DE MISIONES
-- ====================================================================

-- Cuando se cocina exitosamente
RegisterNetEvent('esx_cocinacasera:registrarCocinaExitosa')
AddEventHandler('esx_cocinacasera:registrarCocinaExitosa', function(plato, dificultad)
    local source = source
    UpdateMissionProgress(source, "cocinar", 1, plato, dificultad)
    UpdateMissionProgress(source, "sin_fallas", 1)
    
    local categoria = Config.Recetas[plato]?.category
    if categoria then
        UpdateMissionProgress(source, "categoria", 1, nil, nil, categoria)
    end
end)

-- Cuando se consume comida
RegisterNetEvent('esx_cocinacasera:registrarConsumo')
AddEventHandler('esx_cocinacasera:registrarConsumo', function(plato)
    local source = source
    UpdateMissionProgress(source, "consumir", 1)
end)

-- Cuando falla una cocina
RegisterNetEvent('esx_cocinacasera:registrarCocinaFallida')
AddEventHandler('esx_cocinacasera:registrarCocinaFallida', function(plato, tipoFalla)
    local source = source
    -- Resetear misión de sin fallas si falla
    ResetMissionProgress(source, "sin_fallas")
end)

-- ====================================================================
-- 5. SISTEMA DE PROGRESO
-- ====================================================================

function UpdateMissionProgress(source, tipo, cantidad, receta, dificultad, categoria)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    
    -- Inicializar misiones del jugador
    if not ActiveMissions[identifier] then
        ActiveMissions[identifier] = {}
        LoadPlayerMissions(identifier)
    end
    
    -- Actualizar misiones diarias
    for i, mision in ipairs(DailyMissions) do
        if not mision.completada and mision.tipo == tipo then
            -- Verificar condiciones específicas
            if mision.receta and mision.receta ~= receta then
                goto continue
            end
            if mision.categoria and mision.categoria ~= categoria then
                goto continue
            end
            if mision.dificultad and mision.dificultad ~= dificultad then
                goto continue
            end
            
            -- Actualizar progreso
            mision.progreso = mision.progreso + cantidad
            
            -- Verificar si se completó
            if mision.progreso >= mision.objetivo then
                CompleteMission(source, mision, "diaria")
            end
            
            ::continue::
        end
    end
    
    -- Guardar progreso
    SavePlayerMissions(identifier)
    
    -- Notificar progreso si es significativo
    if cantidad > 0 then
        NotifyMissionProgress(source, tipo, cantidad)
    end
end

function ResetMissionProgress(source, tipo)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    
    for i, mision in ipairs(DailyMissions) do
        if mision.tipo == tipo then
            mision.progreso = 0
        end
    end
    
    SavePlayerMissions(identifier)
end

-- ====================================================================
-- 6. COMPLETACIÓN Y RECOMPENSAS
-- ====================================================================

function CompleteMission(source, mision, tipo)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    -- Marcar como completada
    mision.completada = true
    
    -- Dar recompensas
    if mision.recompensa.dinero then
        xPlayer.addMoney(mision.recompensa.dinero)
    end
    
    if mision.recompensa.exp then
        TriggerEvent('esx_cocinacasera:agregarExperiencia', source, mision.recompensa.exp)
    end
    
    if mision.recompensa.item then
        xPlayer.addInventoryItem(mision.recompensa.item, 1)
    end
    
    -- Notificación
    TriggerClientEvent('esx:showNotification', source, '🎉 ¡Misión completada!')
    TriggerClientEvent('esx:showNotification', source, '💰 Recompensa: $' .. (mision.recompensa.dinero or 0))
    TriggerClientEvent('esx:showNotification', source, '⭐ Experiencia: +' .. (mision.recompensa.exp or 0))
    
    -- Log
    if Config.Debug then
        print('^2[COCINA-MISSIONS]^7 Misión completada: ' .. source .. ' - ' .. mision.id)
    end
end

function NotifyMissionProgress(source, tipo, cantidad)
    local progressMessages = {
        cocinar = "🍳 Receta cocinada",
        consumir = "❤️  Plato consumido", 
        sin_fallas = "✅ Cocina perfecta",
        categoria = "📁 Categoría completada"
    }
    
    local message = progressMessages[tipo] or "Progreso en misión"
    TriggerClientEvent('esx:showNotification', source, message .. ' (' .. cantidad .. ')')
end

-- ====================================================================
-- 7. BASE DE DATOS
-- ====================================================================

function LoadPlayerMissions(identifier)
    MySQL.Async.fetchScalar('SELECT misiones FROM cocina_misiones WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result then
            local data = json.decode(result)
            if data.daily then
                for i, savedMission in ipairs(data.daily) do
                    for j, dailyMission in ipairs(DailyMissions) do
                        if savedMission.id == dailyMission.id then
                            DailyMissions[j].progreso = savedMission.progreso
                            DailyMissions[j].completada = savedMission.completada
                        end
                    end
                end
            end
        end
    end)
end

function SavePlayerMissions(identifier)
    local data = {
        daily = DailyMissions,
        last_updated = os.time()
    }
    
    MySQL.Async.execute('INSERT INTO cocina_misiones (identifier, misiones) VALUES (@identifier, @misiones) ON DUPLICATE KEY UPDATE misiones = @misiones', {
        ['@identifier'] = identifier,
        ['@misiones'] = json.encode(data)
    })
end

-- ====================================================================
-- 8. COMANDOS Y EXPORTACIONES
-- ====================================================================

-- Export para obtener misiones activas
exports('GetActiveMissions', function(source)
    return DailyMissions
end)

-- Comando para ver misiones
RegisterCommand('cocinamisiones', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    TriggerClientEvent('esx:showNotification', source, '📋 Tus misiones de cocina:')
    
    for i, mision in ipairs(DailyMissions) do
        local estado = mision.completada and '✅' or '🔄'
        local progreso = mision.progreso .. '/' .. mision.objetivo
        TriggerClientEvent('esx:showNotification', source, estado .. ' ' .. GetMissionDescription(mision) .. ' (' .. progreso .. ')')
    end
end, false)

function GetMissionDescription(mision)
    local descriptions = {
        cocinar = "Cocinar " .. (mision.receta and Config.Recetas[mision.receta].label or "recetas"),
        consumir = "Consumir platos",
        sin_fallas = "Cocinar sin fallas",
        categoria = "Cocinar " .. (mision.categoria or "recetas")
    }
    return descriptions[mision.tipo] or "Misión de cocina"
end

-- ====================================================================
-- 9. CREACIÓN DE TABLA EN BASE DE DATOS
-- ====================================================================

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `cocina_misiones` (
            `identifier` varchar(60) NOT NULL,
            `misiones` longtext NOT NULL,
            `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(rowsChanged)
        if Config.Debug then
            print('^2[COCINA-MISSIONS]^7 Tabla de misiones inicializada')
        end
    end)
end)

-- ====================================================================
-- 10. RESET DIARIO AUTOMÁTICO
-- ====================================================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(24 * 60 * 60 * 1000) -- 24 horas
        GenerateDailyMissions()
        ActiveMissions = {}
        
        if Config.Debug then
            print('^2[COCINA-MISSIONS]^7 Misiones diarias reseteadas')
        end
    end
end)

print('^2[COCINA-MISSIONS]^7 Sistema de misiones cargado')