-- ====================================================================
-- MÓDULO 2: LADO DEL CLIENTE (client.lua) - FINAL (Seguro y Animado)
-- Añade: Bloqueo de menú Anti-Spam y Animaciones Condicionales.
-- ====================================================================

ESX = nil
local PlayerData = {}
local Cocinando = false
local CocinaActual = nil 
local MenuAbierto = false -- ¡NUEVO! Variable de estado para el Anti-Spam del menú

-- 1. Inicializar ESX y obtener datos del jugador
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
    while ESX.GetPlayerData().job == nil do 
        Citizen.Wait(10)
    end
    PlayerData = ESX.GetPlayerData()
    
    RegisterNetEvent('esx:setPlayerData')
    AddEventHandler('esx:setPlayerData', function(ndata)
        PlayerData = ndata
    end)

    -- Iniciar todos los Blips de Cocina
    AddCocinaBlips()
end)

-- 2. Bucle principal: Detección de Zonas Múltiples y Menú
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        local coords = GetEntityCoords(PlayerPedId())
        local cercaDeCocina = false
        local canInteract = not Cocinando and not MenuAbierto -- Nueva condición de interacción
        
        for nombre, cocina in pairs(Config.Cocinas) do
            local dist = GetDistanceBetweenCoords(coords, cocina.pos, true)
            
            if dist <= cocina.radio then
                cercaDeCocina = true
                CocinaActual = nombre 
                
                if canInteract then
                    ESX.ShowHelpNotification("Presiona ~INPUT_CONTEXT~ para cocinar en " .. cocina.blipName .. ".")

                    if IsControlJustReleased(0, 51) then
                        AbrirMenuCocina()
                    end
                end
                break 
            end
        end

        if not cercaDeCocina then
            CocinaActual = nil
            Citizen.Wait(500)
        end
        
        if Cocinando then
            DisableAllControlActions(0)
        end
    end
end)

-- 3. Añadir todos los Blips al mapa
function AddCocinaBlips()
    for _, cocina in pairs(Config.Cocinas) do
        local blip = AddBlipForCoord(cocina.pos.x, cocina.pos.y, cocina.pos.z)
        
        SetBlipSprite (blip, cocina.blipSprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale  (blip, 0.8)
        SetBlipColour (blip, cocina.blipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(cocina.blipName)
        EndTextCommandSetBlipName(blip)
    end
end


-- 4. Función para generar y mostrar el menú
function AbrirMenuCocina()
    if MenuAbierto then return end -- Bloqueo Anti-Spam
    MenuAbierto = true
    
    local elements = {}
    local job = PlayerData.job.name
    local jobGrade = PlayerData.job.grade or 0 

    for platoFinal, data in pairs(Config.Recetas) do
        local ingredientesStr = {}
        for _, ing in pairs(data.ingredientes) do
            local itemLabel = ESX.GetItemLabel(ing.item) or ing.item 
            table.insert(ingredientesStr, ing.cantidad .. 'x ' .. itemLabel)
        end
        
        local label = data.label .. ' (' .. table.concat(ingredientesStr, ', ') .. ')'
        local color = '#ffffff'

        if data.trabajoRequerido and data.trabajoRequerido ~= job then
            label = '~r~ [PRO] ' .. label 
            color = '#ff4444'
        elseif jobGrade < data.nivelRequerido then
            label = '~y~ [NIVEL ' .. data.nivelRequerido .. '] ' .. label
            color = '#ffcc00'
        end

        table.insert(elements, {
            label = label,
            value = platoFinal,
            jobRequired = data.trabajoRequerido,
            gradeRequired = data.nivelRequerido,
            font_color = color
        })
    end

    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'cocina_menu',
        {
            title    = 'Cocina Casera',
            align    = 'right',
            elements = elements
        },
        function(data, menu)
            menu.close()
            MenuAbierto = false -- Cerrar menú
            
            local platoSeleccionado = data.current.value
            local receta = Config.Recetas[platoSeleccionado]
            
            if receta.trabajoRequerido and receta.trabajoRequerido ~= PlayerData.job.name then
                ESX.ShowNotification('~r~No tienes el trabajo requerido para este plato.')
                return
            end
            
            if PlayerData.job.grade < receta.nivelRequerido then
                 ESX.ShowNotification('~r~Tu nivel (' .. PlayerData.job.grade .. ') es insuficiente (Req: ' .. receta.nivelRequerido .. ').')
                return
            end

            ProcessoCocina(platoSeleccionado, receta.tiempo)

        end,
        function(data, menu)
            menu.close()
            MenuAbierto = false -- Cancelar menú
        end
    )
end

-- 5. Función para la animación y barra de progreso
function ProcessoCocina(plato, tiempo)
    Cocinando = true
    
    ESX.TriggerServerCallback('esx_cocinacasera:cocinarPlato', function(resultado)
        if not resultado then
            Cocinando = false
            ClearPedTasks(PlayerPedId())
        end
    end, plato, tiempo)
    
    -- Tareas visuales del cliente (Animación Condicional)
    local ped = PlayerPedId()
    local receta = Config.Recetas[plato]
    local dict = receta.animDict
    local anim = receta.animName
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, tiempo, 1, 0, false, false, false)
    
    ESX.Progressbar(
        'cocinando',
        'Cocinando ' .. receta.label .. '...',
        tiempo,
        false, 
        false, 
        {},
        function() -- Al completar la barra
            Cocinando = false
            ClearPedTasks(PlayerPedId())
            TriggerServerEvent('esx_cocinacasera:procesarCocina', plato)
        end,
        function(cancelled) 
            if cancelled then
                Cocinando = false
                ClearPedTasks(PlayerPedId())
                TriggerServerEvent('esx_cocinacasera:cancelarCocina')
                ESX.ShowNotification('~r~Cocina cancelada.')
            end
        end
    )
end

-- 6. Nuevo evento para que el servidor sepa si se canceló
RegisterNetEvent('esx_cocinacasera:cancelarCocina')
AddEventHandler('esx_cocinacasera:cancelarCocina', function()
    -- Solo sirve como ping al servidor.
end)