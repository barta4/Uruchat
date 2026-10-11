# =============================================================================
# Uruchat - Imagen Docker basada en Chatwoot v4.18.0 con branding Uruchat
# =============================================================================
#
# Este archivo es un puntero al Dockerfile oficial de Chatwoot (multi-stage).
# El branding Uruchat ya está integrado en el codigo fuente del repo, asi que
# NO se necesita ningun COPY adicional: la imagen se construye desde source.
#
# El Dockerfile oficial real esta en: docker/Dockerfile
#
# -----------------------------------------------------------------------------
# COMO CONSTRUIR Y SUBIR LA IMAGEN A DOCKER HUB
# -----------------------------------------------------------------------------
#
# 1) Login en Docker Hub (una sola vez):
#      docker login -u alfredobartaburu
#
# 2) Construir la imagen (desde la raiz del repo):
#      docker build -f docker/Dockerfile -t alfredobartaburu/uruchat:v4.18.0 .
#
#    Notas:
#      - Primer build: ~15-30 min (compila gems de Ruby y assets de Vite).
#      - Builds siguientes: ~2-5 min (Docker cachea capas).
#      - Necesita ~4GB de RAM libres durante el build.
#
# 3) (Opcional) Probar la imagen localmente antes de subir:
#      docker run --rm -p 3000:3000 alfredobartaburu/uruchat:v4.18.0
#
# 4) Subir a Docker Hub:
#      docker push alfredobartaburu/uruchat:v4.18.0
#
#    Tip: tambien sube un tag "latest":
#      docker tag alfredobartaburu/uruchat:v4.18.0 alfredobartaburu/uruchat:latest
#      docker push alfredobartaburu/uruchat:latest
#
# 5) En produccion, actualiza docker-compose.production.yaml con el nuevo tag
#    y haz:
#      docker compose -f docker-compose.production.yaml pull
#      docker compose -f docker-compose.production.yaml up -d
#
# -----------------------------------------------------------------------------
# POR QUE ESTE DOCKERFILE ES SOLO DOCUMENTACION
# -----------------------------------------------------------------------------
# Docker no permite que un archivo "wrapper" llame a otro Dockerfile directamente.
# El flag -f del comando build es lo que selecciona el Dockerfile a usar.
# Por eso la instruccion correcta es:
#
#   docker build -f docker/Dockerfile ...
#
# y no:
#
#   docker build .            # <-- usaria ESTE archivo, que no tiene stages
#
# =============================================================================

# Sin FROM real: este archivo solo documenta el flujo.
# Para construir, usa: docker build -f docker/Dockerfile -t alfredobartaburu/uruchat:v4.18.0 .
