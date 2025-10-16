
-- ====================================================================
-- SISTEMA DE COCINA CASERA - CLIENTE MEJORADO
-- ====================================================================

-- Variables locales protegidas
local ESX = nil
local PlayerData = {}
local Cocinando = false
local CocinaActual = nil 
local MenuAbierto = false
local CurrentAnimation = nil
local LoadedAnimDicts = {}

-- ====================================================================
-- 1. INICIALIZACIÓN MEJORADA
-- ====================================================================

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) 
            ESX = obj 
        end)
        Citizen.Wait(100)
    end
    
    -- Esperar datos del jugador de forma más robusta
    local attempts = 0
    while (PlayerData.job == nil or PlayerData.job.name == nil) and attempts < 50 do
        PlayerData = ESX.GetPlayerData()
        attempts = attempts + 1
        Citizen.Wait(100)
    end
    
    if attempts >= 50 then
        print('^1[COCINA]^7 Error: No se pudieron cargar los datos del jugador')
        return
    end

    -- Eventos mejorados
    RegisterNetEvent('esx:setPlayerData', function(newData)
        PlayerData = newData
    end)

    RegisterNetEvent('esx:setJob', function(job)
        PlayerData.job = job
    end)

    -- Iniciar sistema
    AddCocinaBlips()
    
    if Config.Debug then
        print('^2[COCINA]^7 Sistema de cocina inicializado correctamente')
    end
end)

-- ====================================================================
-- 2. BUCLE PRINCIPAL OPTIMIZADO
-- ====================================================================

Citizen.CreateThread(function()
    local waitTime = 500
    local lastCoords = vector3(0, 0, 0)
    
    while true do
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local cercaDeCocina = false
        local canInteract = not Cocinando and not MenuAbierto
        
        -- Optimización: Solo verificar si se movió significativamente
        if #(coords - lastCoords) > 2.0 then
            lastCoords = coords
            
            for nombre, cocina in pairs(Config.Cocinas) do
                local dist = #(coords - cocina.pos)
                
                if dist <= cocina.radio then
                    cercaDeCocina = true
                    CocinaActual = nombre 
                    waitTime = 0 -- Revisar más frecuentemente cuando está cerca
                    
                    if canInteract then
                        ESX.ShowHelpNotification("Presiona ~INPUT_CONTEXT~ para cocinar en " .. cocina.blipName .. ".")

                        if IsControlJustReleased(0, 51) then -- E
                            AbrirMenuCocina()
                        end
                    end
                    break
                end
            end
            
            if not cercaDeCocina then
                CocinaActual = nil
                waitTime = 500 -- Revisar menos frecuentemente cuando está lejos
            end
        end
        
        -- Deshabilitar controles mientras cocina
        if Cocinando then
            DisableControlActions()
        end
        
        Citizen.Wait(waitTime)
    end
end)

-- ====================================================================
-- 3. SISTEMA DE BLIPS MEJORADO
-- ====================================================================

function AddCocinaBlips()
    if not Config.EnableBlips then return end
    
    for nombre, cocina in pairs(Config.Cocinas) do
        local blip = AddBlipForCoord(cocina.pos.x, cocina.pos.y, cocina.pos.z)
        
        SetBlipSprite(blip, cocina.blipSprite or 436)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, cocina.blipScale or 0.8)
        SetBlipColour(blip, cocina.blipColor or 1)
        SetBlipAsShortRange(blip, true)
        
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(cocina.blipName or "Cocina")
        EndTextCommandSetBlipName(blip)
        
        if Config.Debug then
            print('^2[COCINA]^7 Blip creado: ' .. (cocina.blipName or nombre))
        end
    end
end

-- ====================================================================
-- 4. MENÚ DE COCINA MEJORADO
-- ====================================================================

