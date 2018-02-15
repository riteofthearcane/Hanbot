local script = {}
script.name = "Varus"
script.developer = "asdf"
script.version = 1.0

local avada_lib = module.lib('avada_lib')
if not avada_lib then
	console.set_color(12)
	print("You need to have Avada Lib in your community_libs folder to run " .. script.name .. "!")
	print("You can find it here:")
	console.set_color(11)
	print("https://gitlab.soontm.net/get_clear_zip.php?fn=avada_lib")
	console.set_color(15)
	return
elseif avada_lib.version < 1 then
	console.set_color(12)
	print("Your need to have Avada Lib updated to run " .. script.name .. "!")
	print("You can find it here:")
	console.set_color(11)
	print("https://gitlab.soontm.net/get_clear_zip.php?fn=avada_lib")
	console.set_color(15)
	return
end

local common = avada_lib.common
local ts = module.internal('TS')
local orb = module.internal("orb")
local gpred = module.internal("pred")

script.q = {delay = 0.25, width = 70, speed = 1850, boundingRadiusMod = 0, minRange = 925, maxRange = 1600, active = false, start = 0} 
script.e = {delay = 0.25, radius = 200, speed = 1000, boundingRadiusMod = 0, range = 925}
script.r = {delay = 0.25, width = 120, speed = 1850, boundingRadiusMod = 1, collision = {hero = true, minion = false }, range = 1075 }
script.buffer = {time = os.clock(), target = nil, delay = 0.15}
script.nextcast = os.clock()

script.menu = menu("varusmenu", script.name)
	ts.load_to_menu(script.menu)

	script.menu:keybind("ult", "Semi-manual R", "Z", nil)
	script.menu:menu("antigap", "Anti-gapcloser R")
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		script.menu.antigap:boolean(enemy.charName, enemy.charName, false)
	end
	script.menu:dropdown("sp_priority", "Spell Priority", 1, {"E","Q"})
		

local function getQRange()
	local t = os.clock() - script.q.start + network.latency
	return math.min(script.q.maxRange, script.q.minRange + t/2.0*script.q.minRange)
end

function script.CastQ(target)
	if player:spellSlot(0).state == 0 then
		local seg = gpred.linear.get_prediction(script.q, target)
		if seg and seg.startPos:dist(seg.endPos) <= getQRange() then
			player:castSpell("release", 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
		end 
	end
end
	
function script.CastE(target)
	if player:spellSlot(2).state == 0  then
		local seg = gpred.circular.get_prediction(script.e, target)
		if seg and seg.startPos:dist(seg.endPos) <= script.e.range then
			player:castSpell("pos", 2, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
		end
	end
end	
	
function script.CastR(target)
	if player:spellSlot(3).state == 0  then
		local seg = gpred.linear.get_prediction(script.r, target)
		if seg and seg.startPos:dist(seg.endPos) <= script.r.range then
			if not gpred.collision.get_prediction(script.r, seg, target) then
				player:castSpell("pos", 3, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end
		end
	end
end

local function BufferQ(enemy)
	if os.clock()>=script.buffer.time and script.buffer.target == nil then
		player:castSpell("pos", 0, game.mousePos)
		script.buffer.time = os.clock()+script.buffer.delay
		script.buffer.target = enemy
	end
end

local function DetonateBlight()
	for i=0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy.buff["varuswdebuff"] and enemy.buff["varuswdebuff"].stacks== 3 and player.pos:dist(enemy.pos) <= 1000 and os.clock() >= script.nextcast then
			if player:spellSlot(0).state == 0 and player:spellSlot(2).state ~= 0 then
				BufferQ(enemy)
			end
			if player:spellSlot(0).state ~= 0 and player:spellSlot(2).state == 0 then
				script.CastE(enemy)
				script.nextcast = os.clock() + 1.175
			end
			if player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 then
				if script.menu.sp_priority:get() == 1 then 
					script.CastE(enemy)
					script.nextcast = os.clock() + 1.175
				else
					BufferQ(enemy)
				end
			end
		end
	end
end



local function AntiGap()
	if player:spellSlot(3).state == 0  then
		for i=0, objManager.enemies_n - 1 do
			local enemy = objManager.enemies[i]
			if common.IsValidTarget(enemy) and enemy.path.isActive and enemy.path.isDashing then
				name = enemy.charName
				if script.menu.antigap[name]:get() then
					local pred_pos = gpred.core.project(player.path.serverPos2D, enemy.path, network.latency + script.r.delay, script.r.speed, enemy.path.dashSpeed)
					if pred_pos and pred_pos:dist(player.path.serverPos2D) <= 850 then
						player:castSpell("pos", 3, vec3(pred_pos.x, enemy.y, pred_pos.y))
					end
				end
			end
		end
	end
end

local function UltMultiple()
	ultcount = 3
	if player:spellSlot(3).state == 0  then
		for i=0, objManager.enemies_n - 1 do
			enemy = objManager.enemies[i]
			hit = 0
			for j=0, objManager.enemies_n - 1 do
				near = objManager.enemies[j]
				if enemy.pos:dist(near.pos) <= 600 then
					hit = hit + 1
				end
			end
			if hit >= ultcount then
				script.CastR(enemy)
			end
		end
	end
end

local TargetSelection = function(res, obj, dist)
    if dist < 2000 then
      res.obj = obj
      return true
    end
end

local function OnTick()
	local target = ts.get_result(TargetSelection).obj
	AntiGap()
	if orb.menu.combat:get() then
		if os.clock() >= script.buffer.time and script.buffer.target~= nil then
			if not common.IsValidTarget(script.buffer.target) then
				script.buffer.target = target
			end
			script.CastQ(script.buffer.target)
			script.buffer.target = nil
			script.nextcast = os.clock() + 0.5
		end
		if script.q.active and target and script.buffer.target == nil then
		script.CastQ(target)	
		end
		UltMultiple()
		DetonateBlight()
	end
	if target then
		if script.menu.ult:get() then
			script.CastR(target)
		end
		if orb.menu.hybrid:get() then
			script.CastE(target)
		end
	end
end

local function OnUpdateBuff(buff)
	if buff.name == "VarusQ" then 
		script.q.active = true
		script.q.start = os.clock()
		orb.core.set_pause_attack(math.huge)
	end
end

local function OnRemoveBuff(buff)
	if buff.name == "VarusQ" then 
		script.q.active = false
		orb.core.set_pause_attack(0)
	end
end

local function OnDraw()
	graphics.draw_circle(player.pos, script.e.range, 1, graphics.argb(255, 255, 255, 255), 50)
	graphics.draw_circle(player.pos, script.q.maxRange, 1, graphics.argb(255, 255, 255, 255), 50)
end

cb.add(cb.removebuff, OnRemoveBuff)
cb.add(cb.updatebuff, OnUpdateBuff)
cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)

print("Varus loaded")