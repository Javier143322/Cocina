-- ====================================================================
-- MÓDULO 4: ACTUALIZACIÓN DE MANIFIESTO (fxmanifest.lua)
-- Añade la carga del nuevo archivo de configuración.
-- ====================================================================

fx_version 'cerulean'
games { 'gta5' }

description 'Sistema de Cocina Casera - Construcción Paso a Paso'
version '1.1.0' -- Versión actualizada

-- Dependencias: Aseguramos que ESX esté cargado
dependencies {
    'es_extended'
}

shared_scripts {
    'config.lua' -- CARGA EL ARCHIVO DE CONFIGURACIÓN PARA AMBOS LADOS
}

client_scripts {
    '@es_extended/config.lua',
    'client.lua',
    'fx_items.lua'
}

server_scripts {
    '@es_extended/config.lua',
    'server.lua',
    'fx_items.lua'
}