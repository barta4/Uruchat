# Uruchat: Permisos por agente (Custom Roles)

Sistema de permisos granulares por agente, **implementación 100% OSS** (commit `9590286c1f`).
No usa ni copia código de `enterprise/` (licencia comercial de Chatwoot); está construido
desde cero sobre el esquema y el frontend que Chatwoot ya publica como MIT.

## Cómo funciona

- Cada cuenta puede definir **Custom Roles** con un subconjunto de permisos.
- A cada agente se le asigna un rol custom (además de su rol base `agent`).
- Un agente con rol custom **deja de usar el acceso por inbox/team** y pasa a estar
  gobernado **exclusivamente** por los permisos de su rol.
- Los agentes sin rol custom y los administradores mantienen el comportamiento estándar.

## Permisos disponibles

| Permiso | Qué habilita |
|---|---|
| `conversation_manage` | Ver y gestionar **todas** las conversaciones |
| `conversation_unassigned_manage` | Gestionar conversaciones sin asignar (y asignárselas) |
| `conversation_participating_manage` | Gestionar conversaciones donde es participante |
| `contact_manage` | Sección Contactos completa |
| `report_manage` | Reportes y CSAT |
| `knowledge_base_manage` | Help Center (portales, artículos, categorías) |

Reglas de visibilidad de conversaciones (policy y lista van siempre alineadas):

- Con `conversation_manage`: todas.
- Con cualquiera de los tres permisos de conversación: siempre ve las **asignadas a él**.
- Con `conversation_unassigned_manage`: además las **sin asignar**.
- Con `conversation_participating_manage`: además las donde es **participante**.
- Sin ningún permiso de conversación: **ninguna**.

## Uso desde la UI

1. Como administrador: **Configuración → Custom Roles** → crear rol (nombre + permisos).
2. **Configuración → Agentes** → editar agente → asignar el rol custom (o quitarlo con el rol estándar).

El feature flag de cuenta `custom_roles` está habilitado por defecto (`config/features.yml`).

## API

Rutas account-scoped (administradores únicamente):

```
GET    /api/v1/accounts/:account_id/custom_roles
POST   /api/v1/accounts/:account_id/custom_roles   { custom_role: { name:, description:, permissions: [] } }
GET    /api/v1/accounts/:account_id/custom_roles/:id
PUT    /api/v1/accounts/:account_id/custom_roles/:id
DELETE /api/v1/accounts/:account_id/custom_roles/:id
```

Asignación a agentes:

```
POST /api/v1/accounts/:account_id/agents   { agent: { email:, name:, custom_role_id: <id> } }
PUT  /api/v1/accounts/:account_id/agents/:id { agent: { custom_role_id: <id | null> } }
```

`custom_role_id: null` desasigna el rol y devuelve al agente al acceso estándar por inbox.

## Implementación (mapa de archivos)

| Capa | Archivo |
|---|---|
| Modelo | `app/models/custom_role.rb` (valida permisos conocidos, invalida unread counts al cambiar) |
| Asociación/permisos | `app/models/account_user.rb` → `belongs_to :custom_role` + `#permissions` |
| Helper de policies | `app/policies/application_policy.rb` → `custom_role_member?` / `has_permission?` |
| Policies | `conversation_policy.rb`, `contact_policy.rb`, `report_policy.rb`, `csat_survey_response_policy.rb`, `portal_policy.rb`, `article_policy.rb`, `category_policy.rb` |
| CRUD policy | `app/policies/custom_role_policy.rb` (solo administradores) |
| Controller | `app/controllers/api/v1/accounts/custom_roles_controller.rb` |
| Visibilidad de listas | `app/services/conversations/permission_filter_service.rb` |
| Agents API | `app/controllers/api/v1/accounts/agents_controller.rb`, `app/builders/agent_builder.rb` |
| Serialización | `app/views/api/v1/models/_user.json.jbuilder`, `_agent.json.jbuilder`, `_custom_role.json.jbuilder` |
| Frontend (preexistente MIT) | `routes/dashboard/settings/customRoles/`, `store/modules/customRole.js`, `constants/permissions.js` |
| Feature flag | `config/features.yml` (`custom_roles: enabled: true`), ruta habilitada para community |

## Specs

- `spec/models/custom_role_spec.rb` — validaciones y nullify al destruir
- `spec/policies/custom_role_permissions_spec.rb` — semantics de todas las policies
- `spec/controllers/api/v1/accounts/custom_roles_controller_spec.rb` — CRUD + autorización
- `spec/services/conversations/permission_filter_service_spec.rb` — scoping de visibilidad

## Notas operativas

- Requiere `DISABLE_ENTERPRISE=true` en el `.env` de producción (Uruchat corre como
  community puro; con enterprise activo los prepends de EE toman precedencia).
- La tabla `custom_roles` y la columna `account_users.custom_role_id` existen desde la
  migración `20240726220747_add_custom_roles.rb` (OSS) — no se necesita migración nueva.
- Al cambiar permisos de un rol, los unread counts filtrados de los miembros se
  invalidan automáticamente (callbacks del modelo).
- Mantener la alineación semántica entre `ConversationPolicy#custom_role_conversation_access?`
  y `PermissionFilterService#custom_role_conversations`: la policy (registro individual) y el
  servicio (listas) deben denegar/permitir lo mismo.
