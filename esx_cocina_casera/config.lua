-- ====================================================================
-- SISTEMA DE COCINA CASERA - CONFIGURACIÓN PROFESIONAL
-- ====================================================================

Config = {}

-- ====================================================================
-- 1. CONFIGURACIÓN GENERAL DEL SISTEMA
-- ====================================================================
Config.Debug = true                      -- Activar mensajes de debug
Config.EnableBlips = true               -- Mostrar blips en el mapa
Config.EnableNotifications = true       -- Notificaciones del sistema
Config.EnableProgressBar = true         -- Barras de progreso visuales
Config.EnableAnimations = true          -- Animaciones durante la cocina
Config.EnableSoundEffects = true        -- Efectos de sonido
Config.EnableCookingXP = true           -- Sistema de experiencia

Config.Language = 'es'                  -- Idioma del sistema ('es', 'en')
Config.Framework = 'esx'                -- Framework compatible

-- ====================================================================
-- 2. CONFIGURACIÓN DE LAS COCINAS (MULTILOCALIZACIÓN MEJORADA)
-- ====================================================================
Config.Cocinas = {
    ['cocina_central'] = {
        pos = vector3(-810.0, 175.0, 78.0),
        radio = 1.5,
        blipSprite = 436,               -- Sprite más apropiado para cocina
        blipColor = 2,                  -- Verde
        blipScale = 0.8,
        blipName = "🍳 Cocina Central",
        allowedJobs = { 'chef', 'police', 'ambulance' }, -- Jobs permitidos
        requiredGrade = 0,              -- Grado mínimo requerido
        isProfessional = true           -- Cocina profesional
    },
    ['cocina_campamento'] = {
        pos = vector3(20.0, -100.0, 70.0),
        radio = 2.0,
        blipSprite = 436,
        blipColor = 5,                  -- Amarillo
        blipScale = 0.7,
        blipName = "🏕️ Cocina Básica",
        allowedJobs = nil,              -- Acceso libre
        requiredGrade = 0,
        isProfessional = false
    },
    ['cocina_restaurante'] = {
        pos = vector3(120.0, -300.0, 50.0),
        radio = 1.8,
        blipSprite = 436,
        blipColor = 49,                 -- Naranja
        blipScale = 0.9,
        blipName = "👨‍🍳 Restaurante",
        allowedJobs = { 'chef' },
        requiredGrade = 2,
        isProfessional = true
    }
}

-- ====================================================================
-- 3. SISTEMA DE RECETAS MEJORADO
-- ====================================================================
Config.Recetas = {
    -- CATEGORÍA: PLATOS PRINCIPALES
    ['guisado_casero'] = {
        label = '🥘 Guisado Casero',
        category = 'principal',
        tiempo = 15000,                 -- 15 segundos
        trabajoRequerido = 'chef',
        nivelRequerido = 2,
        baseFalla = 15,                 -- 15% base de fallar
        dificultad = 'media',           -- baja, media, alta
        
        -- SISTEMA DE NUTRICIÓN MEJORADO
        efectos = {
            salud = { min = 40, max = 60 },    -- Restaura 40-60 de salud
            hambre = { min = 70, max = 90 },   -- Reduce 70-90 de hambre
            sed = { min = 10, max = 20 },      -- Reduce 10-20 de sed
            stamina = { min = 15, max = 25 }   -- Aumenta stamina
        },
        
        -- RECOMPENSAS
        recompensaDinero = { min = 150, max = 250 },
        experiencia = 50,
        
        -- ANIMACIONES CORREGIDAS Y VALIDADAS
        animacion = {
            dict = 'amb@world_human_cooking@male@base',
            anim = 'base',
            flags = 1,
            prop = nil,                 -- Prop opcional
            propBone = nil
        },
        
        -- INGREDIENTES CON VALIDACIÓN
        ingredientes = {
            { item = 'carne', cantidad = 2, calidad = 'normal' },
            { item = 'vegetales', cantidad = 3, calidad = 'normal' },
            { item = 'sal', cantidad = 1, calidad = 'normal' },
            { item = 'agua', cantidad = 1, calidad = 'normal' }
        },
        
        -- ITEM RESULTANTE
        itemResultado = 'guisado_casero',
        cantidadResultado = 1
    },

    -- CATEGORÍA: ENSALADAS
    ['ensalada_fresca'] = {
        label = '🥗 Ensalada Fresca',
        category = 'ensalada',
        tiempo = 8000,                  -- 8 segundos
        trabajoRequerido = nil,         -- Acceso libre
        nivelRequerido = 0,
        baseFalla = 5,
        dificultad = 'baja',
        
        efectos = {
            salud = { min = 20, max = 30 },
            hambre = { min = 25, max = 40 },
            sed = { min = 30, max = 50 },
            stamina = { min = 10, max = 15 }
        },
        
        recompensaDinero = { min = 50, max = 80 },
        experiencia = 20,
        
        animacion = {
            dict = 'amb@prop_human_bbq@male@idle_a',
            anim = 'idle_b',
            flags = 1,
            prop = nil
        },
        
        ingredientes = {
            { item = 'lechuga', cantidad = 2 },
            { item = 'tomate', cantidad = 1 },
            { item = 'zanahoria', cantidad = 1 },
            { item = 'aceite', cantidad = 1 }
        },
        
        itemResultado = 'ensalada_fresca',
        cantidadResultado = 1
    },

    -- CATEGORÍA: POSTRES
    ['pastel_chocolate'] = {
        label = '🍰 Pastel de Chocolate',
        category = 'postre',
        tiempo = 20000,                 -- 20 segundos
        trabajoRequerido = 'chef',
        nivelRequerido = 3,
        baseFalla = 25,
        dificultad = 'alta',
        
        efectos = {
            salud = { min = 10, max = 20 },
            hambre = { min = 40, max = 60 },
            sed = { min = 5, max = 10 },
            stamina = { min = 5, max = 10 }
        },
        
        recompensaDinero = { min = 200, max = 350 },
        experiencia = 80,
        
        animacion = {
            dict = 'amb@world_human_cooking@male@base',
            anim = 'base',
            flags = 1,
            prop = nil
        },
        
        ingredientes = {
            { item = 'harina', cantidad = 2 },
            { item = 'chocolate', cantidad = 3 },
            { item = 'huevo', cantidad = 2 },
            { item = 'azucar', cantidad = 1 },
            { item = 'mantequilla', cantidad = 1 }
        },
        
        itemResultado = 'pastel_chocolate',
        cantidadResultado = 1
    },

    -- CATEGORÍA: BEBIDAS
    ['jugo_natural'] = {
        label = '🥤 Jugo Natural',
        category = 'bebida',
        tiempo = 5000,                  -- 5 segundos
        trabajoRequerido = nil,
        nivelRequerido = 0,
        baseFalla = 2,
        dificultad = 'baja',
        
        efectos = {
            salud = { min = 5, max = 10 },
            hambre = { min = 5, max = 10 },
            sed = { min = 60, max = 80 },
            stamina = { min = 20, max = 30 }
        },
        
        recompensaDinero = { min = 30, max = 50 },
        experiencia = 10,
        
        animacion = {
            dict = 'amb@world_human_drinking@beer@male@idle_a',
            anim = 'idle_a',
            flags = 49,
            prop = 'prop_cs_glass_stack',
            propBone = 28422
        },
        
        ingredientes = {
            { item = 'naranja', cantidad = 3 },
            { item = 'azucar', cantidad = 1 }
        },
        
        itemResultado = 'jugo_natural',
        cantidadResultado = 1
    }
}

