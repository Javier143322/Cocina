-- ====================================================================
-- SISTEMA DE EXPERIENCIA DE COCINA AVANZADO
-- ====================================================================

ESX = nil
local PlayerExperience = {}
local CookingLevels = {}

-- ====================================================================
-- 1. INICIALIZACIÓN
-- ====================================================================

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
    
    if Config.Debug then
        print('^2[COCINA-EXP]^7 Sistema de experiencia inicializado')
    end
end)

-- ====================================================================
-- 2. CONFIGURACIÓN DE EXPERIENCIA AVANZADA
-- ====================================================================

Config.ExperienciaAvanzada = {
    activado = true,
    experiencia_base = 10,
    multiplicador_dificultad = {
        baja = 1.0,
        media = 1.5,
        alta = 2.0,
        experto = 3.0
    },
    bonus_por_nivel = 0.05, -- 5% más XP por nivel
    max_nivel = 100,
    
    niveles = {
        { nivel = 1, exp_requerida = 0, titulo = "🍳 Aprendiz", bonus = 0 },
        { nivel = 2, exp_requerida = 100, titulo = "👨‍🍳 Cocinitas", bonus = 5 },
        { nivel = 5, exp_requerida = 500, titulo = "🔪 Chef Junior", bonus = 10 },
        { nivel = 10, exp_requerida = 1500, titulo = "🥘 Chef", bonus = 15 },
        { nivel = 20, exp_requerida = 4000, titulo = "👨‍🍳 Chef Senior", bonus = 20 },
        { nivel = 30, exp_requerida = 8000, titulo = "🎖️ Maestro Chef", bonus = 25 },
        { nivel = 50, exp_requerida = 20000, titulo = "🌟 Chef Leyenda", bonus = 30 },
        { nivel = 100, exp_requerida = 100000, titulo = "👑 Dios de la Cocina", bonus = 50 }
    },
    
    habilidades_desbloqueables = {
        { nivel = 5, habilidad = "cortes_rapidos", nombre = "Cortes Rápidos", desc = "Tiempo de cocina -10%" },
        { nivel = 10, habilidad = "manos_limpias", nombre = "Manos Limpias", desc = "Probabilidad de falla -15%" },
        { nivel = 15, habilidad = "sazonador", nombre = "Sazonador", desc = "XP ganada +20%" },
        { nivel = 20, habilidad = "eficiencia", nombre = "Eficiencia", desc = "Ingredientes -1 en recetas" },
        { nivel = 25, habilidad = "maestro_fogones", nombre = "Maestro Fogones", desc = "Puedes cocinar 2 recetas simultáneas" },
        { nivel = 30, habilidad = "paladar_experto", nombre = "Paladar Experto", desc = "Efectos de comida +25%" }
    }
}

-- ====================================================================
-- 3. EVENTOS PRINCIPALES DE EXPERIENCIA
-- ====================================================================

-- Evento para agregar experiencia (llamado desde server.lua)
RegisterNetEvent('esx_cocinacasera:agregarExperiencia')
AddEventHandler('esx_cocinacasera:agregarExperiencia', function(cantidad, razon)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    AddExperienceToPlayer(xPlayer, cantidad, razon)
end)

-- Evento cuando se completa una cocina exitosa
RegisterNetEvent('esx_cocinacasera:registrarCocinaExitosa')
AddEventHandler('esx_cocinacasera:registrarCocinaExitosa', function(plato, dificultad)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local receta = Config.Recetas[plato]
    if not receta then return end

    -- Calcular experiencia basada en dificultad
    local expBase = receta.experiencia or Config.ExperienciaAvanzada.experiencia_base
    local multiplicador = Config.ExperienciaAvanzada.multiplicador_dificultad[receta.dificultad] or 1.0
    
    -- Bonus por nivel del jugador
    local nivelJugador = GetPlayerLevel(xPlayer.identifier)
    local bonusNivel = 1 + (nivelJugador * Config.ExperienciaAvanzada.bonus_por_nivel)
    
    local expFinal = math.floor(expBase * multiplicador * bonusNivel)
    
    AddExperienceToPlayer(xPlayer, expFinal, 'cocina_exitosa')
    
    if Config.Debug then
        print('^2[COCINA-EXP]^7 XP ganada: ' .. xPlayer.source .. ' - ' .. expFinal .. ' (' .. plato .. ')')
    end
end)

-- ====================================================================
-- 4. SISTEMA DE NIVELES Y PROGRESO
-- ====================================================================

