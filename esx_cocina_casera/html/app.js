// ====================================================================
// SISTEMA DE INTERFAZ - COCINA CASERA (VERSIÓN CORREGIDA)
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
    // 1. INICIALIZACIÓN MEJORADA
    // ====================================================================

    initialize() {
        console.log('🍳 Inicializando interfaz de Cocina Casera...');
        
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

                // NUEVO: Actualizar datos del jugador
                case 'updatePlayerData':
                    this.updatePlayerData(data.playerData);
                    break;
            }
        });
    }

    // ====================================================================
    // 2. SISTEMA DE EXPERIENCIA CORREGIDO
    // ====================================================================

    updateExperience(data) {
        this.playerData = { ...this.playerData, ...data };
        
        // Actualizar UI
        document.getElementById('current-level').textContent = this.playerData.level;
        document.getElementById('player-title').textContent = this.getTitleForLevel(this.playerData.level);
        
        // CORRECCIÓN: Usar nombres de propiedades consistentes
        const expActual = data.experience_actual || data.experience || 0;
        const expSiguiente = data.experiencia_siguiente_nivel || data.expRequired || 100;
        
        const expPercent = (expActual / expSiguiente) * 100;
        document.getElementById('exp-bar').style.width = expPercent + '%';
        document.getElementById('exp-text').textContent = 
            `${expActual}/${expSiguiente} XP`;
        
        // Efecto de nivel up
        if (data.levelUp) {
            this.playLevelUpAnimation();
        }
    }

    updatePlayerData(playerData) {
        // Actualizar datos generales del jugador
        if (playerData.experience) {
            this.updateExperience(playerData.experience);
        }
        if (playerData.stats) {
            this.updateStats(playerData.stats);
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
        
        this.showNotification(`🎉 ¡NIVEL ${this.playerData.level} ALCANZADO!`, 'success');
        
        setTimeout(() => {
            levelCircle.classList.remove('level-up');
        }, 2000);
    }

    // ====================================================================
    // 3. SISTEMA DE COCINA MEJORADO
    // ====================================================================

    showCookingMenu(recipesData) {
        this.recipes = recipesData;
        this.currentMenu = 'cooking';
        
        const menu = document.getElementById('cooking-menu');
        const recipesList = document.getElementById('recipes-list');
        
        menu.classList.remove('hidden');
        recipesList.innerHTML = this.generateRecipesList(recipesData);
        this.setupCategoryFilters();
    }

    generateRecipesList(recipes) {
        let html = '';
        
        for (const [recipeKey, recipe] of Object.entries(recipes)) {
            // CORRECCIÓN: Usar propiedades de tu config.lua
            const difficulty = recipe.dificultad || 'media';
            const difficultyClass = `difficulty-${difficulty}`;
            const isPro = recipe.trabajoRequerido !== null && recipe.trabajoRequerido !== undefined;
            const proClass = isPro ? 'pro' : '';
            const category = recipe.category || 'principal';
            
            html += `
                <div class="recipe-item ${proClass}" data-recipe="${recipeKey}" data-category="${category}">
                    <div class="recipe-header">
                        <div class="recipe-name">${recipe.label}</div>
                        <div class="recipe-difficulty ${difficultyClass}">
                            ${difficulty.toUpperCase()}
                        </div>
                    </div>
                    <div class="recipe-ingredients">
                        ${this.formatIngredients(recipe.ingredientes)}
                    </div>
                    <div class="recipe-time">
                        ⏱️ ${(recipe.tiempo || 10000) / 1000} segundos
                    </div>
                    ${isPro ? '<div class="recipe-badge">👨‍🍳 PRO</div>' : ''}
                </div>
            `;
        }
        
        return html;
    }

    formatIngredients(ingredients) {
        if (!ingredients) return 'Ingredientes no definidos';
        
        return ingredients.map(ing => {
            const cantidad = ing.cantidad || 1;
            const item = ing.item || 'ingrediente';
            return `${cantidad}x ${this.getItemLabel(item)}`;
        }).join(', ');
    }

    getItemLabel(itemName) {
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
                categoryBtns.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                this.filterRecipesByCategory(btn.dataset.category);
            });
        });
        
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
        if (!this.recipes[recipeKey]) {
            this.showNotification('❌ Receta no disponible', 'error');
            return;
        }

        // CORRECCIÓN: Usar el nombre correcto del recurso
        fetch(`https://esx_cocina_casera/startCooking`, {
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
                this.showNotification(data.error || '❌ Error al iniciar cocina', 'error');
            }
        }).catch(error => {
            this.showNotification('❌ Error de conexión', 'error');
            console.error('Error:', error);
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
            fetch(`https://esx_cocina_casera/getStats`, {
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
            this.renderSkillsList();
        } else {
            this.closeAllMenus();
        }
    }

    // ====================================================================
    // 6. SISTEMA DE NOTIFICACIONES Y PROGRESO
    // ====================================================================

    showNotification(message, type = 'info') {
        const container = document.getElementById('notifications-container');
        const notification = document.createElement('div');
        
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        container.appendChild(notification);
        
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 5000);
    }

    showProgressBar(text, duration) {
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
        }
        
        document.getElementById('progress-fill').style.width = '0%';
        progressContainer.querySelector('.progress-text').textContent = text;
        
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
    // 7. CONTROL DE MENÚS
    // ====================================================================

    toggleCookingMenu() {
        const menu = document.getElementById('cooking-menu');
        
        if (menu.classList.contains('hidden')) {
            this.closeAllMenus();
            menu.classList.remove('hidden');
            this.currentMenu = 'cooking';
            
            fetch(`https://esx_cocina_casera/getRecipes`, {
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
        
        fetch(`https://esx_cocina_casera/closeMenu`, {
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
    // 8. FUNCIONES AUXILIARES
    // ====================================================================

    showExperiencePanel() {
        document.getElementById('experience-panel').style.display = 'block';
    }

    hideExperiencePanel() {
        document.getElementById('experience-panel').style.display = 'none';
    }
}

// ====================================================================
// 9. INICIALIZACIÓN
// ====================================================================

document.addEventListener('DOMContentLoaded', () => {
    window.cocinaUI = new CocinaUI();
    console.log('🍳 Interfaz de Cocina Casera inicializada correctamente');
});

// Funciones globales para HTML
function closeCookingMenu() {
    if (window.cocinaUI) window.cocinaUI.closeCookingMenu();
}

function closeStats() {
    if (window.cocinaUI) window.cocinaUI.closeStats();
}

function closeSkillsMenu() {
    if (window.cocinaUI) window.cocinaUI.closeSkillsMenu();
}

window.CocinaUI = CocinaUI;