-- ====================================================================
-- 4. SISTEMA DE ANIMACIONES PREDEFINIDAS
-- ====================================================================
Config.Animaciones = {
    cocina_base = {
        dict = 'amb@world_human_cooking@male@base',
        anim = 'base',
        flags = 1
    },
    cocina_bbq = {
        dict = 'amb@prop_human_bbq@male@idle_a',
        anim = 'idle_b',
        flags = 1
    },
    preparacion = {
        dict = 'amb@world_human_stand_fire@male@base',
        anim = 'base',
        flags = 1
    },
    mezclar = {
        dict = 'amb@world_human_bum_wash@male@high@base',
        anim = 'base',
        flags = 1
    }
}

-- ====================================================================
-- 5. SISTEMA DE EXPERIENCIA Y NIVELES
-- ====================================================================
Config.SistemaExperiencia = {
    activado = true,
    experienciaBase = 10,
    multiplicadorDificultad = {
        baja = 1.0,
        media = 1.5,
        alta = 2.0
    },
    niveles = {
        { nivel = 1, expRequerida = 0, bonus = 0 },
        { nivel = 2, expRequerida = 100, bonus = 5 },
        { nivel = 3, expRequerida = 300, bonus = 10 },
        { nivel = 4, expRequerida = 600, bonus = 15 },
        { nivel = 5, expRequerida = 1000, bonus = 20 }
    }
}

-- ====================================================================
-- 6. CONFIGURACIÓN DE FALLAS Y CALIDAD
-- ====================================================================
Config.SistemaCalidad = {
    -- Factores que afectan la probabilidad de falla
    factoresFalla = {
        porDificultad = {
            baja = 0.5,    -- 50% menos probabilidad
            media = 1.0,   -- Probabilidad base
            alta = 1.5     -- 50% más probabilidad
        },
        porNivel = 0.02,   -- 2% menos por nivel del jugador
        porHambre = 0.001, -- 0.1% más por punto de hambre
        porSed = 0.001     -- 0.1% más por punto de sed
    },
    
    -- Resultados de falla
    resultadosFalla = {
        quemado = {
            probabilidad = 0.6,    -- 60% de quemarse
            itemResultado = 'comida_quemada',
            mensaje = '¡Se te quemó la comida!'
        },
        incomible = {
            probabilidad = 0.3,    -- 30% de ser incomible
            itemResultado = 'comida_incomible',
            mensaje = 'La comida quedó incomible...'
        },
        desastre = {
            probabilidad = 0.1,    -- 10% de desastre total
            itemResultado = nil,
            mensaje = '¡Desastre total! Perdiste todos los ingredientes.'
        }
    }
}

