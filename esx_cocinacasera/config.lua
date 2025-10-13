-- ====================================================================
-- MÓDULO 1: CONFIGURACIÓN CENTRALIZADA (config.lua)
-- Versión Final: Multilocalización, Nutrición y Progresión.
-- ====================================================================

Config = {}

-- 1. CONFIGURACIÓN DE LAS COCINAS (¡MULTILOCALIZACIÓN!)
-- Se pueden añadir múltiples ubicaciones de cocina.
Config.Cocinas = {
    ['cocina_principal'] = {
        pos = vector3(-810.0, 175.0, 78.0), -- Ubicación de ejemplo 1
        radio = 1.5,
        blipSprite = 374,
        blipColor = 2,
        blipName = "Cocina Central"
    },
    ['cocina_secundaria'] = {
        pos = vector3(20.0, -100.0, 70.0), -- Ubicación de ejemplo 2 (cambiar a tu gusto)
        radio = 2.0,
        blipSprite = 374,
        blipColor = 5, -- Color diferente para distinguirlas
        blipName = "Punto de Cocina Rápida"
    }
}

-- 2. DEFINICIÓN DE RECETAS
-- Añade: Puntos de hambre/sed restaurados.
Config.Recetas = {
    ['guisado'] = { 
        label = 'Guisado Casero',
        tiempo = 8000,
        trabajoRequerido = 'chef',
        nivelRequerido = 3,         -- Nuevo: Requiere grado/nivel 3 o superior en el trabajo.
        baseFalla = 50,             -- Nuevo: Base de probabilidad de falla si no cumple el nivel.
        restoreHealth = 50,         -- Puntos de salud restaurados
        restoreHunger = 60,         -- Puntos de hambre restaurados (0-100)
        restoreThirst = 10,         -- Puntos de sed restaurados
        ingredientes = {
            { item = 'carne', cantidad = 2 },
            { item = 'vegetales', cantidad = 1 },
            { item = 'sal', cantidad = 1 }
        }
    },
    ['ensalada'] = {
        label = 'Ensalada Refrescante',
        tiempo = 3000,
        trabajoRequerido = nil,
        nivelRequerido = 0,         -- Cualquiera puede hacerla
        baseFalla = 10,
        restoreHealth = 25,
        restoreHunger = 20,
        restoreThirst = 40,
        ingredientes = {
            { item = 'vegetales', cantidad = 3 }
        }
    }
}