--self.entity = chip
--self.player = chip owner

CreateConVar("sbox_E2_maxNpcsPerSecond", 4, FCVAR_NONE, "", 1)

E2Lib.RegisterExtension("npcspawncore", false, "E2 functions that spawn npcs.")

local npcspawncore = {}
hook.Add("PlayerInitialSpawn", "npcspawncore_plyinitspawn", function(ply, trans)
    ply.lastNpcSpawntime = 0
end)

for i,ply in ipairs(player.GetAll()) do
	ply.lastNpcSpawntime = 0
end

registerCallback("construct", function(self)
	self.entity.npcSpawnUndo = 1
	self.player.npcsBursted = 0
	self.entity.npcsToUndo = {}
	timer.Create("npcspawncore_npcburst_clear", 1.0, 0, function()
		if self.player then
			self.player.npcsBursted = 0
		end
	end)
end)

local function NpcCanSpawn(ply)
	return ply.npcsBursted < GetConVar("sbox_E2_maxNpcsPerSecond"):GetFloat() and true or false
end


e2function number npcCanSpawn()
	return NpcCanSpawn(self.player) and 1 or 0
end

e2function void npcSpawnUndo(number state)
	self.entity.npcSpawnUndo = state == 1
end

function NpcSpawn(class, pos, yaw, chip)
    local is_npc = false
	local npc = ents.Create(class)
    npc:SetPos(pos)
    if yaw ~= nil then npc:SetAngles(Angle(0,yaw,0)) end

    if npc:IsNPC() then
        npc:Spawn()
        is_npc = true
    else
        SafeRemoveEntity(npc)
    end

	if IsValid(chip.player) then
		gamemode.Call("PlayerSpawnedNPC", chip.player, chip.player, npc)
	end
	return npc, is_npc
end

e2function entity npcSpawn(string class, vector pos)
    if NpcCanSpawn(self.player) then
        local npc, is_npc = NpcSpawn(class, pos, nil, self)
        
        if not is_npc then
            return self:throw("Not an NPC class!", 0)
        end
        
        if self.entity.npcSpawnUndo then
			undo.Create("E2 Spawned Npc")
			undo.AddEntity(npc)
			undo.SetPlayer(self.player)
			undo.Finish("E2 Spawned Npc")
        else
            self.entity.npcsToUndo[#self.entity.npcsToUndo + 1] = npc
        end

        self.player.npcsBursted = self.player.npcsBursted + 1

        self.player.lastNpcSpawntime = CurTime()
        return npc
    end
end

e2function entity npcSpawn(string class, vector pos, number yaw)
    if NpcCanSpawn(self.player) then
        local npc, is_npc = NpcSpawn(class, pos, yaw, self)
        
        if not is_npc then
            return self:throw("Not an NPC class!", 0)
        end
        
        if self.entity.npcSpawnUndo then
            undo.Create("E2 Spawned Npc")
            undo.AddEntity(npc)
            undo.SetPlayer(self.player)
            undo.Finish("E2 Spawned Npc")
        else
            self.entity.npcsToUndo[#self.entity.npcsToUndo + 1] = npc
        end

        self.player.npcsBursted = self.player.npcsBursted + 1

        self.player.lastNpcSpawntime = CurTime()
        return npc
    end
end

e2function void entity:npcSetYaw(number yaw)
    if not this:IsNPC() then return self:throw("Not an NPC!", 0) end
    this:SetAngles(Angle(0,yaw,0))
end

registerCallback("destruct", function(self)
	for k,v in ipairs(self.entity.npcsToUndo) do
		SafeRemoveEntity(v)
	end
end)