-- ====================================================================
-- MÓDULO 2: LADO DEL CLIENTE (client.lua)
-- (Revisado y Completo)
-- ====================================================================

ESX = nil
local PlayerData = {}

-- 1. Definición de Recetas (Debe coincidir con la lógica del Servidor)
-- Este es nuestro "diccionario" de lo que se puede cocinar y qué se necesita.
local Recetas = {
    -- Nombre interno del Plato Final (valor que se envía al servidor)
    ['guisado'] = { 
        label = 'Guisado Casero', -- Etiqueta amigable para el menú
        ingredientes = {
            { item = 'carne', cantidad = 2 },
            { item = 'vegetales', cantidad = 1 },
            { item = 'sal', cantidad = 1 }
        }
    },
    ['ensalada'] = {
        label = 'Ensalada Refrescante',
        ingredientes = {
            { item = 'vegetales', cantidad = 3 }
        }
    }
}

-- 2. Ubicación de Prueba de la Cocina
-- ADVERTENCIA: DEBES AJUSTAR ESTAS COORDENADAS A TU SERVIDOR.
local CocinaTest = {
    pos = vector3(-810.0, 175.0, 78.0), -- Coordenadas de ejemplo (ajusta a tu gusto)
    radio = 1.5 -- Distancia máxima para interactuar
}

-- 3. Inicializar ESX y obtener datos del jugador
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
    -- Esto asegura que tenemos los datos del jugador disponibles
    while ESX.GetPlayerData().job == nil do 
        Citizen.Wait(10)
    end
    PlayerData = ESX.GetPlayerData()
end)

-- 4. Bucle principal: Detección de Zona y Menú
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Mínima espera para no sobrecargar el CPU
        
        local coords = GetEntityCoords(PlayerPedId())
        local dist = GetDistanceBetweenCoords(coords, CocinaTest.pos, true)
        
        -- Si el jugador está cerca de la zona de cocina
        if dist <= CocinaTest.radio then
            ESX.ShowHelpNotification("Presiona ~INPUT_CONTEXT~ para cocinar.") -- Muestra "Presiona E"

            -- Si presiona la tecla de interacción (InputContext es 'E' por defecto)
            if IsControlJustReleased(0, 51) then
                AbrirMenuCocina()
            end
        else
            -- Si está lejos, esperamos un poco más
            Citizen.Wait(500)
        end
    end
end)

-- 5. Función para generar y mostrar el menú
function AbrirMenuCocina()
    local elements = {}

    -- Recorrer la tabla de recetas para construir el menú dinámicamente
    for platoFinal, data in pairs(Recetas) do
        local ingredientesStr = {}
        for _, ing in pairs(data.ingredientes) do
            -- Obtener la etiqueta real del ítem para mostrarla en el menú
            local itemLabel = ESX.GetItemLabel(ing.item) or ing.item 
            table.insert(ingredientesStr, ing.cantidad .. 'x ' .. itemLabel)
        end
        
        local label = data.label .. ' (' .. table.concat(ingredientesStr, ', ') .. ')'

        -- Añadir el elemento al menú
        table.insert(elements, {
            label = label,
            value = platoFinal -- Esto se envía al servidor
        })
    end

    -- Mostrar el menú
    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'cocina_menu',
        {
            title    = 'Cocina Casera',
            align    = 'right',
            elements = elements
        },
        function(data, menu)
            menu.close()
            
            -- Cuando el jugador selecciona un plato
            local platoSeleccionado = data.current.value
            
            -- ¡PASO CRUCIAL! Disparar el evento al Servidor para procesar la cocina
            TriggerServerEvent('esx_cocinacasera:cocinarPlato', platoSeleccionado)
        end,
        function(data, menu)
            menu.close()
        end
    )
end
