-- ====================================================================
-- SISTEMA DE COCINA CASERA - SERVIDOR PROFESIONAL
-- ====================================================================

ESX = nil
local PlayersCooking = {}
local CookingSessions = {}
local RateLimits = {}

-- ====================================================================
-- 1. INICIALIZACIÓN Y SEGURIDAD
-- ====================================================================

TriggerEvent('esx:getSharedObject', function(obj) 
    ESX = obj 
end)

-- Función de seguridad para verificar jugadores
local function IsPlayerValid(source)
    if not source then return false end
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer ~= nil
end

-- Sistema de rate limiting
local function CheckRateLimit(source, action)
    local key = source .. '_' .. action
    local currentTime = os.time()
    
    if not RateLimits[key] then
        RateLimits[key] = currentTime
        return true
    end
    
    local timeDiff = currentTime - RateLimits[key]
    if timeDiff < Config.Validaciones.cooldownEntreCocinas / 1000 then
        return false
    end
    
    RateLimits[key] = currentTime
    return true
end

-- ====================================================================
-- 2. SISTEMA DE CONSUMO UNIVERSAL MEJORADO
-- ====================================================================

Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Esperar a que ESX cargue completamente
    
    for itemName, receta in pairs(Config.Recetas) do
        if Config.Debug then
            print('^2[COCINA]^7 Registrando item usable: ' .. itemName)
        end
        
        ESX.RegisterUsableItem(itemName, function(source)
            if not IsPlayerValid(source) then return end
            
            local xPlayer = ESX.GetPlayerFromId(source)
            
            -- Verificar que el item existe
            local item = xPlayer.getInventoryItem(itemName)
            if item.count < 1 then
                if Config.Debug then
                    print('^3[COCINA]^7 Jugador ' .. source .. ' intentó usar item que no tiene: ' .. itemName)
                end
                return
            end
            
            -- Remover item del inventario
            xPlayer.removeInventoryItem(itemName, 1)
            
            -- Aplicar efectos de nutrición
            ApplyNutritionEffects(source, receta)
            
            -- Sistema de experiencia por consumo
            if Config.SistemaExperiencia.activado then
                AddCookingExperience(xPlayer, 5, 'consumo') -- XP por consumo
            end
            
            -- Notificación al jugador
            TriggerClientEvent('esx:showNotification', source, 
                string.format(Config.Mensajes.cocina_exitosa, receta.label))
                
            if Config.Debug then
                print('^2[COCINA]^7 Jugador ' .. source .. ' consumió: ' .. itemName)
            end
        end)
    end
    
    print('^2[COCINA]^7 Sistema de consumo cargado - ' .. GetTableLength(Config.Recetas) .. ' recetas registradas')
end)

-- ====================================================================
-- 3. CALLBACK DE VERIFICACIÓN MEJORADO (NO BLOQUEANTE)
-- ====================================================================

ESX.RegisterServerCallback('esx_cocinacasera:verificarIngredientes', function(source, cb, platoFinal)
    if not IsPlayerValid(source) then
        cb(false)
        return
    end
    
    -- Rate limiting
    if not CheckRateLimit(source, 'start_cooking') then
        TriggerClientEvent('esx:showNotification', source, '⏳ Espera un momento antes de cocinar de nuevo')
        cb(false)
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local jobName = xPlayer.job.name
    local jobGrade = xPlayer.job.grade or 0
    
    -- Validar que la receta existe
    if not Config.Recetas[platoFinal] then
        if Config.Debug then
            print('^1[COCINA]^7 Receta no encontrada: ' .. tostring(platoFinal))
        end
        TriggerClientEvent('esx:showNotification', source, '❌ Receta no válida')
        cb(false)
        return
    end
    
    local receta = Config.Recetas[platoFinal]
    
    -- Validar acceso al trabajo
    if not ValidateJobAccess(receta, jobName, jobGrade) then
        cb(false)
        return
    end
    
    -- Validar ingredientes
    local tieneIngredientes, ingredientesFaltantes = ValidateIngredients(xPlayer, receta.ingredientes)
    
    if not tieneIngredientes then
        local missingItems = {}
        for _, ing in pairs(ingredientesFaltantes) do
            table.insert(missingItems, ing.cantidad .. 'x ' .. (Config.Items[ing.item]?.label or ing.item))
        end
        
        TriggerClientEvent('esx:showNotification', source, 
            Config.Mensajes.sin_ingredientes .. ': ' .. table.concat(missingItems, ', '))
        cb(false)
        return
    end
    
    -- Crear sesión de cocina
    local sessionId = source .. '_' .. os.time()
    CookingSessions[sessionId] = {
        playerId = source,
        recipe = platoFinal,
        startTime = os.time(),
        ingredients = receta.ingredientes
    }
    
    PlayersCooking[source] = sessionId
    
    if Config.Debug then
        print('^2[COCINA]^7 Sesión de cocina iniciada: ' .. sessionId .. ' - ' .. platoFinal)
    end
    
    cb(true)
end)

