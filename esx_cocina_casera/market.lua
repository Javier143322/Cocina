-- ====================================================================
-- SISTEMA DE MERCADO DE COCINA
-- ====================================================================

ESX = nil
local MarketPrices = {}
local PlayerSales = {}

-- ====================================================================
-- 1. INICIALIZACIÓN
-- ====================================================================

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
    
    -- Inicializar precios de mercado
    InitializeMarketPrices()
    
    if Config.Debug then
        print('^2[COCINA-MARKET]^7 Sistema de mercado inicializado')
    end
end)

-- ====================================================================
-- 2. CONFIGURACIÓN DEL MERCADO
-- ====================================================================

Config.Mercado = {
    impuesto_venta = 0.10, -- 10% de impuesto
    precio_base_multiplier = 1.5,
    fluctuacion_diaria = 0.2, -- 20% fluctuación
    items_comprables = {
        'carne', 'vegetales', 'sal', 'agua', 'aceite', 'harina', 'huevo', 'azucar'
    },
    ubicaciones_mercado = {
        vector3(73.0, -1392.0, 29.0), -- Tienda de ropa (ejemplo)
        vector3(-707.0, -914.0, 19.0), -- Supermercado
        vector3(374.0, 327.0, 103.0)  -- Tienda norte
    }
}

-- ====================================================================
-- 3. SISTEMA DE PRECIOS DINÁMICOS
-- ====================================================================

function InitializeMarketPrices()
    for itemName, itemData in pairs(Config.Items) do
        if itemData.tipo == 'ingrediente' or itemData.tipo == 'comida' then
            -- Precio base basado en la rareza y utilidad
            local precioBase = CalculateBasePrice(itemName, itemData)
            
            -- Aplicar fluctuación diaria
            local fluctuacion = (math.random() * 2 - 1) * Config.Mercado.fluctuacion_diaria
            local precioFinal = math.floor(precioBase * (1 + fluctuacion))
            
            MarketPrices[itemName] = {
                precio_compra = precioFinal,
                precio_venta = math.floor(precioFinal * 0.7), -- 70% del precio de compra
                fluctuacion = fluctuacion,
                ultima_actualizacion = os.time()
            }
        end
    end
    
    if Config.Debug then
        print('^2[COCINA-MARKET]^7 Precios de mercado inicializados: ' .. GetTableLength(MarketPrices) .. ' items')
    end
end

function CalculateBasePrice(itemName, itemData)
    local preciosBase = {
        -- Ingredientes básicos
        ['carne'] = 45,
        ['vegetales'] = 25,
        ['lechuga'] = 15,
        ['tomate'] = 12,
        ['zanahoria'] = 10,
        ['sal'] = 5,
        ['agua'] = 3,
        ['aceite'] = 20,
        ['harina'] = 8,
        ['chocolate'] = 35,
        ['huevo'] = 8,
        ['azucar'] = 10,
        ['mantequilla'] = 25,
        ['naranja'] = 8,
        
        -- Platos terminados (más caros que la suma de ingredientes)
        ['guisado_casero'] = 150,
        ['ensalada_fresca'] = 80,
        ['pastel_chocolate'] = 200,
        ['jugo_natural'] = 40
    }
    
    return preciosBase[itemName] or 10
end

-- ====================================================================
-- 4. EVENTOS DE COMPRA Y VENTA
-- ====================================================================

-- Comprar ingredientes
RegisterNetEvent('esx_cocinacasera:comprarIngrediente')
AddEventHandler('esx_cocinacasera:comprarIngrediente', function(itemName, cantidad)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    cantidad = math.floor(math.abs(cantidad or 1))
    
    -- Verificar que el item es comprable
    if not IsItemPurchasable(itemName) then
        TriggerClientEvent('esx:showNotification', source, '❌ Este item no está disponible para compra')
        return
    end
    
    -- Obtener precio
    local precioInfo = MarketPrices[itemName]
    if not precioInfo then
        TriggerClientEvent('esx:showNotification', source, '❌ Error: Precio no disponible')
        return
    end
    
    local costoTotal = precioInfo.precio_compra * cantidad
    
    -- Verificar dinero
    if xPlayer.getMoney() < costoTotal then
        TriggerClientEvent('esx:showNotification', source, '❌ Dinero insuficiente. Necesitas: $' .. costoTotal)
        return
    end
    
    -- Realizar compra
    xPlayer.removeMoney(costoTotal)
    xPlayer.addInventoryItem(itemName, cantidad)
    
    -- Actualizar estadísticas de mercado
    UpdateMarketStatistics(itemName, 'compra', cantidad, precioInfo.precio_compra)
    
    TriggerClientEvent('esx:showNotification', source, '✅ Comprado: ' .. cantidad .. 'x ' .. (Config.Items[itemName]?.label or itemName))
    TriggerClientEvent('esx:showNotification', source, '💰 Gastado: $' .. costoTotal)
    
    if Config.Debug then
        print('^2[COCINA-MARKET]^7 Compra: ' .. source .. ' - ' .. itemName .. ' x' .. cantidad .. ' - $' .. costoTotal)
    end
end)