function AddExperienceToPlayer(xPlayer, cantidad, razon)
    local identifier = xPlayer.identifier
    InitializePlayerExperience(identifier)
    
    local datosExp = PlayerExperience[identifier]
    local nivelAnterior = datosExp.nivel_actual
    
    -- Agregar experiencia
    datosExp.experiencia_total = datosExp.experiencia_total + cantidad
    datosExp.experiencia_actual = datosExp.experiencia_actual + cantidad
    
    -- Verificar subida de nivel
    local nuevoNivel = CalculatePlayerLevel(datosExp.experiencia_total)
    
    if nuevoNivel > nivelAnterior then
        HandleLevelUp(xPlayer, nivelAnterior, nuevoNivel)
        datosExp.nivel_actual = nuevoNivel
        datosExp.experiencia_actual = datosExp.experiencia_total - GetExpRequiredForLevel(nuevoNivel)
    end
    
    -- Actualizar estadísticas
    TriggerEvent('esx_cocinacasera:actualizarEstadisticasXP', xPlayer.source, cantidad)
    
    -- Guardar en base de datos
    SavePlayerExperience(identifier)
    
    -- Notificar al cliente
    TriggerClientEvent('esx_cocinacasera:actualizarUIExperiencia', xPlayer.source, {
        nivel = datosExp.nivel_actual,
        experiencia_actual = datosExp.experiencia_actual,
        experiencia_siguiente_nivel = GetExpRequiredForLevel(datosExp.nivel_actual + 1) - GetExpRequiredForLevel(datosExp.nivel_actual),
        experiencia_total = datosExp.experiencia_total
    })
    
    -- Notificación de experiencia ganada
    if razon ~= 'silent' then
        TriggerClientEvent('esx:showNotification', xPlayer.source, 
            '⭐ +' .. cantidad .. ' XP de Cocina (' .. (razon or 'actividad') .. ')')
    end
end

function HandleLevelUp(xPlayer, nivelAnterior, nuevoNivel)
    -- Obtener información del nivel
    local infoNivel = GetLevelInfo(nuevoNivel)
    
    -- Notificación espectacular
    TriggerClientEvent('esx:showNotification', xPlayer.source, 
        '🎉 ¡NIVEL ' .. nuevoNivel .. ' ALCANZADO! 🎉')
    TriggerClientEvent('esx:showNotification', xPlayer.source, 
        '👨‍🍳 Ahora eres: ' .. (infoNivel.titulo or 'Chef'))
    
    -- Recompensas por nivel
    if infoNivel.bonus and infoNivel.bonus > 0 then
        local recompensa = infoNivel.bonus * 100
        xPlayer.addMoney(recompensa)
        TriggerClientEvent('esx:showNotification', xPlayer.source, 
            '💰 Bonus por nivel: $' .. recompensa)
    end
    
    -- Verificar habilidades desbloqueadas
    CheckUnlockedSkills(xPlayer, nuevoNivel)
    
    -- Log
    if Config.Debug then
        print('^2[COCINA-EXP]^7 Subida de nivel: ' .. xPlayer.source .. ' - ' .. nivelAnterior .. ' -> ' .. nuevoNivel)
    end
end

function CheckUnlockedSkills(xPlayer, nuevoNivel)
    for _, habilidad in ipairs(Config.ExperienciaAvanzada.habilidades_desbloqueables) do
        if nuevoNivel == habilidad.nivel then
            UnlockSkill(xPlayer, habilidad)
        end
    end
end

function UnlockSkill(xPlayer, habilidad)
    local identifier = xPlayer.identifier
    
    if not PlayerExperience[identifier].habilidades then
        PlayerExperience[identifier].habilidades = {}
    end
    
    PlayerExperience[identifier].habilidades[habilidad.habilidad] = true
    
    -- Notificar al jugador
    TriggerClientEvent('esx:showNotification', xPlayer.source, 
        '🔓 HABILIDAD DESBLOQUEADA: ' .. habilidad.nombre)
    TriggerClientEvent('esx:showNotification', xPlayer.source, 
        '📖 ' .. habilidad.desc)
    
    -- Aplicar efectos de la habilidad
    ApplySkillEffect(xPlayer, habilidad.habilidad)
    
    if Config.Debug then
        print('^2[COCINA-EXP]^7 Habilidad desbloqueada: ' .. xPlayer.source .. ' - ' .. habilidad.nombre)
    end
end

-- ====================================================================
-- 5. FUNCIONES DE CÁLCULO Y UTILIDAD
-- ====================================================================

