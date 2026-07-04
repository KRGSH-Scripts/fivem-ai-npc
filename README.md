# AI Peds - FiveM Resource

AI Peds ist eine FiveM-Resource für autonome, KI-gestützte NPCs. Die Peds erhalten Namen, Persönlichkeiten, zufällige FreeRoam-Outfits, eigene Zustände, Beziehungen untereinander und können sprechen, arbeiten, wandern, sozial interagieren und optional per OpenRouter/LLM Entscheidungen oder Chat-Antworten erzeugen.

## Features

- **Autonome NPCs**
  - Automatisches Spawnen beim Resource-Start
  - Regelmäßige Zustands-Auswertung alle 30 Sekunden
  - Zustände wie `idle`, `wandering`, `working`, `social`, `following` und `sleep`

- **Dynamische FreeRoam-Peds**
  - Nutzt `mp_m_freemode_01` und `mp_f_freemode_01`
  - Zufälliges Geschlecht
  - Zufällige Kleidung/Komponenten über `Config.OutfitComponents`
  - Individuelle Namen und Persönlichkeiten

- **KI-Personas**
  - Namen aus konfigurierbaren Vor- und Nachnamen
  - Zufällige Persönlichkeitsprofile
  - Optional vorbereitete OpenRouter-Anbindung für KI-generierte Persönlichkeit/Antworten

- **Verhaltenssystem**
  - Wandern mit zufälligen Warte- und Laufzeiten
  - Arbeitszeiten und Arbeitsorte
  - Soziale Interaktionen mit nahegelegenen NPCs
  - Fallback-Entscheidungen ohne aktive externe KI

- **Chat- und Interaktionssystem**
  - Sichtbare Chat-Nachrichten über NPCs
  - Begrüßungen und Smalltalk aus der Config
  - Optional KI-generierte Chat-Antworten
  - Spieler können Peds über `qb-target` ansprechen oder folgen lassen

- **Beziehungssystem**
  - Beziehung zwischen NPCs mit:
    - Sympathie
    - Vertrauen
    - Respekt
    - Bekanntheit
    - Relation: `neutral`, `friend`, `enemy`
  - Werte werden nach Interaktionen angepasst und gespeichert

- **Persistente Datenbankdaten**
  - Automatische Tabellenerstellung bei laufendem `oxmysql`
  - Speichert Personas, Outfits, Beziehungen, Interaktionen und Statistiken

- **NPC Tool-System für KI/Entwickler**
  - Tools wie `speak`, `moveTo`, `workAt`, `interact`, `setState`, `scanEnvironment`, `remember`
  - Eigene Tools können per Export registriert werden
  - KI-Systeme können Tool-Schemas abrufen und Aktionen ausführen

- **Admin-Kommandos**
  - Peds manuell spawnen/löschen
  - Alle Peds entfernen
  - Ped-Anzahl anzeigen
  - KI-Chat aktivieren/deaktivieren

- **Entwickler-Exports**
  - Peds spawnen/löschen
  - Ped-Anzahl abrufen
  - Tool-System verwenden
  - OpenRouter zur Laufzeit konfigurieren

## Voraussetzungen

Empfohlen:

- FiveM Server
- `oxmysql`
- `qb-core`
- `qb-target`

Optional/alternativ:

- ESX statt QB-Core, wenn `Config.UseQbCore = false` gesetzt wird
- OpenRouter API-Key für externe KI-Antworten

> Hinweis: In `fxmanifest.lua` sind aktuell `oxmysql`, `qb-core` und `qb-target` als Dependencies eingetragen. Wenn du ESX ohne QB-Core nutzen möchtest, musst du die Dependencies und Config entsprechend anpassen.

## Installation

1. Resource in deinen FiveM-Server kopieren:

   ```text
   resources/[local]/ai-peds
   ```

2. Sicherstellen, dass die Abhängigkeiten vor dieser Resource starten:

   ```cfg
   ensure oxmysql
   ensure qb-core
   ensure qb-target
   ensure ai-peds
   ```

3. Datenbank konfigurieren.

   `oxmysql` muss korrekt eingerichtet sein. Die Resource erstellt beim Start automatisch folgende Tabellen, falls sie noch nicht existieren:

   - `ai_peds_stats`
   - `ai_peds_relationships`
   - `ai_peds_interactions`
   - `ai_peds_personas`

4. Server starten oder Resource neu laden:

   ```text
   refresh
   ensure ai-peds
   ```

Beim Start werden automatisch mehrere Peds gespawnt und an Clients synchronisiert.

## Konfiguration

Die wichtigsten Dateien:

- `shared/config.lua` - Hauptkonfiguration
- `shared/settings.lua` - KI/OpenRouter/Scheduler-Einstellungen
- `fxmanifest.lua` - Resource-Scripts und Dependencies

### Framework wählen

In `shared/config.lua`:

```lua
Config.UseQbCore = true -- QB-Core verwenden
```

Für ESX:

```lua
Config.UseQbCore = false
```

### Debug aktivieren

```lua
Config.Debug = true
```

### Spawn-Orte ändern

In `Config.SpawnLocations` kannst du feste Spawnpunkte definieren:

```lua
Config.SpawnLocations = {
    {coords = vector4(230.0, -800.0, 30.0, 100.0), model = 'a_m_m_business_01'}
}
```

Zusätzlich spawnt die Resource beim Start zufällig generierte FreeRoam-Peds.

### Verhalten anpassen

In `Config.Behaviors` steuerst du:

- Wandern
- Arbeitszeiten
- Arbeitsorte
- Sozialverhalten
- Chat-Reichweite
- Gruppenchat-Wahrscheinlichkeit

Beispiel Arbeitszeit:

```lua
Config.Behaviors.working.workHours = {
    start = 8,
    finish = 18
}
```

