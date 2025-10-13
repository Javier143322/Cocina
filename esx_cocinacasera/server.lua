
ESX = nil

-- 1. Inicializa ESX cuando esté listo
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- 2. Definición de las recetas (¡DEBE COINCIDIR CON CLIENTE!)
local Recetas = {
    ['guisado'] = {
        label = 'Guisado Casero',
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

-- 3. Handler (Manejador) del evento de cocina
-- Este es el código que el cliente llama cuando selecciona un plato.
RegisterServerEvent('esx_cocinacasera:cocinarPlato')
AddEventHandler('esx_cocinacasera:cocinarPlato', function(platoFinal)
    local xPlayer = ESX.GetPlayerFromId(source) -- Obtenemos los datos del jugador
    
    -- A. Validación: ¿Existe la receta?
    if Recetas[platoFinal] then
        local receta = Recetas[platoFinal]
        local puedeCocinar = true
        
        -- B. Verificación de Ingredientes
        for _, ing in pairs(receta.ingredientes) do
            -- Comprobamos si el jugador tiene la cantidad necesaria
            if xPlayer.getInventoryItem(ing.item).count < ing.cantidad then
                puedeCocinar = false
                break -- Si falta uno, detenemos la verificación
            end
        end

        -- C. Procesamiento de la Receta
        if puedeCocinar then
            -- 1. Consumir Ingredientes
            for _, ing in pairs(receta.ingredientes) do
                xPlayer.removeInventoryItem(ing.item, ing.cantidad)
            end

            -- 2. Dar Plato Final al Jugador
            xPlayer.addInventoryItem(platoFinal, 1)

            -- 3. Mensaje de Éxito
            TriggerClientEvent('esx:showNotification', source, 'Has cocinado con éxito: ' .. receta.label .. '!')
        else
            -- 4. Mensaje de Error (Faltan Ingredientes)
            TriggerClientEvent('esx:showNotification', source, '¡Te faltan ingredientes para cocinar ' .. receta.label .. '!')
        end

    else
        -- 5. Mensaje de Error (Plato no válido)
        print(('ERROR: Plato %s no encontrado en las recetas!'):format(platoFinal))
    end
end)
