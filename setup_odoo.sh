#!/bin/bash

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con colores
print_step() {
    echo -e "${BLUE}$1${NC} $2"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
    exit 1
}

# Función mejorada para leer entrada del usuario que funciona con curl | bash
read_input() {
    local prompt="$1"
    local result
    
    # Intentar múltiples métodos para leer entrada interactiva
    if [ -c /dev/tty ]; then
        # Método 1: usar /dev/tty directamente
        printf "%s" "$prompt" >&2
        read result < /dev/tty
    elif [ -t 0 ]; then
        # Método 2: stdin es un terminal
        printf "%s" "$prompt" >&2
        read result
    else
        # Método 3: forzar lectura desde terminal
        exec < /dev/tty
        printf "%s" "$prompt" >&2
        read result
    fi
    
    echo "$result"
}

# Banner del script
echo -e "${BLUE}"
echo "🚀 ODOO SETUP SCRIPT - Configuración automática"
echo -e "${NC}"

# Obtener URL del repositorio
REPO_URL="$1"

# Si no se proporciona URL como argumento, pedirla interactivamente
if [[ -z "$REPO_URL" ]]; then
    echo ""
    echo -e "${YELLOW}🔗 Introduce la URL del repositorio de Odoo:${NC}"
    echo -e "${YELLOW}   Ejemplos:${NC}"
    echo -e "${YELLOW}   - git@github.com:usuario/repositorio.git${NC}"
    echo -e "${YELLOW}   - https://github.com/usuario/repositorio.git${NC}"
    echo ""
    
    REPO_URL=$(read_input "URL: ")
    
    # Verificar que se introdujo una URL
    if [[ -z "$REPO_URL" ]]; then
        print_error "No se proporcionó ninguna URL del repositorio"
    fi
fi

# Extraer el nombre del repositorio de la URL
REPO=$(basename "$REPO_URL" .git)

# Validar que se extrajo correctamente el nombre
if [[ -z "$REPO" ]]; then
    print_error "No se pudo extraer el nombre del repositorio de la URL: $REPO_URL"
fi

echo ""
print_step "🎯" "Repositorio: $REPO"
print_step "🔗" "URL: $REPO_URL"
echo ""

# Verificar si el directorio ya existe
if [[ -d "$REPO" ]]; then
    echo -e "${YELLOW}⚠️  El directorio '$REPO' ya existe.${NC}"
    
    # Preguntar si eliminar el directorio existente
    confirm=$(read_input "¿Deseas eliminarlo y continuar? (y/N): ")
    if [[ $confirm =~ ^[Yy]$ ]]; then
        print_step "🗑️" "Eliminando directorio existente..."
        rm -rf "$REPO"
    else
        print_error "Operación cancelada por el usuario"
    fi
fi

# Verificar que git está disponible
if ! command -v git &> /dev/null; then
    print_error "Git no está instalado. Por favor, instala Git antes de continuar."
fi

# Clonar el repositorio
print_step "📥" "Clonando repositorio..."
if git clone "$REPO_URL"; then
    print_success "Repositorio clonado exitosamente"
else
    print_error "Error al clonar el repositorio. Verifica la URL y tu conexión."
fi

cd "$REPO" || print_error "No se pudo acceder al directorio del proyecto"

echo ""
print_step "📂" "Directorio actual: $(pwd)"

# Verificar dependencias y mostrar advertencias si no están disponibles
check_and_warn() {
    if ! command -v "$1" &> /dev/null; then
        print_step "⚠️" "$1 no está disponible, saltando $2..."
        return 1
    fi
    return 0
}

# Instalar pre-commit (si está disponible)
if check_and_warn "pre-commit" "instalación de hooks"; then
    print_step "⚙️" "Instalando pre-commit hooks..."
    if pre-commit install -f; then
        print_success "Pre-commit hooks instalados"
    else
        print_step "⚠️" "No se pudo instalar pre-commit hooks"
    fi
fi

# Establecer modo desarrollador (si invoke está disponible)
if command -v inv &> /dev/null; then
    INV_CMD="inv"
elif command -v invoke &> /dev/null; then
    INV_CMD="invoke"
else
    INV_CMD=""
fi

if [[ -n "$INV_CMD" ]]; then
    print_step "🔧" "Estableciendo modo desarrollador..."
    if $INV_CMD develop; then
        print_success "Modo desarrollador establecido"
    else
        print_step "⚠️" "No se pudo establecer modo desarrollador"
    fi
    
    # Descargar los addons
    print_step "📦" "Descargando addons declarados en addons.yaml..."
    if $INV_CMD git-aggregate; then
        print_success "Addons descargados"
    else
        print_step "⚠️" "No se pudieron descargar los addons"
    fi
    
    # Inicializar la base de datos
    print_step "🗃️" "Inicializando la base de datos..."
    if $INV_CMD install -pe; then
        print_success "Base de datos inicializada"
    else
        print_step "⚠️" "No se pudo inicializar la base de datos"
    fi
    
    # Preparar la base de datos
    print_step "🧪" "Preparando la base de datos..."
    if $INV_CMD preparedb; then
        print_success "Base de datos preparada"
    else
        print_step "⚠️" "No se pudo preparar la base de datos"
    fi
else
    print_step "⚠️" "invoke no está disponible, saltando configuración avanzada..."
fi

echo ""

# Verificar si Docker está disponible y preguntar si iniciar
if command -v docker &> /dev/null && (command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1); then
    if [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]; then
        print_step "🐳" "Docker Compose detectado"
        
        # Preguntar si levantar el proyecto con Docker
        start_docker=$(read_input "¿Deseas levantar el proyecto con Docker ahora? (Y/n): ")
        if [[ ! $start_docker =~ ^[Nn]$ ]]; then
            print_step "🚀" "Levantando el proyecto con Docker..."
            
            # Usar docker compose si está disponible, si no docker-compose
            if docker compose version &> /dev/null 2>&1; then
                docker compose up
            else
                docker-compose up
            fi
        else
            echo ""
            print_step "ℹ️" "Para levantar el proyecto más tarde, ejecuta:"
            echo "   cd $REPO"
            echo "   docker-compose up"
        fi
    else
        print_step "ℹ️" "No se encontró docker-compose.yml"
    fi
else
    print_step "⚠️" "Docker o Docker Compose no están disponibles"
    print_step "ℹ️" "El proyecto se ha configurado, pero no se puede levantar automáticamente"
fi

echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    ✅ CONFIGURACIÓN COMPLETA                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

print_success "Proyecto '$REPO' configurado exitosamente"
print_step "📂" "Ubicación: $(pwd)"
print_step "🚀" "¡Ya puedes comenzar a trabajar con tu proyecto Odoo!"

echo ""
echo -e "${BLUE}📚 Comandos útiles:${NC}"
echo "   cd $REPO"
if [[ -f "odoo-bin" ]]; then
    echo "   python3 odoo-bin --help"
fi
if [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]; then
    echo "   docker-compose up"
    echo "   docker-compose logs -f"
    echo "   docker-compose stop"
fi
echo ""
