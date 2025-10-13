-- ====================================================================
-- MÓDULO 1: CONFIGURACIÓN CENTRALIZADA (config.lua)
-- Todas las coordenadas, recetas, tiempos y requerimientos en un solo lugar.
-- ====================================================================

Config = {}

-- 1. CONFIGURACIÓN DE LA COCINA
Config.CocinaTest = {
    -- ADVERTENCIA: AJUSTA ESTAS COORDENADAS A TU UBICACIÓN DE COCINA
    pos = vector3(-810.0, 175.0, 78.0), 
    radio = 1.5,                      -- Distancia máxima para interactuar
    blipSprite = 374,                 -- Icono del blip (374 = cubiertos)
    blipColor = 2,                    -- Color del blip (2 = verde)
    blipName = "Cocina Principal"     -- Nombre que aparece en el mapa
}

-- 2. DEFINICIÓN DE RECETAS
-- Estructura: ['nombre_interno_del_plato'] = { ... }
Config.Recetas = {
    ['guisado'] = { 
        label = 'Guisado Casero',
        tiempo = 8000,              -- Tiempo de cocción en milisegundos (8 segundos)
        trabajoRequerido = 'chef',  -- 'chef' o nil si cualquiera puede cocinar
        probabilidadFalla = 15,     -- Probabilidad de fallo del 15% (1 a 100)
        ingredientes = {
            { item = 'carne', cantidad = 2 },
            { item = 'vegetales', cantidad = 1 },
            { item = 'sal', cantidad = 1 }
        }
    },
    ['ensalada'] = {
        label = 'Ensalada Refrescante',
        tiempo = 3000,              -- 3 segundos
        trabajoRequerido = nil,
        probabilidadFalla = 5,
        ingredientes = {
            { item = 'vegetales', cantidad = 3 }
        }
    },
    -- Puedes añadir nuevas recetas aquí sin tocar client.lua o server.lua:
    -- ['sopa_de_tomate'] = {
    --     label = 'Sopa de Tomate',
    --     tiempo = 5000,
    --     trabajoRequerido = 'chef',
    --     probabilidadFalla = 10,
    --     ingredientes = {
    --         { item = 'tomate', cantidad = 3 },
    --         { item = 'agua', cantidad = 1 }
    --     }
    -- }
}