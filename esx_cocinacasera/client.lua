-- ====================================================================
-- MÓDULO 2: LADO DEL CLIENTE (client.lua) - FINAL (Refactorizado)
-- Ahora lee toda la información desde el archivo 'config.lua'.
-- ====================================================================

ESX = nil
local PlayerData = {}
local Cocinando = false

-- 1. Las Recetas y Coordenadas ahora se leen desde la tabla global 'Config'

-- 2. Inicializar ESX y obtener datos del jugador
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

    -- Iniciar el Blip de la Cocina usando la configuración
    AddCocinaBlip()
end)

-- 3. Bucle principal: Detección de Zona y Menú
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        local coords = GetEntityCoords(PlayerPedId())
        local dist = GetDistanceBetweenCoords(coords, Config.CocinaTest.pos, true)
        
        if dist <= Config.CocinaTest.radio and not Cocinando then
            ESX.ShowHelpNotification("Presiona ~INPUT_CONTEXT~ para cocinar.")

            if IsControlJustReleased(0, 51) then
                AbrirMenuCocina()
            end
        elseif dist > Config.CocinaTest.radio then
            Citizen.Wait(500)
        end
        
        if Cocinando then
            DisableAllControlActions(0)
        end
    end
end)

-- 4. Añadir Blip al mapa
function AddCocinaBlip()
    local blip = AddBlipForCoord(Config.CocinaTest.pos.x, Config.CocinaTest.pos.y, Config.CocinaTest.pos.z)
    
    SetBlipSprite (blip, Config.CocinaTest.blipSprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale  (blip, 0.8)
    SetBlipColour (blip, Config.CocinaTest.blipColor)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Config.CocinaTest.blipName)
    EndTextCommandSetBlipName(blip)
end


-- 5. Función para generar y mostrar el menú
function AbrirMenuCocina()
    local elements = {}
    local job = PlayerData.job.name

    -- Iteramos sobre la Configuración
    for platoFinal, data in pairs(Config.Recetas) do
        local ingredientesStr = {}
        for _, ing in pairs(data.ingredientes) do
            local itemLabel = ESX.GetItemLabel(ing.item) or ing.item 
            table.insert(ingredientesStr, ing.cantidad .. 'x ' .. itemLabel)
        end
        
        local label = data.label .. ' (' .. table.concat(ingredientesStr, ', ') .. ')'
        local color = '#ffffff'

        -- Lógica para el trabajo requerido (UX)
        if data.trabajoRequerido and data.trabajoRequerido ~= job then
            label = '~r~ [PRO] ' .. label 
            color = '#ff4444'
        end

        table.insert(elements, {
            label = label,
            value = platoFinal,
            jobRequired = data.trabajoRequerido,
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
            
            local platoSeleccionado = data.current.value
            local receta = Config.Recetas[platoSeleccionado]
            
            if receta.trabajoRequerido and receta.trabajoRequerido ~= PlayerData.job.name then
                ESX.ShowNotification('~r~No tienes la experiencia necesaria para cocinar este plato.')
                return
            end

            ProcessoCocina(platoSeleccionado, receta.tiempo)

        end,
        function(data, menu)
            menu.close()
        end
    )
end

-- 6. Función para la animación y barra de progreso
function ProcessoCocina(plato, tiempo)
    Cocinando = true
    
    -- El servidor ya tiene la receta y el tiempo gracias a 'config.lua'
    ESX.TriggerServerCallback('esx_cocinacasera:cocinarPlato', function(resultado)
        if resultado then
            -- El tiempo y el proceso de verificación de ingredientes en el servidor terminaron.
            -- El resultado final (éxito/falla) se maneja en 'esx_cocinacasera:procesarCocina'
        else
            Cocinando = false
            ClearPedTasks(PlayerPedId())
        end
    end, plato, tiempo)
    
    -- Tareas visuales del cliente
    local ped = PlayerPedId()
    local dict = "amb@prop_human_bbq@male@idle_a"
    local anim = "idle_b"
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, tiempo, 1, 0, false, false, false)
    
    ESX.Progressbar(
        'cocinando',
        'Cocinando ' .. Config.Recetas[plato].label .. '...',
        tiempo,
        false, 
        false, 
        {},
        function() -- Al completar la barra
            Cocinando = false
            ClearPedTasks(PlayerPedId())
        end,
        function(cancelled) 
            if cancelled then
                Cocinando = false
                ClearPedTasks(PlayerPedId())
                ESX.ShowNotification('~r~Cocina cancelada.')
            end
        end
    )
end