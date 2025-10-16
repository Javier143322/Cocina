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
    'config.lua'
}

-- ====================================================================
-- SCRIPTS DEL CLIENTE
-- ====================================================================
client_scripts {
    'client/client.lua',
    'client/fx_items.lua',
    'modules/stats.lua',
    'modules/missions.lua', 
    'modules/market.lua',
    'modules/experience.lua'
}

-- ====================================================================
-- SCRIPTS DEL SERVIDOR  
-- ====================================================================
server_scripts {
    'server/server.lua',
    'modules/stats.lua',
    'modules/missions.lua',
    'modules/market.lua',
    'modules/experience.lua'
}

-- ====================================================================
-- INTERFAZ DE USUARIO
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
    'GetCookingStats',
    'GetActiveMissions'
}

server_exports {
    'RegisterNewRecipe',
    'GetCookingStats',
    'ValidateIngredients',
    'GetMarketPrices',
    'GetPlayerExperience'
}

lua54 'yes'