-- Vender platos cocinados
RegisterNetEvent('esx_cocinacasera:venderPlato')
AddEventHandler('esx_cocinacasera:venderPlato', function(itemName, cantidad)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    cantidad = math.floor(math.abs(cantidad or 1))
    
    -- Verificar que tiene los items
    local item = xPlayer.getInventoryItem(itemName)
    if not item or item.count < cantidad then
        TriggerClientEvent('esx:showNotification', source, '❌ No tienes suficientes ' .. (Config.Items[itemName]?.label or itemName))
        return
    end
    
    -- Verificar que es un plato vendible
    if not IsItemSellable(itemName) then
        TriggerClientEvent('esx:showNotification', source, '❌ No puedes vender este item')
        return
    end
    
    -- Obtener precio de venta
    local precioInfo = MarketPrices[itemName]
    if not precioInfo then
        TriggerClientEvent('esx:showNotification', source, '❌ Error: Precio de venta no disponible')
        return
    end
    
    local gananciaBruta = precioInfo.precio_venta * cantidad
    local impuesto = math.floor(gananciaBruta * Config.Mercado.impuesto_venta)
    local gananciaNeta = gananciaBruta - impuesto
    
    -- Realizar venta
    xPlayer.removeInventoryItem(itemName, cantidad)
    xPlayer.addMoney(gananciaNeta)
    
    -- Actualizar estadísticas
    UpdateMarketStatistics(itemName, 'venta', cantidad, precioInfo.precio_venta)
    UpdatePlayerSales(xPlayer.identifier, itemName, cantidad, gananciaNeta)
    
    TriggerClientEvent('esx:showNotification', source, '💰 Vendido: ' .. cantidad .. 'x ' .. (Config.Items[itemName]?.label or itemName))
    TriggerClientEvent('esx:showNotification', source, '💵 Ganancia: $' .. gananciaNeta .. ' (Impuesto: -$' .. impuesto .. ')')
    
    if Config.Debug then
        print('^2[COCINA-MARKET]^7 Venta: ' .. source .. ' - ' .. itemName .. ' x' .. cantidad .. ' - $' .. gananciaNeta)
    end
end)

-- ====================================================================
-- 5. FUNCIONES UTILITARIAS
-- ====================================================================

function IsItemPurchasable(itemName)
    for _, itemComprable in ipairs(Config.Mercado.items_comprables) do
        if itemComprable == itemName then
            return true
        end
    end
    return false
end

function IsItemSellable(itemName)
    local itemData = Config.Items[itemName]
    return itemData and (itemData.tipo == 'comida' or itemData.tipo == 'bebida')
end

function UpdateMarketStatistics(itemName, tipo, cantidad, precio)
    if not MarketPrices[itemName].estadisticas then
        MarketPrices[itemName].estadisticas = {
            total_comprado = 0,
            total_vendido = 0,
            volumen_compra = 0,
            volumen_venta = 0
        }
    end
    
    if tipo == 'compra' then
        MarketPrices[itemName].estadisticas.total_comprado = MarketPrices[itemName].estadisticas.total_comprado + cantidad
        MarketPrices[itemName].estadisticas.volumen_compra = MarketPrices[itemName].estadisticas.volumen_compra + (cantidad * precio)
    else
        MarketPrices[itemName].estadisticas.total_vendido = MarketPrices[itemName].estadisticas.total_vendido + cantidad
        MarketPrices[itemName].estadisticas.volumen_venta = MarketPrices[itemName].estadisticas.volumen_venta + (cantidad * precio)
    end
    
    -- Ajustar precios basado en oferta/demanda
    AdjustPricesBasedOnDemand(itemName)
end

function UpdatePlayerSales(identifier, itemName, cantidad, ganancia)
    if not PlayerSales[identifier] then
        PlayerSales[identifier] = {}
    end
    
    if not PlayerSales[identifier][itemName] then
        PlayerSales[identifier][itemName] = {
            total_vendido = 0,
            ganancia_total = 0
        }
    end
    
    PlayerSales[identifier][itemName].total_vendido = PlayerSales[identifier][itemName].total_vendido + cantidad
    PlayerSales[identifier][itemName].ganancia_total = PlayerSales[identifier][itemName].ganancia_total + ganancia
    
    SavePlayerSales(identifier)
end