function AbrirMenuCocina()
    if MenuAbierto or Cocinando then 
        ESX.ShowNotification('~y~El menú ya está abierto o estás cocinando')
        return 
    end
    
    MenuAbierto = true
    
    local elements = {}
    local jobName = PlayerData.job.name
    local jobGrade = PlayerData.job.grade or 0

    for platoFinal, data in pairs(Config.Recetas) do
        -- Verificar si la receta está disponible
        if IsRecipeAvailable(data, jobName, jobGrade) then
            local ingredientesStr = FormatIngredients(data.ingredientes)
            local labelInfo = GetRecipeLabelInfo(data, jobName, jobGrade)
            
            table.insert(elements, {
                label = labelInfo.text,
                value = platoFinal,
                jobRequired = data.trabajoRequerido,
                gradeRequired = data.nivelRequerido,
                font_color = labelInfo.color
            })
        end
    end

    if #elements == 0 then
        ESX.ShowNotification('~y~No hay recetas disponibles')
        MenuAbierto = false
        return
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cocina_menu', {
        title    = '🍳 Cocina Casera - ' .. (Config.Cocinas[CocinaActual]?.blipName or 'Cocina'),
        align    = 'right',
        elements = elements
    }, function(data, menu)
        menu.close()
        MenuAbierto = false
        
        local platoSeleccionado = data.current.value
        local receta = Config.Recetas[platoSeleccionado]
        
        -- Validación final antes de cocinar
        if not ValidateRecipeAccess(receta, PlayerData.job.name, PlayerData.job.grade) then
            ESX.ShowNotification('~r~No cumples con los requisitos para esta receta')
            return
        end

        IniciarProcesoCocina(platoSeleccionado, receta)

    end, function(data, menu)
        menu.close()
        MenuAbierto = false
        ESX.ShowNotification('~y~Menú de cocina cerrado')
    end, function(data, menu)
        -- Actualizar en tiempo real
    end)
end

-- ====================================================================
-- 5. PROCESO DE COCINA MEJORADO
-- ====================================================================

function IniciarProcesoCocina(plato, receta)
    Cocinando = true
    
    -- Verificar ingredientes primero
    ESX.TriggerServerCallback('esx_cocinacasera:verificarIngredientes', function(tieneIngredientes)
        if not tieneIngredientes then
            Cocinando = false
            ESX.ShowNotification('~r~No tienes los ingredientes necesarios')
            return
        end
        
        -- Iniciar animación
        if not PlayCookingAnimation(receta.animDict, receta.animName) then
            ESX.ShowNotification('~r~Error al cargar la animación')
            Cocinando = false
            return
        end
        
        -- Barra de progreso mejorada
        ESX.Progressbar('cocinando_' .. plato, '🍳 Cocinando ' .. receta.label, receta.tiempo, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            anim = {
                dict = receta.animDict,
                clip = receta.animName
            },
            prop = receta.prop -- Soporte para props opcionales
        }, function(success)
            if success then
                TriggerServerEvent('esx_cocinacasera:procesarCocina', plato)
                ESX.ShowNotification('~g~¡Plato cocinado exitosamente!')
            end
            Cocinando = false
            ClearPedTasks(PlayerPedId())
            StopAnimation(receta.animDict)
        end, function()
            -- Al cancelar
            Cocinando = false
            ClearPedTasks(PlayerPedId())
            StopAnimation(receta.animDict)
            TriggerServerEvent('esx_cocinacasera:cancelarCocina')
            ESX.ShowNotification('~y~Cocina cancelada')
        end)
        
    end, plato)
end

-- ====================================================================
-- 6. SISTEMA DE ANIMACIONES MEJORADO
-- ====================================================================

function PlayCookingAnimation(dict, anim)
    if not dict or not anim then
        if Config.Debug then
            print('^3[COCINA]^7 Animación no definida, usando animación por defecto')
        end
        dict = 'amb@world_human_cooking@male@base'
        anim = 'base'
    end
    
    -- Cargar diccionario de animación con timeout
    if not LoadedAnimDicts[dict] then
        RequestAnimDict(dict)
        
        local timeout = 5000 -- 5 segundos máximo
        local startTime = GetGameTimer()
        
        while not HasAnimDictLoaded(dict) do
            if GetGameTimer() - startTime > timeout then
                print('^1[COCINA]^7 Timeout cargando animación: ' .. dict)
                return false
            end
            Citizen.Wait(10)
        end
        LoadedAnimDicts[dict] = true
    end
    
    local ped = PlayerPedId()
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    CurrentAnimation = {dict = dict, anim = anim}
    
    return true
