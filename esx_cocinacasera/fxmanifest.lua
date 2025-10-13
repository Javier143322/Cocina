-- ====================================================================
-- MÓDULO 4: ACTUALIZACIÓN DE MANIFIESTO (fxmanifest.lua)
-- Añade la carga del nuevo archivo de lógica de ítems.
-- ====================================================================

fx_version 'cerulean'
games { 'gta5' }

description 'Sistema de Cocina Casera - Construcción Paso a Paso'
version '1.0.0'

-- Dependencias: Aseguramos que ESX esté cargado
dependencies {
    'es_extended'
}

client_scripts {
    '@es_extended/config.lua',
    'client.lua',
    'fx_items.lua' -- ¡NUEVO ARCHIVO A CARGAR!
}

server_scripts {
    '@es_extended/config.lua',
    'server.lua',
    'fx_items.lua' -- ¡NUEVO ARCHIVO A CARGAR!
}