function AdjustPricesBasedOnDemand(itemName)
    local stats = MarketPrices[itemName].estadisticas
    if not stats then return end
    
    -- Si hay mucha demanda (compras > ventas), subir precio
    local ratio_demanda = stats.total_comprado / math.max(stats.total_vendido, 1)
    
    if ratio_demanda > 1.5 then
        -- Alta demanda, subir precio 5%
        MarketPrices[itemName].precio_compra = math.floor(MarketPrices[itemName].precio_compra * 1.05)
        MarketPrices[itemName].precio_venta = math.floor(MarketPrices[itemName].precio_venta * 1.05)
    elseif ratio_demanda < 0.5 then
        -- Baja demanda, bajar precio 5%
        MarketPrices[itemName].precio_compra = math.floor(MarketPrices[itemName].precio_compra * 0.95)
        MarketPrices[itemName].precio_venta = math.floor(MarketPrices[itemName].precio_venta * 0.95)
    end
end

-- ====================================================================
-- 6. BASE DE DATOS
-- ====================================================================

function SavePlayerSales(identifier)
    MySQL.Async.execute('INSERT INTO cocina_ventas (identifier, ventas) VALUES (@identifier, @ventas) ON DUPLICATE KEY UPDATE ventas = @ventas', {
        ['@identifier'] = identifier,
        ['@ventas'] = json.encode(PlayerSales[identifier])
    })
end

function LoadPlayerSales(identifier)
    MySQL.Async.fetchScalar('SELECT ventas FROM cocina_ventas WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result then
            PlayerSales[identifier] = json.decode(result)
        end
    end)
end

-- ====================================================================
-- 7. COMANDOS Y EXPORTACIONES
-- ====================================================================

-- Export para obtener precios de mercado
exports('GetMarketPrices', function()
    return MarketPrices
end)

-- Comando para ver precios
RegisterCommand('cocinaprecios', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    TriggerClientEvent('esx:showNotification', source, '💰 Precios del mercado de cocina:')
    
    for itemName, precioInfo in pairs(MarketPrices) do
        local itemLabel = Config.Items[itemName]?.label or itemName
        TriggerClientEvent('esx:showNotification', source, '🛒 ' .. itemLabel .. ': Compra $' .. precioInfo.precio_compra .. ' | Venta $' .. precioInfo.precio_venta)
    end
end, false)

-- Comando para vender todo
RegisterCommand('vendercomida', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local itemsVendidos = 0
    local gananciaTotal = 0
    
    for itemName, itemData in pairs(Config.Items) do
        if IsItemSellable(itemName) then
            local item = xPlayer.getInventoryItem(itemName)
            if item and item.count > 0 then
                local cantidad = item.count
                local precioInfo = MarketPrices[itemName]
                
                if precioInfo then
                    local ganancia = math.floor(precioInfo.precio_venta * cantidad * (1 - Config.Mercado.impuesto_venta))
                    
                    xPlayer.removeInventoryItem(itemName, cantidad)
                    xPlayer.addMoney(ganancia)
                    
                    itemsVendidos = itemsVendidos + cantidad
                    gananciaTotal = gananciaTotal + ganancia
                    
                    UpdatePlayerSales(xPlayer.identifier, itemName, cantidad, ganancia)
                end
            end
        end
    end
    
    if itemsVendidos > 0 then
        TriggerClientEvent('esx:showNotification', source, '💰 Vendidos ' .. itemsVendidos .. ' items por $' .. gananciaTotal)
    else
        TriggerClientEvent('esx:showNotification', source, '❌ No tienes comida para vender')
    end
end, false)

-- ====================================================================
-- 8. CREACIÓN DE TABLAS EN BASE DE DATOS
-- ====================================================================

MySQL.ready(function()
    -- Tabla de ventas de jugadores
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `cocina_ventas` (
            `identifier` varchar(60) NOT NULL,
            `ventas` longtext NOT NULL,
            `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Tabla de estadísticas de mercado
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `cocina_mercado` (
            `item_name` varchar(50) NOT NULL,
            `estadisticas` longtext NOT NULL,
            `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`item_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(rowsChanged)
        if Config.Debug then
            print('^2[COCINA-MARKET]^7 Tablas de mercado inicializadas')
        end
    end)
end)

-- ====================================================================
-- 9. ACTUALIZACIÓN DIARIA DE PRECIOS
-- ====================================================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(24 * 60 * 60 * 1000) -- 24 horas
        InitializeMarketPrices() -- Resetear precios diariamente
        
        if Config.Debug then
            print('^2[COCINA-MARKET]^7 Precios de mercado actualizados')
        end
    end
end)

print('^2[COCINA-MARKET]^7 Sistema de mercado cargado')