end

function StopAnimation(dict)
    if CurrentAnimation then
        local ped = PlayerPedId()
        StopAnimTask(ped, CurrentAnimation.dict, CurrentAnimation.anim, 1.0)
        CurrentAnimation = nil
    end
end

-- ====================================================================
-- 7. FUNCIONES UTILITARIAS MEJORADAS
-- ====================================================================

function IsRecipeAvailable(receta, jobName, jobGrade)
    if receta.trabajoRequerido and receta.trabajoRequerido ~= jobName then
        return false
    end
    
    if jobGrade < (receta.nivelRequerido or 0) then
        return false
    end
    
    return true
end

function FormatIngredients(ingredientes)
    local formatted = {}
    for _, ing in pairs(ingredientes) do
        local itemLabel = ESX.GetItemLabel(ing.item) or ing.item 
        table.insert(formatted, ing.cantidad .. 'x ' .. itemLabel)
    end
    return table.concat(formatted, ', ')
end

function GetRecipeLabelInfo(receta, jobName, jobGrade)
    local text = receta.label
    local color = '#ffffff'
    
    if receta.trabajoRequerido then
        text = '[PRO] ' .. text
        color = '#4CAF50' -- Verde para profesionales
    end
    
    if receta.nivelRequerido and receta.nivelRequerido > 0 then
        text = '[NIVEL ' .. receta.nivelRequerido .. '] ' .. text
        if jobGrade < receta.nivelRequerido then
            color = '#FF9800' -- Naranja para nivel insuficiente
        end
    end
    
    return {text = text, color = color}
end

function ValidateRecipeAccess(receta, jobName, jobGrade)
    if receta.trabajoRequerido and receta.trabajoRequerido ~= jobName then
        return false, 'Trabajo requerido: ' .. receta.trabajoRequerido
    end
    
    if jobGrade < (receta.nivelRequerido or 0) then
        return false, 'Nivel requerido: ' .. receta.nivelRequerido
    end
    
    return true
end

function DisableControlActions()
    DisableAllControlActions(0)
    -- Permitir algunas teclas esenciales
    EnableControlAction(0, 1, true)  -- Mouse
    EnableControlAction(0, 2, true)  -- Mouse
    EnableControlAction(0, 249, true) -- Push to talk
end

-- ====================================================================
-- 8. CLEANUP Y SEGURIDAD
-- ====================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Limpiar todo
        if Cocinando then
            ClearPedTasks(PlayerPedId())
            TriggerServerEvent('esx_cocinacasera:cancelarCocina')
        end
        
        if MenuAbierto then
            ESX.UI.Menu.CloseAll()
        end
        
        -- Liberar animaciones
        for dict, _ in pairs(LoadedAnimDicts) do
            RemoveAnimDict(dict)
        end
        
        if Config.Debug then
            print('^2[COCINA]^7 Recurso detenido - Cleanup completado')
        end
    end
end)

-- Evento para cancelación remota
RegisterNetEvent('esx_cocinacasera:cancelarCocina')
AddEventHandler('esx_cocinacasera:cancelarCocina', function()
    if Cocinando then
        Cocinando = false
        ClearPedTasks(PlayerPedId())
        if CurrentAnimation then
            StopAnimation(CurrentAnimation.dict)
        end
        ESX.ShowNotification('~y~Cocina cancelada')
    end
end)

-- ====================================================================
-- 9. COMANDOS DE DEBUG (OPCIONAL)
-- ====================================================================

if Config.Debug then
    RegisterCommand('cocina_debug', function()
        print('^2[COCINA-DEBUG]^7 Estado actual:')
        print('Cocinando: ' .. tostring(Cocinando))
        print('MenuAbierto: ' .. tostring(MenuAbierto))
        print('CocinaActual: ' .. tostring(CocinaActual))
        print('Job: ' .. PlayerData.job.name .. ' Grado: ' .. PlayerData.job.grade)
    end, false)
end

print('^2[COCINA]^7 Cliente de cocina cargado - Listo para usar')