-- ====================================================================
-- 4. PROCESAMIENTO FINAL MEJORADO
-- ====================================================================

RegisterServerEvent('esx_cocinacasera:procesarCocina')
AddEventHandler('esx_cocinacasera:procesarCocina', function(platoFinal)
    local source = source
    if not IsPlayerValid(source) then return end
    
    local sessionId = PlayersCooking[source]
    if not sessionId or not CookingSessions[sessionId] then
        if Config.Debug then
            print('^3[COCINA]^7 Sesión no válida para jugador: ' .. source)
        end
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local session = CookingSessions[sessionId]
    local receta = Config.Recetas[platoFinal]
    
    -- Verificar que la sesión corresponde a la receta
    if session.recipe ~= platoFinal then
        if Config.Debug then
            print('^1[COCINA]^7 Discrepancia en sesión de cocina: ' .. session.recipe .. ' vs ' .. platoFinal)
        end
        CleanupCookingSession(source)
        return
    end
    
    -- Calcular probabilidad de éxito
    local probabilidadExito = CalculateSuccessProbability(source, receta)
    local esExito = math.random(1, 100) <= probabilidadExito
    
    -- Quitar ingredientes (solo si no es desastre total)
    local resultadoFalla = nil
    if esExito then
        RemoveIngredients(xPlayer, receta.ingredientes)
    else
        resultadoFalla = HandleCookingFailure(xPlayer, receta)
        -- Solo quitar ingredientes si no es desastre total
        if resultadoFalla and resultadoFalla.tipo ~= 'desastre' then
            RemoveIngredients(xPlayer, receta.ingredientes)
        end
    end
    
    -- Dar recompensas
    if esExito then
        GiveCookingRewards(xPlayer, receta, session)
    elseif resultadoFalla then
        GiveFailureResult(xPlayer, resultadoFalla)
    end
    
    -- Limpiar sesión
    CleanupCookingSession(source)
    
    if Config.Debug then
        local resultado = esExito and 'ÉXITO' or 'FALLA'
        print('^2[COCINA]^7 Cocina finalizada: ' .. sessionId .. ' - ' .. resultado .. ' (' .. probabilidadExito .. '%)')
    end
end)

-- ====================================================================
-- 5. SISTEMA DE FALLAS Y RECOMPENSAS MEJORADO
-- ====================================================================

function CalculateSuccessProbability(source, receta)
    local xPlayer = ESX.GetPlayerFromId(source)
    local jobGrade = xPlayer.job.grade or 0
    local probabilidadBase = 100 - receta.baseFalla
    
    -- Bonus por nivel del trabajo
    local bonusNivel = jobGrade * 2  -- 2% más por nivel
    
    -- Bonus por experiencia de cocina (si está activado)
    local bonusExperiencia = 0
    if Config.SistemaExperiencia.activado then
        -- Aquí podrías integrar con un sistema de experiencia personalizado
        bonusExperiencia = math.min(20, jobGrade * 1.5) -- Máximo 20% bonus
    end
    
    -- Multiplicador por dificultad
    local multiplicadorDificultad = Config.SistemaCalidad.factoresFalla.porDificultad[receta.dificultad] or 1.0
    
    local probabilidadFinal = (probabilidadBase + bonusNivel + bonusExperiencia) * multiplicadorDificultad
    
    -- Asegurar que esté entre 5% y 95%
    return math.max(5, math.min(95, math.floor(probabilidadFinal)))
end

function HandleCookingFailure(xPlayer, receta)
    local rand = math.random(1, 100)
    local acumulado = 0
    
    for tipoFalla, configFalla in pairs(Config.SistemaCalidad.resultadosFalla) do
        acumulado = acumulado + (configFalla.probabilidad * 100)
        if rand <= acumulado then
            return {
                tipo = tipoFalla,
                item = configFalla.itemResultado,
                mensaje = configFalla.mensaje
            }
        end
    end
    
    -- Fallback
    return {
        tipo = 'quemado',
        item = 'comida_quemada',
        mensaje = Config.Mensajes.comida_quemada
    }
end

function GiveCookingRewards(xPlayer, receta, session)
    -- Dar el item resultante
    xPlayer.addInventoryItem(receta.itemResultado, receta.cantidadResultado)
    
    -- Dar recompensa de dinero
    if receta.recompensaDinero then
        local dinero = math.random(receta.recompensaDinero.min, receta.recompensaDinero.max)
        xPlayer.addMoney(dinero)
        TriggerClientEvent('esx:showNotification', xPlayer.source, 
            string.format(Config.Mensajes.dinero_ganado, dinero))
    end
    
    -- Dar experiencia
    if Config.SistemaExperiencia.activado then
        local expGanada = receta.experiencia or Config.SistemaExperiencia.experienciaBase
        local multiplicador = Config.SistemaExperiencia.multiplicadorDificultad[receta.dificultad] or 1.0
        expGanada = math.floor(expGanada * multiplicador)
        
        AddCookingExperience(xPlayer, expGanada, 'cocina')
        
        TriggerClientEvent('esx:showNotification', xPlayer.source, 
            string.format(Config.Mensajes.experiencia_ganada, expGanada))
    end
    
    -- Notificación de éxito
    TriggerClientEvent('esx:showNotification', xPlayer.source, 
        string.format(Config.Mensajes.cocina_exitosa, receta.label))
