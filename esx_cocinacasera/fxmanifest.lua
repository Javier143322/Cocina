fx_version 'cerulean'
game 'gta5'

name 'esx_cocina_casera'
author 'TuNombre'
description 'Sistema avanzado de cocina casera con estadísticas, misiones, mercado y experiencia'
version '2.0.0'

-- ====================================================================
-- DEPENDENCIAS
-- ====================================================================
dependencies {
    'es_extended'
}

-- ====================================================================
-- CONFIGURACIÓN COMPARTIDA
-- ====================================================================
shared_scripts {
    'config.lua'                    -- Configuración principal
}

-- ====================================================================
-- SCRIPTS DEL CLIENTE
-- ====================================================================
client_scripts {
    'client.lua',                   -- Cliente principal (EXISTENTE)
    'fx_items.lua',                 -- Sistema de consumo (EXISTENTE)
    'stats.lua',                    -- NUEVO: Estadísticas
    'missions.lua',                 -- NUEVO: Misiones
    'market.lua',                   -- NUEVO: Mercado
    'experience.lua'                -- NUEVO: Experiencia avanzada
}

-- ====================================================================
-- SCRIPTS DEL SERVIDOR
-- ====================================================================
server_scripts {
    'server.lua',                   -- Servidor principal (EXISTENTE)
    'stats.lua',                    -- NUEVO: Estadísticas
    'missions.lua',                 -- NUEVO: Misiones  
    'market.lua',                   -- NUEVO: Mercado
    'experience.lua'                -- NUEVO: Experiencia avanzada
}

-- ====================================================================
-- INTERFAZ DE USUARIO (NUEVO)
-- ====================================================================
ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/css/styles.css',
    'html/js/app.js',
    'html/assets/icons/*.png',
    'html/assets/sounds/*.ogg'
}

-- ====================================================================
-- EXPORTACIONES
-- ====================================================================
exports {
    'CanPlayerCook',
    'GetPlayerRecipes', 
    'StartCookingProcess',
    'GetCookingStats',              -- NUEVA EXPORT
    'GetActiveMissions'             -- NUEVA EXPORT
}

server_exports {
    'RegisterNewRecipe',
    'GetCookingStats',
    'ValidateIngredients',
    'GetMarketPrices',              -- NUEVA EXPORT
    'GetPlayerExperience'           -- NUEVA EXPORT
}

-- ====================================================================
-- COMPATIBILIDAD
-- ====================================================================
lua54 'yes'