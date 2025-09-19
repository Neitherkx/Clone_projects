# 🚀 Odoo Setup Script

Este script automatiza la configuración inicial de proyectos Odoo a partir de un repositorio Git. Incluye validaciones, instalación de dependencias, inicialización de base de datos, hooks de desarrollo y soporte para Docker Compose.

## Características

- **Clona automáticamente el repositorio Odoo** desde una URL proporcionada por argumento o interactiva.
- **Verifica dependencias** como `git`, `pre-commit`, `invoke/inv`, y `docker/docker-compose`.
- **Instala hooks de pre-commit** (si está disponible).
- **Configura modo desarrollador** con `invoke`/`inv`.
- **Descarga addons** si hay `addons.yaml` y ejecuta agregación vía `git-aggregate`.
- **Inicializa y prepara la base de datos** con comandos personalizados.
- **Detecta y permite levantar el proyecto con Docker Compose**.
- **Mensajes claros y coloridos** para cada paso y error.

## Requisitos previos

- [Git](https://git-scm.com/) instalado.
- [pre-commit](https://pre-commit.com/) (opcional).
- [Invoke](https://www.pyinvoke.org/) o `inv` (opcional, recomendado para desarrolladores Odoo).
- [Docker](https://www.docker.com/) y [Docker Compose](https://docs.docker.com/compose/) (opcional para entorno dockerizado).
- Acceso a la URL del repositorio Odoo (SSH o HTTPS).

## Uso

```bash
curl -sSL https://raw.githubusercontent.com/Neitherkx/Clone_projects/main/setup_odoo.sh | bash -s <URL_DE_REPOSITORIO>
# o
bash odoo-setup.sh <URL_DE_REPOSITORIO>
```

Si no se indica la URL del repositorio como argumento, el script la pedirá de forma interactiva.

### Ejemplo de URLs válidas

- `git@github.com:usuario/repositorio.git`
- `https://github.com/usuario/repositorio.git`

## Proceso de configuración

1. **Clonación del repositorio:** Descarga el proyecto en una carpeta nueva.
2. **Instalación de hooks de pre-commit:** Para mantener la calidad del código.
3. **Modo desarrollador:** Configura el entorno como developer.
4. **Descarga de addons:** Si existe `addons.yaml` y los scripts están disponibles.
5. **Inicialización y preparación de la base de datos:** Automatización con comandos Odoo/invoke.
6. **Levantamiento con Docker:** Si detecta archivos de Docker Compose y tienes Docker instalado, te ofrece iniciar el entorno.

## Comandos útiles tras la configuración

```bash
cd <nombre_del_repositorio>
python3 odoo-bin --help        # Si existe odoo-bin
docker-compose up              # Si existe docker-compose.yml
docker-compose logs -f
docker-compose stop
```

## Preguntas frecuentes

- **¿Qué pasa si el directorio del repositorio ya existe?**  
  El script te preguntará si deseas eliminarlo y continuar.

- **¿No tengo Docker ni Invoke?**  
  El script continuará la configuración y te informará de las limitaciones.

- **¿Hay errores al clonar o instalar dependencias?**  
  El script muestra mensajes claros y detiene la ejecución si es necesario.

## Personalización

Puedes adaptar el script para añadir pasos específicos de tu flujo de trabajo Odoo, modificar comandos de base de datos, o agregar validaciones adicionales.

---

**¡Listo! Ya puedes comenzar a trabajar con tu proyecto Odoo 🚀**
