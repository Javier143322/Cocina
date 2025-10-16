// ====================================================================
// SISTEMA DE INTERFAZ - COCINA CASERA
// ====================================================================

class CocinaUI {
    constructor() {
        this.currentMenu = null;
        this.playerData = {
            level: 1,
            experience: 0,
            expRequired: 100,
            title: "🍳 Aprendiz"
        };
        this.recipes = {};
        this.stats = {};
        this.skills = {};
        
        this.initialize();
    }

    // ====================================================================
    // 1. INICIALIZACIÓN DEL SISTEMA
    // ====================================================================

    initialize() {
        console.log('🍳 Inicializando interfaz de Cocina Casera...');
        
        // Cargar datos iniciales
        this.loadPlayerData();
        
        // Configurar event listeners
        this.setupEventListeners();
        
        // Configurar comunicación NUI
        this.setupNUICommunication();
        
        // Mostrar panel de experiencia
        this.showExperiencePanel();
    }

    setupEventListeners() {
        // Teclas para abrir menús
        document.addEventListener('keydown', (e) => {
            switch(e.keyCode) {
                case 27: // ESC - Cerrar menús
                    this.closeAllMenus();
                    break;
                case 73: // I - Menú de cocina
                    this.toggleCookingMenu();
                    break;
                case 79: // O - Estadísticas
                    this.toggleStatsPanel();
                    break;
                case 80: // P - Habilidades
                    this.toggleSkillsMenu();
                    break;
            }
        });
    }