-- ====================================================================
-- 7. CONFIGURACIÓN DE ITEMS Y ETIQUETAS
-- ====================================================================
Config.Items = {
    -- Ingredientes básicos
    ['carne'] = { label = '🥩 Carne', tipo = 'ingrediente' },
    ['vegetales'] = { label = '🥕 Vegetales', tipo = 'ingrediente' },
    ['lechuga'] = { label = '🥬 Lechuga', tipo = 'ingrediente' },
    ['tomate'] = { label = '🍅 Tomate', tipo = 'ingrediente' },
    ['zanahoria'] = { label = '🥕 Zanahoria', tipo = 'ingrediente' },
    ['sal'] = { label = '🧂 Sal', tipo = 'ingrediente' },
    ['agua'] = { label = '💧 Agua', tipo = 'ingrediente' },
    ['aceite'] = { label = '🫒 Aceite', tipo = 'ingrediente' },
    ['harina'] = { label = '🌾 Harina', tipo = 'ingrediente' },
    ['chocolate'] = { label = '🍫 Chocolate', tipo = 'ingrediente' },
    ['huevo'] = { label = '🥚 Huevo', tipo = 'ingrediente' },
    ['azucar'] = { label = '🍚 Azúcar', tipo = 'ingrediente' },
    ['mantequilla'] = { label = '🧈 Mantequilla', tipo = 'ingrediente' },
    ['naranja'] = { label = '🍊 Naranja', tipo = 'ingrediente' },
    
    -- Platos terminados
    ['guisado_casero'] = { label = '🥘 Guisado Casero', tipo = 'comida' },
    ['ensalada_fresca'] = { label = '🥗 Ensalada Fresca', tipo = 'comida' },
    ['pastel_chocolate'] = { label = '🍰 Pastel de Chocolate', tipo = 'comida' },
    ['jugo_natural'] = { label = '🥤 Jugo Natural', tipo = 'bebida' },
    
    -- Resultados de falla
    ['comida_quemada'] = { label = '💀 Comida Quemada', tipo = 'basura' },
    ['comida_incomible'] = { label = '🤢 Comida Incomible', tipo = 'basura' }
}

-- ====================================================================
-- 8. CONFIGURACIÓN DE MENSAJES Y TEXTO
-- ====================================================================
Config.Mensajes = {
    -- Notificaciones de éxito
    cocina_exitosa = "🍳 ¡Has cocinado %s exitosamente!",
    experiencia_ganada = "⭐ +%d XP de cocina",
    dinero_ganado = "💰 Ganaste $%d",
    
    -- Notificaciones de error
    sin_ingredientes = "❌ No tienes los ingredientes necesarios",
    no_autorizado = "🚫 No tienes acceso a esta cocina",
    nivel_insuficiente = "📊 Nivel insuficiente. Requerido: %d",
    trabajo_incorrecto = "👨‍🍳 Trabajo incorrecto. Requerido: %s",
    cocina_ocupada = "⏳ Ya estás cocinando algo",
    
    -- Mensajes de falla
    comida_quemada = "🔥 ¡Se te quemó la comida!",
    comida_incomible = "🤢 La comida quedó incomible...",
    desastre_total = "💥 ¡Desastre total! Perdiste los ingredientes.",
    
    -- Interfaz
    presiona_para_cocinar = "Presiona ~INPUT_CONTEXT~ para cocinar",
    cocinando = "🍳 Cocinando %s...",
    cancelado = "⏹️ Cocina cancelada"
}

-- ====================================================================
-- 9. CONFIGURACIÓN DE SONIDOS
-- ====================================================================
Config.Sonidos = {
    activado = true,
    sonidos = {
        exito = {
            nombre = 'BASE_JUMP_PASSED',
            set = 'HUD_AWARDS'
        },
        falla = {
            nombre = 'Bed', 
            set = 'WastedSounds'
        },
        cocinando = {
            nombre = 'Timer',
            set = 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS'
        }
    }
}

-- ====================================================================
-- 10. VALIDACIONES Y SEGURIDAD
-- ====================================================================
Config.Validaciones = {
    tiempoMinimoCocina = 3000,      -- 3 segundos mínimo
    tiempoMaximoCocina = 60000,     -- 60 segundos máximo
    radioMaximoInteraccion = 3.0,   -- Radio máximo para interactuar
    maxRecetasSimultaneas = 1,      -- Máximo de recetas cocinando a la vez
    cooldownEntreCocinas = 5000     -- 5 segundos entre cocciones
}

-- ====================================================================
-- 11. CONFIGURACIÓN DE DEBUG
-- ====================================================================
Config.DebugOpciones = {
    mostrarZonas = false,           -- Mostrar zonas de cocina
    logProcesos = true,             -- Log de procesos en consola
    ignorarRequisitos = false,      -- Ignorar requisitos (solo debug)
    mostrarInfoRecetas = true       -- Mostrar info de recetas
}

print('^2[COCINA]^7 Configuración cargada - ' .. #Config.Cocinas .. ' cocinas, ' .. #Config.Recetas .. ' recetas')