end

function GiveFailureResult(xPlayer, resultadoFalla)
    if resultadoFalla.item then
        xPlayer.addInventoryItem(resultadoFalla.item, 1)
    end
    
    TriggerClientEvent('esx:showNotification', xPlayer.source, resultadoFalla.mensaje)
end

-- ====================================================================
-- 6. FUNCIONES UTILITARIAS MEJORADAS
-- ====================================================================

function ValidateJobAccess(receta, jobName, jobGrade)
    -- Si no requiere trabajo, acceso libre
    if not receta.trabajoRequerido then
        return true
    end
    
    -- Verificar trabajo
    if receta.trabajoRequerido ~= jobName then
        return false, string.format(Config.Mensajes.trabajo_incorrecto, receta.trabajoRequerido)
    end
    
    -- Verificar nivel
    if jobGrade < receta.nivelRequerido then
        return false, string.format(Config.Mensajes.nivel_insuficiente, receta.nivelRequerido)
    end
    
    return true
end

function ValidateIngredients(xPlayer, ingredientes)
    local faltantes = {}
    
    for _, ing in pairs(ingredientes) do
        local item = xPlayer.getInventoryItem(ing.item)
        if not item or item.count < ing.cantidad then
            table.insert(faltantes, {
                item = ing.item,
                cantidad = ing.cantidad - (item and item.count or 0)
            })
        end
    end
    
    return #faltantes == 0, faltantes
end

function RemoveIngredients(xPlayer, ingredientes)
    for _, ing in pairs(ingredientes) do
        xPlayer.removeInventoryItem(ing.item, ing.cantidad)
    end
end

function ApplyNutritionEffects(source, receta)
    if receta.efectos then
        local xPlayer = ESX.GetPlayerFromId(source)
        
        -- Salud
        if receta.efectos.salud then
            local salud = math.random(receta.efectos.salud.min, receta.efectos.salud.max)
            TriggerClientEvent('esx_cocinacasera:restaurarSalud', source, salud)
        end
        
        -- Hambre (usando esx_status si está disponible)
        if receta.efectos.hambre and xPlayer.setHunger then
            local hambre = math.random(receta.efectos.hambre.min, receta.efectos.hambre.max)
            xPlayer.setHunger(hambre)
        end
        
        -- Sed (usando esx_status si está disponible)
        if receta.efectos.sed and xPlayer.setThirst then
            local sed = math.random(receta.efectos.sed.min, receta.efectos.sed.max)
            xPlayer.setThirst(sed)
        end
    end
end

function AddCookingExperience(xPlayer, cantidad, tipo)
    -- Aquí integrarías con tu sistema de experiencia personalizado
    -- Por ahora solo es un placeholder
    if Config.Debug then
        print('^2[COCINA]^7 XP ganada: ' .. xPlayer.source .. ' - ' .. cantidad .. ' (' .. tipo .. ')')
    end
end

function CleanupCookingSession(source)
    local sessionId = PlayersCooking[source]
    if sessionId then
        CookingSessions[sessionId] = nil
        PlayersCooking[source] = nil
    end
end

function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- ====================================================================
-- 7. MANEJO DE CANCELACIONES Y CLEANUP
-- ====================================================================

RegisterServerEvent('esx_cocinacasera:cancelarCocina')
AddEventHandler('esx_cocinacasera:cancelarCocina', function()
    local source = source
    CleanupCookingSession(source)
    
    if Config.Debug then
        print('^3[COCINA]^7 Cocina cancelada por jugador: ' .. source)
    end
end)

-- Cleanup global al desconectar
AddEventHandler('playerDropped', function(reason)
    local source = source
    CleanupCookingSession(source)
end)

-- Cleanup al detener el recurso
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CookingSessions = {}
        PlayersCooking = {}
        RateLimits = {}
        
        if Config.Debug then
            print('^2[COCINA]^7 Servidor detenido - Cleanup completado')
        end
    end
end)

-- ====================================================================
-- 8. COMANDOS DE ADMINISTRACIÓN (OPCIONAL)
-- ====================================================================

if Config.Debug then
    RegisterCommand('cocina_stats', function(source, args, rawCommand)
        if source == 0 then
            print('^2[COCINA-STATS]^7 Estadísticas del servidor:')
            print('Sesiones activas: ' .. GetTableLength(CookingSessions))
            print('Jugadores cocinando: ' .. GetTableLength(PlayersCooking))
            print('Recetas registradas: ' .. GetTableLength(Config.Recetas))
        end
    end, true)
end

print('^2[COCINA]^7 Servidor de cocina cargado - Listo para procesar recetas')