### Chat-Texte ändern

In `Config.ChatMessages`:

```lua
Config.ChatMessages.greetings = {
    "Hey, wie geht's?",
    "Guten Tag!"
}
```

### FreeRoam-Outfits anpassen

Die Kleidung wird über `Config.OutfitComponents` generiert. Dort werden Component-ID, Drawable-Range und Texture-Range definiert.

## OpenRouter KI aktivieren optional

Standardmäßig ist externe KI deaktiviert.

In `shared/settings.lua`:

```lua
Settings.OpenRouterApiKey = "DEIN_API_KEY"
Settings.OpenRouterEnabled = true
```

Optional zur Laufzeit per Export:

```lua
exports['ai-peds']:SetOpenRouterEnabled(true, "DEIN_API_KEY", "openai/gpt-3.5-turbo")
```

Oder ingame als Admin:

```text
/ai-peds-ki enable
/ai-peds-ki disable
```

## Admin-Kommandos

| Befehl | Beschreibung |
|---|---|
| `/ai-peds-spawn [type] [gender]` | Spawnt einen Ped an deiner Position |
| `/ai-peds-delete` | Löscht einen Ped in deiner Nähe |
| `/ai-peds-cleanup` | Entfernt alle aktiven Peds |
| `/ai-peds-count` | Zeigt die Anzahl aktiver Peds |
| `/ai-peds-ki enable` | Aktiviert KI-Chat |
| `/ai-peds-ki disable` | Deaktiviert KI-Chat |

Beispiele:

```text
/ai-peds-spawn business male
/ai-peds-spawn farmer
/ai-peds-spawn random female
```

Admin-Rechte werden über QB-Core/ESX Gruppen geprüft. Ohne Framework ist der Check aktuell testweise offen.

## Client-Debug-Kommandos

Wenn `Config.Debug = true` gesetzt ist:

| Befehl | Beschreibung |
|---|---|
| `/ai-peds-list` | Listet registrierte Peds im Client-Log |
| `/ai-peds-state [netId] [state]` | Setzt lokal einen Zustand |

## Entwickler-Exports

### Peds verwalten

```lua
-- Ped an bestimmter Position spawnen
local netId = exports['ai-peds']:SpawnPedAtLocation(vector4(x, y, z, heading), nil, 'farmer')

-- Ped löschen
exports['ai-peds']:DeletePed(netId)

-- Ped-Anzahl abrufen
local count = exports['ai-peds']:GetPedCount()
```

### OpenRouter

```lua
exports['ai-peds']:SetOpenRouterEnabled(true, "api-key", "openai/gpt-3.5-turbo")
```

### Tool-System

```lua
-- Tool ausführen
local result = exports['ai-peds']:ExecuteTool('speak', netId, "Hallo!", "happy", 4000)

-- Tool-Schema abrufen
local schema = exports['ai-peds']:GetToolSchema()

-- Eigenes Tool registrieren
exports['ai-peds']:RegisterTool('customAction', {
    name = 'customAction',
    description = 'Eigene Aktion',
    parameters = {
        netId = 'number'
    },
    execute = function(netId)
        return true
    end
})
```

## Verfügbare NPC-Tools

| Tool | Zweck |
|---|---|
| `speak` | NPC spricht eine Nachricht |
| `moveTo` | NPC bewegt sich zu Koordinaten |
| `workAt` | NPC arbeitet an einem konfigurierten Ort |
| `interact` | NPC interagiert mit anderem NPC |
| `getRelationship` | Beziehung zwischen zwei NPCs abrufen |
| `setState` | Zustand eines NPCs setzen |
| `scanEnvironment` | Umgebung nach NPCs scannen |
| `remember` | Erinnerung/Wert für NPC speichern |

## Resource-Struktur

```text
ai-peds/
├── client/
│   ├── aiController.lua
│   ├── animations.lua
│   ├── chatSystem.lua
│   ├── main.lua
│   ├── pedBehavior.lua
│   ├── pedSpawner.lua
│   └── target.lua
├── server/
│   ├── database.lua
│   ├── main.lua
│   ├── openrouter.lua
│   ├── pedInteractions.lua
│   ├── pedManager.lua
│   ├── scheduler.lua
│   ├── tools.lua
│   └── tools/
├── shared/
│   ├── config.lua
│   └── settings.lua
├── fxmanifest.lua
└── Makefile
```

## Entwicklung und Checks

Die Resource enthält ein Makefile für Syntax- und Kompatibilitätschecks.

```bash
make syntax      # Lua-Syntax prüfen
make lint        # luacheck verwenden, falls installiert
make check-fivem # FiveM-Kompatibilitätschecks
make full-check  # kompletter Check
```

Erwartetes Ergebnis:

```text
=== Alle Checks bestanden! ✅ ===
```

## Troubleshooting

### Es spawnen keine Peds

- Prüfe, ob `ensure ai-peds` nach `oxmysql`, Framework und Target gestartet wird.
- Prüfe die Server-Konsole auf Lua-Fehler.
- Prüfe, ob Clients das Event `ai-peds:client:ready` auslösen.

### Datenbanktabellen fehlen

- Stelle sicher, dass `oxmysql` gestartet ist.
- Prüfe deine MySQL-Verbindung.
- Die Tabellen werden erst nach einigen Sekunden erstellt.

### Target-Interaktionen fehlen

- Prüfe, ob `qb-target` gestartet ist.
- Prüfe `Config.UseQbCore`.
- Stelle sicher, dass die Peds clientseitig existieren.

### KI antwortet nicht

- `Settings.OpenRouterEnabled = true` setzen.
- API-Key eintragen.
- Server-Konsole auf HTTP/API-Fehler prüfen.

## Lizenz

MIT License
