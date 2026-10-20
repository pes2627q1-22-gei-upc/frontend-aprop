# ADR-0001 · Construir el backend en Go amb `net/http`, sense framework

- **Estat:** acceptada
- **Data:** 2026-10-02 (Incepció 2) · **Autoria:** FiveGuys

## Context

L'API REST és el punt d'entrada únic de l'app, de la web d'administració i dels equips PES. Ha de gestionar
moltes peticions simultànies (xats i notificacions), respondre en < 0,5 s, desplegar-se fàcilment en un
contenidor i minimitzar la superfície d'atac (NFR d'immunitat, `60-metodologia-i-qualitat.md`).

## Decisió

Backend en Go 1.25 amb la llibreria estàndard `net/http` (`http.ServeMux` amb patrons `MÈTODE /ruta/{param}`).
Sense framework web. Dependències externes només quan siguin imprescindibles i s'hagin revisat amb `govulncheck`.

## Alternatives considerades

- **Frameworks Go (Gin, Echo, Fiber…):** més dependències i més superfície d'atac, i des de Go 1.22 el `ServeMux`
  ja ofereix enrutament per mètode i paràmetres.
- **Altres llenguatges:** no s'hi detallen; Go s'escull per ser compilat, tenir concurrència nativa i generar un binari únic i lleuger.

## Conseqüències

- (+) Control total de les rutes, pocs mòduls a auditar, imatge Docker petita.
- (−) Middleware, validació i serialització d'errors es fan a mà. Mitigació: un paquet `handlers/response`
  comú i la skill `endpoint-go`.
- Nota: `go.mod` declara `go 1.25.11` (la memòria diu 1.25.5) i depèn de `github.com/joho/godotenv`.