    setupNUICommunication() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            switch(data.action) {
                case 'updateExperience':
                    this.updateExperience(data.data);
                    break;
                    
                case 'showCookingMenu':
                    this.showCookingMenu(data.recipes);
                    break;
                    
                case 'updateStats':
                    this.updateStats(data.stats);
                    break;
                    
                case 'updateSkills':
                    this.updateSkills(data.skills);
                    break;
                    
                case 'showNotification':
                    this.showNotification(data.message, data.type);
                    break;
                    
                case 'showProgressBar':
                    this.showProgressBar(data.text, data.duration);
                    break;
                    
                case 'hideProgressBar':
                    this.hideProgressBar();
                    break;
                    
                case 'closeAllMenus':
                    this.closeAllMenus();
                    break;
            }
        });
    }

    // ====================================================================
    // 2. SISTEMA DE EXPERIENCIA Y NIVELES
    // ====================================================================

    updateExperience(data) {
        this.playerData = { ...this.playerData, ...data };
        
        // Actualizar UI
        document.getElementById('current-level').textContent = this.playerData.level;
        document.getElementById('player-title').textContent = this.getTitleForLevel(this.playerData.level);
        
        // Calcular porcentaje de experiencia
        const expPercent = (this.playerData.experience_actual / this.playerData.experiencia_siguiente_nivel) * 100;
        document.getElementById('exp-bar').style.width = expPercent + '%';
        document.getElementById('exp-text').textContent = 
            `${this.playerData.experience_actual}/${this.playerData.experiencia_siguiente_nivel} XP`;
        
        // Efecto de nivel up
        if (data.levelUp) {
            this.playLevelUpAnimation();
        }
    }

    getTitleForLevel(level) {
        const titles = {
            1: "🍳 Aprendiz",
            2: "👨‍🍳 Cocinitas", 
            5: "🔪 Chef Junior",
            10: "🥘 Chef",
            20: "👨‍🍳 Chef Senior",
            30: "🎖️ Maestro Chef",
            50: "🌟 Chef Leyenda",
            100: "👑 Dios de la Cocina"
        };
        
        // Encontrar el título más alto para el nivel actual
        let highestTitle = "🍳 Aprendiz";
        for (const [lvl, title] of Object.entries(titles)) {
            if (level >= parseInt(lvl)) {
                highestTitle = title;
            }
        }
        
        return highestTitle;
    }

    playLevelUpAnimation() {
        const levelCircle = document.querySelector('.level-circle');
        levelCircle.classList.add('level-up');
        
        // Mostrar notificación especial
        this.showNotification(`🎉 ¡NIVEL ${this.playerData.level} ALCANZADO!`, 'success');
        
        setTimeout(() => {
            levelCircle.classList.remove('level-up');
        }, 2000);
    }

    // ====================================================================
    // 3. SISTEMA DE MENÚ DE COCINA
    // ====================================================================

    showCookingMenu(recipesData) {
        this.recipes = recipesData;
        this.currentMenu = 'cooking';
        
        const menu = document.getElementById('cooking-menu');
        const recipesList = document.getElementById('recipes-list');
        
        // Mostrar menú
        menu.classList.remove('hidden');
        
        // Generar lista de recetas
        recipesList.innerHTML = this.generateRecipesList(recipesData);
        
        // Configurar filtros de categoría
        this.setupCategoryFilters();
    }

    generateRecipesList(recipes) {
        let html = '';
        
        for (const [recipeKey, recipe] of Object.entries(recipes)) {
            const difficultyClass = `difficulty-${recipe.dificultad}`;
            const isPro = recipe.trabajoRequerido !== null;
            const proClass = isPro ? 'pro' : '';
            
            html += `
                <div class="recipe-item ${proClass}" data-recipe="${recipeKey}" data-category="${recipe.category}">
                    <div class="recipe-header">
                        <div class="recipe-name">${recipe.label}</div>
                        <div class="recipe-difficulty ${difficultyClass}">
                            ${recipe.dificultad.toUpperCase()}
                        </div>
                    </div>
                    <div class="recipe-ingredients">
                        ${this.formatIngredients(recipe.ingredientes)}
                    </div>
                    <div class="recipe-time">
                        ⏱️ ${recipe.tiempo / 1000} segundos
                    </div>
                    ${isPro ? '<div class="recipe-badge">👨‍🍳 PRO</div>' : ''}
                </div>
            `;
        }
        
        return html;
    }

    formatIngredients(ingredients) {
        return ingredients.map(ing => 
            `${ing.cantidad}x ${this.getItemLabel(ing.item)}`
        ).join(', ');
    }

    getItemLabel(itemName) {
        // Aquí integrarías con la configuración de items
        const itemLabels = {
            'carne': '🥩 Carne',
            'vegetales': '🥕 Vegetales', 
            'lechuga': '🥬 Lechuga',
            'tomate': '🍅 Tomate',
            'zanahoria': '🥕 Zanahoria',
            'sal': '🧂 Sal',
            'agua': '💧 Agua',
            'aceite': '🫒 Aceite',
            'harina': '🌾 Harina',
            'chocolate': '🍫 Chocolate',
            'huevo': '🥚 Huevo',
            'azucar': '🍚 Azúcar',
            'mantequilla': '🧈 Mantequilla',
            'naranja': '🍊 Naranja'
        };
        
        return itemLabels[itemName] || itemName;
    }

    setupCategoryFilters() {
        const categoryBtns = document.querySelectorAll('.category-btn');
        
        categoryBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                // Remover activo de todos los botones
                categoryBtns.forEach(b => b.classList.remove('active'));
                // Activar botón clickeado
                btn.classList.add('active');
                
                // Filtrar recetas
                this.filterRecipesByCategory(btn.dataset.category);
            });
        });
        
        // Configurar click en recetas
        document.querySelectorAll('.recipe-item').forEach(item => {
            item.addEventListener('click', () => {
                this.selectRecipe(item.dataset.recipe);
            });
        });
    }

    filterRecipesByCategory(category) {
        const recipes = document.querySelectorAll('.recipe-item');
        
        recipes.forEach(recipe => {
            if (category === 'all' || recipe.dataset.category === category) {
                recipe.style.display = 'block';
            } else {
                recipe.style.display = 'none';
            }
        });
    }

    selectRecipe(recipeKey) {
        // Enviar al cliente de FiveM para iniciar cocina
        fetch(`https://${GetParentResourceName()}/startCooking`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                recipe: recipeKey
            })
        }).then(resp => resp.json()).then(data => {
            if (data.success) {
                this.closeAllMenus();
                this.showNotification(`🍳 Iniciando cocina: ${this.recipes[recipeKey].label}`, 'success');
            } else {
                this.showNotification(data.error || 'Error al iniciar cocina', 'error');
            }
        });
    }

    // ====================================================================
    // 4. SISTEMA DE ESTADÍSTICAS
    // ====================================================================

    updateStats(statsData) {
        this.stats = statsData;
        
        document.getElementById('stat-recipes').textContent = statsData.total_recetas_cocinadas || 0;
        document.getElementById('stat-success').textContent = 
            `${Math.round(statsData.porcentaje_exito || 0)}%`;
        document.getElementById('stat-level').textContent = statsData.nivel_chef || 1;
        document.getElementById('stat-ranking').textContent = `#${statsData.ranking || 1}`;
    }

    toggleStatsPanel() {
        const panel = document.getElementById('stats-panel');
        
        if (panel.classList.contains('hidden')) {
            this.closeAllMenus();
            panel.classList.remove('hidden');
            this.currentMenu = 'stats';
            
            // Solicitar datos actualizados
            fetch(`https://${GetParentResourceName()}/getStats`, {
                method: 'POST'
            });
        } else {
            this.closeAllMenus();
        }
    }

    // ====================================================================
    // 5. SISTEMA DE HABILIDADES
    // ====================================================================

    updateSkills(skillsData) {
        this.skills = skillsData;
        this.renderSkillsList();
    }

    renderSkillsList() {
        const skillsContent = document.getElementById('skills-content');
        
        if (!skillsContent) return;
        
        const skills = [
            { id: 'cortes_rapidos', name: 'Cortes Rápidos', desc: 'Tiempo de cocina -10%', level: 5, unlocked: false },
            { id: 'manos_limpias', name: 'Manos Limpias', desc: 'Probabilidad de falla -15%', level: 10, unlocked: false },
            { id: 'sazonador', name: 'Sazonador', desc: 'XP ganada +20%', level: 15, unlocked: false },
            { id: 'eficiencia', name: 'Eficiencia', desc: 'Ingredientes -1 en recetas', level: 20, unlocked: false },
            { id: 'maestro_fogones', name: 'Maestro Fogones', desc: 'Puedes cocinar 2 recetas simultáneas', level: 25, unlocked: false },
            { id: 'paladar_experto', name: 'Paladar Experto', desc: 'Efectos de comida +25%', level: 30, unlocked: false }
        ];
        
        let html = '';
        
        skills.forEach(skill => {
            const isUnlocked = this.playerData.level >= skill.level;
            const unlockedClass = isUnlocked ? 'unlocked' : '';
            const status = isUnlocked ? '🔓 DESBLOQUEADA' : `🔒 Nivel ${skill.level}`;
            
            html += `
                <div class="skill-item ${unlockedClass}">
                    <div class="skill-header">
                        <div class="skill-name">${skill.name}</div>
                        <div class="skill-level">${status}</div>
                    </div>
                    <div class="skill-desc">${skill.desc}</div>
                    <div class="skill-progress">
                        <div class="skill-progress-bar" style="width: ${isUnlocked ? '100' : '0'}%"></div>
                    </div>
                </div>
            `;
        });
        
        skillsContent.innerHTML = html;
    }

    toggleSkillsMenu() {
        const menu = document.getElementById('skills-menu');
        
        if (menu.classList.contains('hidden')) {
            this.closeAllMenus();
            menu.classList.remove('hidden');
            this.currentMenu = 'skills';
            
            // Actualizar lista de habilidades
            this.renderSkillsList();
        } else {
            this.closeAllMenus();
        }
    }

    // ====================================================================
    // 6. SISTEMA DE NOTIFICACIONES
    // ====================================================================

    showNotification(message, type = 'info') {
        const container = document.getElementById('notifications-container');
        const notification = document.createElement('div');
        
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        container.appendChild(notification);
        
        // Auto-remover después de 5 segundos
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 5000);
    }

    // ====================================================================
    // 7. SISTEMA DE BARRAS DE PROGRESO
    // ====================================================================

    showProgressBar(text, duration) {
        // Crear barra de progreso si no existe
        let progressContainer = document.getElementById('progress-container');
        
        if (!progressContainer) {
            progressContainer = document.createElement('div');
            progressContainer.id = 'progress-container';
            progressContainer.className = 'progress-container';
            progressContainer.innerHTML = `
                <div class="progress-text">${text}</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="progress-fill"></div>
                </div>
            `;
            document.body.appendChild(progressContainer);
        } else {
            document.getElementById('progress-fill').style.width = '0%';
            progressContainer.querySelector('.progress-text').textContent = text;
        }
        
        // Animar barra de progreso
        let startTime = Date.now();
        const animateProgress = () => {
            const elapsed = Date.now() - startTime;
            const progress = Math.min((elapsed / duration) * 100, 100);
            
            document.getElementById('progress-fill').style.width = progress + '%';
            
            if (progress < 100) {
                requestAnimationFrame(animateProgress);
            }
        };
        
        animateProgress();
    }

    hideProgressBar() {
        const progressContainer = document.getElementById('progress-container');
        if (progressContainer) {
            progressContainer.remove();
        }
    }

    // ====================================================================
    // 8. CONTROL DE MENÚS
    // ====================================================================

    toggleCookingMenu() {
        const menu = document.getElementById('cooking-menu');
        
        if (menu.classList.contains('hidden')) {
            this.closeAllMenus();
            menu.classList.remove('hidden');
            this.currentMenu = 'cooking';
            
            // Solicitar recetas al servidor
            fetch(`https://${GetParentResourceName()}/getRecipes`, {
                method: 'POST'
            });
        } else {
            this.closeAllMenus();
        }
    }

    closeAllMenus() {
        document.querySelectorAll('.menu, .panel').forEach(element => {
            if (!element.id.includes('experience-panel')) {
                element.classList.add('hidden');
            }
        });
        this.currentMenu = null;
        
        // Enviar al juego que se cerraron los menús
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST'
        });
    }

    closeCookingMenu() {
        document.getElementById('cooking-menu').classList.add('hidden');
        this.currentMenu = null;
    }

    closeStats() {
        document.getElementById('stats-panel').classList.add('hidden');
        this.currentMenu = null;
    }

    closeSkillsMenu() {
        document.getElementById('skills-menu').classList.add('hidden');
        this.currentMenu = null;
    }

    // ====================================================================
    // 9. FUNCIONES AUXILIARES
    // ====================================================================

    loadPlayerData() {
        // Cargar datos iniciales del jugador
        fetch(`https://${GetParentResourceName()}/getPlayerData`, {
            method: 'POST'
        }).then(resp => resp.json()).then(data => {
            if (data.experience) {
                this.updateExperience(data.experience);
            }
            if (data.stats) {
                this.updateStats(data.stats);
            }
        });
    }

    showExperiencePanel() {
        document.getElementById('experience-panel').style.display = 'block';
    }

    hideExperiencePanel() {
        document.getElementById('experience-panel').style.display = 'none';
    }
}

// ====================================================================
// 10. INICIALIZACIÓN DE LA APLICACIÓN
// ====================================================================

// Esperar a que el DOM esté listo
document.addEventListener('DOMContentLoaded', () => {
    window.cocinaUI = new CocinaUI();
    console.log('🍳 Interfaz de Cocina Casera inicializada correctamente');
});

// Funciones globales para llamadas desde HTML
function closeCookingMenu() {
    if (window.cocinaUI) {
        window.cocinaUI.closeCookingMenu();
    }
}

function closeStats() {
    if (window.cocinaUI) {
        window.cocinaUI.closeStats();
    }
}

function closeSkillsMenu() {
    if (window.cocinaUI) {
        window.cocinaUI.closeSkillsMenu();
    }
}

// Exportar para uso global
window.CocinaUI = CocinaUI;
