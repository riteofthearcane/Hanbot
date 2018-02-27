local script = {}
script.name = "Varus"
script.developer = "asdf"
script.version = 2.3

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

script.q = {delay = 0, width = 70, speed = 1850, boundingRadiusMod = 0, minRange = 925, maxRange = 1600, active = false, start = 0, chargetime = os.clock(), target = nil, releasedelay = 0.15} 
script.e = {delay = 1.25, radius = 235, speed = math.huge, boundingRadiusMod = 0, range = 925}
script.r = {delay = 0.25, width = 120, speed = 1850, boundingRadiusMod = 1, collision = {hero = true, minion = false }, range = 1075}
script.aa = {range = 575, speed = 2000, delay = 1}
script.nextcast = os.clock()
script.preQ = {time = os.clock(),target = nil}
script.preE = {time = os.clock(),target = nil}
script.guinsoos = false

script.menu = menu("varusmenu", script.name)
	ts.load_to_menu(script.menu)

	script.menu:keybind("ult", "Semi-manual R", "Z", nil)
	script.menu:menu("antigap", "Anti-gapcloser R")
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		script.menu.antigap:boolean(enemy.charName, enemy.charName, false)
	end
	script.menu:dropdown("sp_priority", "Spell Priority", 1, {"E","Q"})
	script.menu:boolean("experimental", "Experimental Fast Combo", true)
	script.menu:boolean("drawings", "Drawings", true)

		
local function getQRange()
	local t = os.clock() - script.q.start + network.latency
	return math.min(script.q.maxRange, script.q.minRange + t/2.0*script.q.minRange)
end

local function qTraceFilter(seg, obj)
	if gpred.trace.linear.hardlock(script.q, seg, obj) then
		return true
	end
	if gpred.trace.linear.hardlockmove(script.q, seg, obj) then
		return true
	end
	if not obj.path.isActive then
		if getQRange() < seg.startPos:dist(obj.pos2D) + (obj.moveSpeed * 0.333) then
			return false
		end
	end
	if getQRange()<1300 then
		return true
	end
	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

local function rTraceFilter(seg, obj, slow)
	if gpred.trace.linear.hardlock(script.r, seg, obj) then
		return true
	end
	if gpred.trace.linear.hardlockmove(script.r, seg, obj) then
		return true
	end
	if not obj.path.isActive then
		if script.r.range < seg.startPos:dist(obj.pos2D) + (obj.moveSpeed * 0.333) then
			return false
		end
	end
	if not slow then
		return true
	end
	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

function script.CastQ(target)
	if player:spellSlot(0).state == 0 then
		local seg = gpred.linear.get_prediction(script.q, target)
		if seg and qTraceFilter(seg, target) then
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
	
function script.CastR(target, slow)
	if player:spellSlot(3).state == 0  then
		local seg = gpred.linear.get_prediction(script.r, target)
		if seg and rTraceFilter(seg, target, slow) then
			if not gpred.collision.get_prediction(script.r, seg, target) then
				player:castSpell("pos", 3, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end
		end
	end
end

local function BufferQ(enemy)
	if os.clock()>=script.q.chargetime and script.q.target == nil then
		player:castSpell("pos", 0, game.mousePos)
		script.q.chargetime = os.clock()+script.q.releasedelay
		script.q.target = enemy
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
				if enemy.pos:dist(near.pos) <= 500 then
					hit = hit + 1
				end
			end
			if hit >= ultcount then
				script.CastR(enemy, true)
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

local function preCastQ(target, aatraveltime, animationTime)
	qtraveltime = player.pos:dist(target.pos)/script.q.speed
	offset = aatraveltime+animationTime-qtraveltime-script.q.releasedelay+0.2
	script.preQ.time = os.clock()+offset
	script.preQ.target=target
end

local function preCastE(target, aatraveltime,animationTime)
	offset = aatraveltime+animationTime-script.e.delay + 0.7  
	script.preE.time = os.clock()+offset
	script.preE.target=target
end

local function checkAA(missile)
	if script.menu.experimental:get() and missile.spell.owner.ptr == player.ptr and missile.spell.isBasicAttack then
		enemy = orb.core.cur_attack_target
		if orb.menu.combat:get() and common.IsValidTarget(enemy) and player.pos:dist(enemy.pos) <= script.aa.range-100 and os.clock() >= script.nextcast then
			if (enemy.buff["varuswdebuff"] and not script.guinsoos and enemy.buff["varuswdebuff"].stacks== 1) or (script.guinsoos and not enemy.buff["varuswdebuff"]) then
				aatraveltime = player.pos:dist(enemy.pos)/script.aa.speed
				if player:spellSlot(0).state == 0 and player:spellSlot(2).state ~= 0 then
					preCastQ(enemy, aatraveltime, missile.spell.animationTime)
				end
				if player:spellSlot(0).state ~= 0 and player:spellSlot(2).state == 0 then
					preCastE(enemy, aatraveltime, missile.spell.animationTime)
				end
				if player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 then
					if script.menu.sp_priority:get() == 1 then 
						preCastE(enemy, aatraveltime, missile.spell.animationTime)
					else
						preCastQ(enemy, aatraveltime, missile.spell.animationTime)
					end
				end 
				if orb.combat.can_attack() and player.pos:dist(enemy.pos) <= script.aa.range then
					player:attack(enemy)
				end
			end
		end
	end
end
		
local function OnTick()
	local target = ts.get_result(TargetSelection).obj
	AntiGap()
	if orb.menu.combat:get() then
		if os.clock() >= script.q.chargetime and script.q.target~= nil then
			if not common.IsValidTarget(script.q.target) then
				script.q.target = target
			end
			script.CastQ(script.q.target)
			script.q.target = nil
			script.nextcast = os.clock() + 0.5
		end
		if os.clock() >= script.preQ.time and os.clock() - script.preQ.time <= 1 and script.preQ.target ~= nil and player:spellSlot(0).state == 0 then
			if common.IsValidTarget(script.preQ.target) then
				BufferQ(script.preQ.target)
				script.preQ.target = nil
			else
				script.q.target = nil
			end
		end
		if os.clock() >= script.preE.time and os.clock() - script.preE.time <= 1 and script.preE.target ~= nil and player:spellSlot(2).state == 0 then
			if common.IsValidTarget(script.preE.target) then
				script.CastE(script.preE.target)
			end
				script.nextcast = os.clock() + script.e.delay
			script.preE.target = nil
		end
		if script.q.active and target and script.q.target == nil then
		script.CastQ(target)	
		end
		UltMultiple()
		DetonateBlight()
	end
	if target then
		if script.menu.ult:get() then
			script.CastR(target, false)
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
	if buff.name == "rageblade" and buff.owner.ptr == player.ptr and buff.stacks == 6 then
		script.guinsoos = true
	end
end

local function OnRemoveBuff(buff)
	if buff.name == "VarusQ" then 
		script.q.active = false
		orb.core.set_pause_attack(0)
	end
	if buff.name == "rageblade" and buff.owner.ptr == player.ptr then
		script.guinsoos = false
	end
end

local function OnDraw()
	if script.menu.drawings:get() then
		graphics.draw_circle(player.pos, script.e.range, 1, graphics.argb(255, 255, 255, 255), 50)
		graphics.draw_circle(player.pos, script.q.maxRange, 1, graphics.argb(255, 255, 255, 255), 50)
	end
end

cb.add(cb.missile, checkAA)
cb.add(cb.removebuff, OnRemoveBuff)
cb.add(cb.updatebuff, OnUpdateBuff)
cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)

print("Varus loaded")