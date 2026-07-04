--- 
--- Scan Tool - Umgebung nach NPCs scannen
---

ToolScan = {}

function ToolScan.Execute(netId, radius)
    radius = radius or 10.0
    TriggerClientEvent('ai-peds:client:scanEnvironment', -1, netId, radius)
    return {status = "scanning", radius = radius}
end

return ToolScan