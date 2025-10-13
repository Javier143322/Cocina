-- ====================================================================
-- MÓDULO 4: ACTUALIZACIÓN DE MANIFIESTO (fxmanifest.lua)
-- Asegura que se carguen los scripts del lado del cliente y del servidor.
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