function InitializePlayerExperience(identifier)
    if not PlayerExperience[identifier] then
        PlayerExperience[identifier] = {
            nivel_actual = 1,
            experiencia_total = 0,
            experiencia_actual = 0,
            habilidades = {},
            fecha_creacion = os.time(),
            ultima_actualizacion = os.time()
        }
        
        -- Cargar desde base de datos
        LoadPlayerExperience(identifier)
    end
end

function CalculatePlayerLevel(experienciaTotal)
    local niveles = Config.ExperienciaAvanzada.niveles
    local nivel = 1
    
    for i = #niveles, 1, -1 do
        if experienciaTotal >= niveles[i].exp_requerida then
            return niveles[i].nivel
        end
    end
    
    return nivel
end

function GetExpRequiredForLevel(nivel)
    for _, nivelInfo in ipairs(Config.ExperienciaAvanzada.niveles) do
        if nivelInfo.nivel == nivel then
            return nivelInfo.exp_requerida
        end
    end
    return nivel * 100 -- Fórmula por defecto
end

function GetLevelInfo(nivel)
    for _, nivelInfo in ipairs(Config.ExperienciaAvanzada.niveles) do
        if nivelInfo.nivel == nivel then
            return nivelInfo
        end
    end
    return { nivel = nivel, titulo = "Chef", bonus = 0 }
end

function GetPlayerLevel(identifier)
    InitializePlayerExperience(identifier)
    return PlayerExperience[identifier].nivel_actual
end

function ApplySkillEffect(xPlayer, habilidad)
    -- Aquí aplicarías los efectos de las habilidades en el gameplay
    -- Por ejemplo, reducir tiempos de cocina, mejorar probabilidades, etc.
    
    if Config.Debug then
        print('^2[COCINA-EXP]^7 Aplicando efecto de habilidad: ' .. xPlayer.source .. ' - ' .. habilidad)
    end
end

-- ====================================================================
-- 6. BASE DE DATOS
-- ====================================================================

function LoadPlayerExperience(identifier)
    MySQL.Async.fetchScalar('SELECT experiencia FROM cocina_experiencia WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result then
            PlayerExperience[identifier] = json.decode(result)
        end
    end)
end

function SavePlayerExperience(identifier)
    MySQL.Async.execute('INSERT INTO cocina_experiencia (identifier, experiencia) VALUES (@identifier, @experiencia) ON DUPLICATE KEY UPDATE experiencia = @experiencia', {
        ['@identifier'] = identifier,
        ['@experiencia'] = json.encode(PlayerExperience[identifier])
    })
end

-- ====================================================================
-- 7. COMANDOS Y EXPORTACIONES
-- ====================================================================

-- Export para obtener experiencia del jugador
exports('GetPlayerExperience', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    
    local identifier = xPlayer.identifier
    InitializePlayerExperience(identifier)
    
    return {
        nivel = PlayerExperience[identifier].nivel_actual,
        experiencia_actual = PlayerExperience[identifier].experiencia_actual,
        experiencia_total = PlayerExperience[identifier].experiencia_total,
        exp_siguiente_nivel = GetExpRequiredForLevel(PlayerExperience[identifier].nivel_actual + 1) - GetExpRequiredForLevel(PlayerExperience[identifier].nivel_actual),
        habilidades = PlayerExperience[identifier].habilidades or {}
    }
end)

-- Comando para ver experiencia
RegisterCommand('cocinaexp', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local expData = exports['esx_cocina_casera']:GetPlayerExperience(source)
    if expData then
        TriggerClientEvent('esx:showNotification', source, '👨‍🍳 Nivel de Chef: ' .. expData.nivel)
        TriggerClientEvent('esx:showNotification', source, '⭐ XP: ' .. expData.experiencia_actual .. '/' .. expData.exp_siguiente_nivel)
        TriggerClientEvent('esx:showNotification', source, '📊 XP Total: ' .. expData.experiencia_total)
        TriggerClientEvent('esx:showNotification', source, '🔓 Habilidades: ' .. GetTableLength(expData.habilidades))
    end
end, false)

-- ====================================================================
-- 8. CREACIÓN DE TABLA EN BASE DE DATOS
-- ====================================================================

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `cocina_experiencia` (
            `identifier` varchar(60) NOT NULL,
            `experiencia` longtext NOT NULL,
            `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(rowsChanged)
        if Config.Debug then
            print('^2[COCINA-EXP]^7 Tabla de experiencia inicializada')
        end
    end)
end)

-- Función auxiliar
function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

print('^2[COCINA-EXP]^7 Sistema de experiencia avanzada cargado')
