---
name: sprint-planning
description: "Comanda /sprint-planning <capacitat en hores>: proposa les històries i tasques d'un sprint segons la prioritat del backlog i la capacitat de l'equip."
disable-model-invocation: true
metadata:
  repos: both
---

# /sprint-planning

Entrades (demana les que faltin): capacitat de l'equip en hores (o hores per persona), històries prioritzades a
Taiga (ordre), històries arrossegades de l'sprint anterior i dependències amb Talaia i Mobilicat.

1. Llegeix `docs/ai/10-requisits.md` (SP; 1 SP ≈ 2 h) i `docs/ai/estat.md`.
2. Omple la capacitat seguint l'ordre del backlog, deixant un **20 % de marge** per a revisions, bugs i
   documentació. No partiu una història entre sprints; si no hi cap, proposa partir-la en històries més petites.
3. Comprova les dependències: el frontend d'una història sense endpoint ha d'anar amb el seu backend al
   mateix sprint, o bé amb un repositori de demostració indicat explícitament.
4. Per a cada història escollida, descompon-la en tasques amb hores (frontend i backend), com a la skill
   `nova-historia-usuari` § 4.
5. Reparteix-les per perfil (frontend o backend) sense assignar noms si no t'ho demanen.

Sortida:

```
Capacitat: X h · Planificat: Y h (Z SP) · Marge: W h
| Història | SP | Tasques (h) | Dependències |
Riscos: …
Recordatori: enviar la planificació al professor avui.
```

Al final, actualitza «Sprint» i «Propers passos» a `docs/ai/estat.md`.
