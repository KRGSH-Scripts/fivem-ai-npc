# luacheck Konfiguration für FiveM Resources
# Speichere als .luacheckrc im Resource-Ordner

# FiveM globale Variablen (keine Warnings)
std = none
# CitizenFX globals
globals = Citizen, QBCore, ESX, MySQL, TriggerEvent, TriggerClientEvent, TriggerServerEvent, 
          RegisterNetEvent, RegisterCommand, AddEventHandler, 
          GetClockHours, GetClockMinutes,
          CreateThread, Wait, SetTimeout, SetInterval,
          GetEntityCoords, SetEntityCoords, CreatePed, DeletePed,
          DoesEntityExist, NetworkGetEntityFromNetworkId, NetworkGetNetworkIdFromEntity

# Max Zeilenlänge (FiveM liebt lange Zeilen manchmal)
max-line-length = 200

# Ignoriere bestimmte Muster
ignore = 
  # FiveM-typisch
  211 -- unused local "_"
  212 -- unused varargs
  213 -- unused import
  301 -- line length (wird für manche Dateien ignoriert)

# Lua Version
lua-version = 5.4

# Keine ungenutzten Argumente-Warnungen (FiveM Events)
unused-args = false

# Keine ungenutzten Fields (oft bei Config-Tabellen)  
unused-fields = false