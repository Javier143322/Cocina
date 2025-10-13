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
    'client.lua' -- Aquí estará la lógica de interacción y menú
}

server_scripts {
    '@es_extended/config.lua',
    'server.lua' -- Aquí estará la lógica de inventario y seguridad
}

