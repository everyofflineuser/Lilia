﻿local function fixupProp(client, ent, mins, maxs)
    local pos = ent:GetPos()
    local down, up = ent:LocalToWorld(mins), ent:LocalToWorld(maxs)
    local trD = util.TraceLine({
        start = pos,
        endpos = down,
        filter = {ent, client}
    })

    local trU = util.TraceLine({
        start = pos,
        endpos = up,
        filter = {ent, client}
    })

    if trD.Hit and trU.Hit then return end
    if trD.Hit then ent:SetPos(pos + trD.HitPos - down) end
    if trU.Hit then ent:SetPos(pos + trU.HitPos - up) end
end

local function tryFixPropPosition(client, ent)
    local m, M = ent:OBBMins(), ent:OBBMaxs()
    fixupProp(client, ent, Vector(m.x, 0, 0), Vector(M.x, 0, 0))
    fixupProp(client, ent, Vector(0, m.y, 0), Vector(0, M.y, 0))
    fixupProp(client, ent, Vector(0, 0, m.z), Vector(0, 0, M.z))
end

net.Receive("SpawnMenuSpawnItem", function(_, client)
    local id = net.ReadString()
    if not IsValid(client) or not id or not client:hasPrivilege("Staff Permissions - Can Use Item Spawner") then return end
    local startPos, dir = client:EyePos(), client:GetAimVector()
    local tr = util.TraceLine({
        start = startPos,
        endpos = startPos + dir * 4096,
        filter = client
    })

    if not tr.Hit then return end
    lia.item.spawn(id, tr.HitPos, function(item)
        local ent = item:getEntity()
        if not IsValid(ent) then return end
        tryFixPropPosition(client, ent)
        undo.Create("item")
        undo.SetPlayer(client)
        undo.AddEntity(ent)
        local name = lia.item.list[id] and lia.item.list[id].name or id
        undo.SetCustomUndoText("Undone " .. name)
        undo.Finish("Item (" .. name .. ")")
        lia.log.add(client, "spawnItem", name, "SpawnMenuSpawnItem")
    end, angle_zero, {})
end)

net.Receive("SpawnMenuGiveItem", function(_, client)
    local id, targetID = net.ReadString(), net.ReadString()
    if not IsValid(client) then return end
    if not id then return end
    if not client:hasPrivilege("Staff Permissions - Can Use Item Spawner") then return end
    local targetChar = lia.char.getBySteamID(targetID)
    local target = targetChar:getPlayer()
    if not targetChar then return end
    targetChar:getInv():add(id)
    lia.log.add(client, "chargiveItem", id, target, "SpawnMenuGiveItem")
end)
