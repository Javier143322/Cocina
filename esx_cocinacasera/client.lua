-- ====================================================================
-- MÓDULO 2: LADO DEL CLIENTE (client.lua) - FINAL
-- Añade: Blip en el mapa y Animación/Barra de Progreso Inmersiva.
-- ====================================================================

ESX = nil
local PlayerData = {}
local Cocinando = false -- Nuevo estado para evitar que el jugador se mueva mientras cocina

-- 1. Definición de Recetas (Debe coincidir con la lógica del Servidor)
local Recetas = {
    ['guisado'] = { 
        label = 'Guisado Casero',
        ingredientes = {
            { item = 'carne', cantidad = 2 },
            { item = 'vegetales', cantidad = 1 },
            { item = 'sal', cantidad = 1 }
        },
        tiempo = 8000, -- 8 segundos de cocción
        trabajoRequerido = 'chef' -- Solo chefs pueden hacer guisado
    },
    ['ensalada'] = {
        label = 'Ensalada Refrescante',
        ingredientes = {
            { item = 'vegetales', cantidad = 3 }
        },
        tiempo = 3000, -- 3 segundos de cocción
        trabajoRequerido = nil -- Cualquiera puede hacer ensalada
    }
}

-- 2. Ubicación de Prueba de la Cocina
local CocinaTest = {
    pos = vector3(-810.0, 175.0, 78.0), -- Coordenadas de ejemplo (ajusta a tu gusto)
    radio = 1.5, -- Distancia máxima para interactuar
    blipId = 0
}

-- 3. Inicializar ESX y obtener datos del jugador
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
    while ESX.GetPlayerData().job == nil do 
        Citizen.Wait(10)
    end
    PlayerData = ESX.GetPlayerData()
    
    -- Listener para actualizar los datos del jugador (ej: cambio de trabajo)
    RegisterNetEvent('esx:setPlayerData')
    AddEventHandler('esx:setPlayerData', function(ndata)
        PlayerData = ndata
    end)

    -- Iniciar el Blip de la Cocina
    AddCocinaBlip()
end)

-- 4. Bucle principal: Detección de Zona y Menú
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        local coords = GetEntityCoords(PlayerPedId())
        local dist = GetDistanceBetweenCoords(coords, CocinaTest.pos, true)
        
        -- Si el jugador está cerca de la zona de cocina Y no está cocinando
        if dist <= CocinaTest.radio and not Cocinando then
            ESX.ShowHelpNotification("Presiona ~INPUT_CONTEXT~ para cocinar.")

            if IsControlJustReleased(0, 51) then
                AbrirMenuCocina()
            end
        elseif dist > CocinaTest.radio then
            Citizen.Wait(500)
        end
        
        -- Evita que el jugador se mueva si está en proceso de cocción
        if Cocinando then
            DisableAllControlActions(0)
        end
    end
end)

-- 5. Añadir Blip al mapa
function AddCocinaBlip()
    local blip = AddBlipForCoord(CocinaTest.pos.x, CocinaTest.pos.y, CocinaTest.pos.z)
    
    SetBlipSprite (blip, 374) -- Icono de cubiertos/restaurante
    SetBlipDisplay(blip, 4)
    SetBlipScale  (blip, 0.8)
    SetBlipColour (blip, 2) -- Color verde
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Cocina Principal")
    EndTextCommandSetBlipName(blip)
    
    CocinaTest.blipId = blip
end


-- 6. Función para generar y mostrar el menú
function AbrirMenuCocina()
    local elements = {}
    local job = PlayerData.job.name -- Obtiene el trabajo actual

    for platoFinal, data in pairs(Recetas) do
        local ingredientesStr = {}
        for _, ing in pairs(data.ingredientes) do
            local itemLabel = ESX.GetItemLabel(ing.item) or ing.item 
            table.insert(ingredientesStr, ing.cantidad .. 'x ' .. itemLabel)
        end
        
        local label = data.label .. ' (' .. table.concat(ingredientesStr, ', ') .. ')'
        local color = '#ffffff' -- Por defecto

        -- Lógica para el trabajo requerido
        if data.trabajoRequerido and data.trabajoRequerido ~= job then
            label = '~r~ [PRO] ' .. label -- Añadir indicador si está bloqueado
            color = '#ff4444'
        end

        -- Añadir el elemento al menú
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
            local receta = Recetas[platoSeleccionado]
            
            -- Bloqueo por Trabajo (lado cliente para UX)
            if receta.trabajoRequerido and receta.trabajoRequerido ~= PlayerData.job.name then
                ESX.ShowNotification('~r~No tienes la experiencia necesaria para cocinar este plato.')
                return
            end

            -- Iniciar la Animación y el Proceso
            ProcessoCocina(platoSeleccionado, receta.tiempo)

        end,
        function(data, menu)
            menu.close()
        end
    )
end

-- 7. Función para la animación y barra de progreso
function ProcessoCocina(plato, tiempo)
    -- Inicia la animación de "cocinar"
    Cocinando = true
    ESX.TriggerServerCallback('esx_cocinacasera:cocinarPlato', function(resultado)
        Cocinando = false
        ClearPedTasks(PlayerPedId()) -- Detiene la animación
        
        if resultado then
            -- Solo si el servidor devuelve TRUE (ingredientes correctos)
            -- Disparar el evento al Servidor para el procesamiento FINAL (quitar ingredientes y dar ítem)
            TriggerServerEvent('esx_cocinacasera:procesarCocina', plato)
        end
    end, plato, tiempo) -- Enviamos el plato y el tiempo al servidor
    
    -- Tareas visuales del cliente
    local ped = PlayerPedId()
    local dict = "amb@prop_human_bbq@male@idle_a" -- Diccionario de animación de barbacoa/cocina
    local anim = "idle_b"
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    
    -- Ejecuta la animación
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, tiempo, 1, 0, false, false, false)
    
    -- Muestra la barra de progreso
    ESX.Progressbar(
        'cocinando',
        'Cocinando ' .. Recetas[plato].label .. '...',
        tiempo,
        false, -- No se puede cancelar
        false, -- No se puede usar el vehículo
        {},
        nil,
        function() -- Al completar la barra
            -- NOTA: El resultado final lo maneja el Callback del servidor, no la barra.
        end,
        function(cancelled) -- Al cancelar la barra (no aplica en este caso)
            if cancelled then
                Cocinando = false
                ClearPedTasks(PlayerPedId())
                ESX.ShowNotification('~r~Cocina cancelada.')
            end
        end
    )
end