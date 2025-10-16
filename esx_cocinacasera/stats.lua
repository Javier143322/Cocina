-- ====================================================================
-- SISTEMA DE ESTADÍSTICAS DE COCINA
-- ====================================================================

ESX = nil
local PlayerStats = {}

-- ====================================================================
-- 1. INICIALIZACIÓN
-- ====================================================================

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
end)

-- ====================================================================
-- 2. EVENTOS PARA REGISTRAR ESTADÍSTICAS
-- ====================================================================

-- Registrar cocina exitosa
RegisterNetEvent('esx_cocinacasera:registrarCocinaExitosa')
AddEventHandler('esx_cocinacasera:registrarCocinaExitosa', function(plato, dificultad)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    InitializePlayerStats(identifier)

    -- Actualizar estadísticas
    PlayerStats[identifier].total_recetas_cocinadas = PlayerStats[identifier].total_recetas_cocinadas + 1
    PlayerStats[identifier].recetas_exitosas = PlayerStats[identifier].recetas_exitosas + 1
    
    -- Por categoría de plato
    local categoria = Config.Recetas[plato]?.category or 'otro'
    PlayerStats[identifier].por_categoria[categoria] = (PlayerStats[identifier].por_categoria[categoria] or 0) + 1
    
    -- Por dificultad
    PlayerStats[identifier].por_dificultad[dificultad] = (PlayerStats[identifier].por_dificultad[dificultad] or 0) + 1
    
    -- Guardar en base de datos
    SavePlayerStats(identifier)
    
    if Config.Debug then
        print('^2[COCINA-STATS]^7 Estadísticas actualizadas: ' .. identifier)
    end
end)

-- Registrar falla en cocina
RegisterNetEvent('esx_cocinacasera:registrarCocinaFallida')
AddEventHandler('esx_cocinacasera:registrarCocinaFallida', function(plato, tipoFalla)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    InitializePlayerStats(identifier)

    PlayerStats[identifier].total_recetas_cocinadas = PlayerStats[identifier].total_recetas_cocinadas + 1
    PlayerStats[identifier].recetas_fallidas = PlayerStats[identifier].recetas_fallidas + 1
    PlayerStats[identifier].fallas_por_tipo[tipoFalla] = (PlayerStats[identifier].fallas_por_tipo[tipoFalla] or 0) + 1
    
    SavePlayerStats(identifier)
end)

-- Registrar consumo
RegisterNetEvent('esx_cocinacasera:registrarConsumo')
AddEventHandler('esx_cocinacasera:registrarConsumo', function(plato)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    InitializePlayerStats(identifier)

    PlayerStats[identifier].total_consumos = PlayerStats[identifier].total_consumos + 1
    PlayerStats[identifier].platos_consumidos[plato] = (PlayerStats[identifier].platos_consumidos[plato] or 0) + 1
    
    SavePlayerStats(identifier)
end)

-- ====================================================================
-- 3. FUNCIONES PRINCIPALES
-- ====================================================================

function InitializePlayerStats(identifier)
    if not PlayerStats[identifier] then
        PlayerStats[identifier] = {
            total_recetas_cocinadas = 0,
            recetas_exitosas = 0,
            recetas_fallidas = 0,
            total_consumos = 0,
            experiencia_total = 0,
            por_categoria = {},
            por_dificultad = {},
            fallas_por_tipo = {},
            platos_consumidos = {},
            misiones_completadas = 0,
            dinero_ganado = 0,
            fecha_primer_cocina = os.time(),
            fecha_ultima_cocina = os.time()
        }
        
        -- Cargar desde base de datos si existe
        LoadPlayerStats(identifier)
    end
end

function GetPlayerStats(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    
    local identifier = xPlayer.identifier
    InitializePlayerStats(identifier)
    
    -- Calcular porcentajes
    local stats = PlayerStats[identifier]
    stats.porcentaje_exito = stats.total_recetas_cocinadas > 0 and 
        (stats.recetas_exitosas / stats.total_recetas_cocinadas) * 100 or 0
    
    stats.nivel_chef = CalculateChefLevel(stats.experiencia_total)
    stats.ranking = CalculateRanking(identifier)
    
    return stats
end

function CalculateChefLevel(experiencia)
    local niveles = Config.SistemaExperiencia.niveles
    for i = #niveles, 1, -1 do
        if experiencia >= niveles[i].expRequerida then
            return niveles[i].nivel
        end
    end
    return 1
end

function CalculateRanking(identifier)
    -- Lógica simple de ranking basado en experiencia
    local players = GetPlayersWithStats()
    table.sort(players, function(a, b)
        return a.experiencia_total > b.experiencia_total
    end)
    
    for i, player in ipairs(players) do
        if player.identifier == identifier then
            return i
        end
    end
    return #players + 1
end

-- ====================================================================
-- 4. BASE DE DATOS
-- ====================================================================

function LoadPlayerStats(identifier)
    MySQL.Async.fetchScalar('SELECT stats FROM cocina_stats WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result then
            PlayerStats[identifier] = json.decode(result)
        end
    end)
end

function SavePlayerStats(identifier)
    MySQL.Async.execute('INSERT INTO cocina_stats (identifier, stats) VALUES (@identifier, @stats) ON DUPLICATE KEY UPDATE stats = @stats', {
        ['@identifier'] = identifier,
        ['@stats'] = json.encode(PlayerStats[identifier])
    })
end

-- ====================================================================
-- 5. COMANDOS Y EXPORTACIONES
-- ====================================================================

-- Export para cliente
exports('GetCookingStats', function(source)
    return GetPlayerStats(source)
end)

-- Comando para ver estadísticas
RegisterCommand('cocinastats', function(source, args, rawCommand)
    local stats = GetPlayerStats(source)
    if stats then
        TriggerClientEvent('esx:showNotification', source, '📊 Tus estadísticas de cocina:')
        TriggerClientEvent('esx:showNotification', source, '🍳 Recetas: ' .. stats.total_recetas_cocinadas .. ' (' .. math.floor(stats.porcentaje_exito) .. '% éxito)')
        TriggerClientEvent('esx:showNotification', source, '👨‍🍳 Nivel: ' .. stats.nivel_chef .. ' - Ranking: #' .. stats.ranking)
        TriggerClientEvent('esx:showNotification', source, '💰 Dinero ganado: $' .. stats.dinero_ganado)
    end
end, false)

-- ====================================================================
-- 6. CREACIÓN DE TABLA EN BASE DE DATOS
-- ====================================================================

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `cocina_stats` (
            `identifier` varchar(60) NOT NULL,
            `stats` longtext NOT NULL,
            `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(rowsChanged)
        if Config.Debug then
            print('^2[COCINA-STATS]^7 Tabla de estadísticas inicializada')
        end
    end)
end)

print('^2[COCINA-STATS]^7 Sistema de estadísticas cargado')