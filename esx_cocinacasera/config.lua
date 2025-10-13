-- ====================================================================
-- MÓDULO 1: CONFIGURACIÓN CENTRALIZADA (config.lua)
-- Versión Profesional: Multilocalización, Nutrición y Animaciones Únicas.
-- ====================================================================

Config = {}

-- 1. CONFIGURACIÓN DE LAS COCINAS (¡MULTILOCALIZACIÓN!)
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
        blipColor = 5, 
        blipName = "Punto de Cocina Rápida"
    }
}

-- 2. DEFINICIÓN DE RECETAS
-- Añade: Definición de la animación para cada plato.
Config.Recetas = {
    ['guisado'] = { 
        label = 'Guisado Casero',
        tiempo = 8000,
        trabajoRequerido = 'chef',
        nivelRequerido = 3,         
        baseFalla = 50,             
        restoreHealth = 50,         
        restoreHunger = 60,         
        restoreThirst = 10,         
        animDict = "amb@prop_human_bbq@male@idle_a", -- Animación de barbacoa
        animName = "idle_b",
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
        nivelRequerido = 0,         
        baseFalla = 10,
        restoreHealth = 25,
        restoreHunger = 20,
        restoreThirst = 40,
        animDict = "mini_game_balloon", -- Animación más corta o de preparación (ajustar si es necesario)
        animName = "prep_hotdog_a",
        ingredientes = {
            { item = 'vegetales', cantidad = 3 }
        }
    }
}