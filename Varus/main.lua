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
local ts = avada_lib.targetSelector
local orb = module.internal("orb")
local gpred = module.internal("pred")

script.qPred = { delay = 0, width = 70, speed = 1850, boundingRadiusMod = 0} 
script.ePred = { delay = 0.25, radius = 200, speed = 1000, boundingRadiusMod = 0}
script.rPred = { delay = 0.25, width = 120, speed = 1850, boundingRadiusMod = 1, collision = { hero = true, minion = false } }
qActive = false
qStart = 0

script.menu = menu("varusmenu", script.name)
	ts = ts(script.menu, 1800)
	ts:addToMenu()
	script.menu:keybind("ult", "Manual Ult", "Z", nil)
	script.menu:dropdown("sp_priority", "Spell Priority", 2, {"E","Q"})
	script.menu:menu("antigap", "Use Ult against Dashes")
		for i = 0, objManager.enemies_n - 1 do
			local enemy = objManager.enemies[i]
			script.menu.antigap:boolean(enemy.charName, enemy.charName, false)
		end

local function getQRange()
	local t = os.clock() - qStart + network.latency
	return math.min(1600, 925 + t/2.0*925)
end

function script.CastQ(target)
	if player:spellSlot(0).state == 0 then
		local seg = gpred.linear.get_prediction(script.qPred, target)
		if seg and seg.startPos:dist(seg.endPos) <= getQRange() then
			player:castSpell("release", 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
		end 
	end
end
	
function script.CastE(target)
	if player:spellSlot(2).state == 0  then
		local seg = gpred.circular.get_prediction(script.ePred, target)
		if seg and seg.startPos:dist(seg.endPos) <= 925 then
			player:castSpell("pos", 2, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
		end
	end
end	
	
function script.CastR(target)
	if player:spellSlot(3).state == 0  then
		local seg = gpred.linear.get_prediction(script.rPred, target)
		if seg and seg.startPos:dist(seg.endPos) <= 1075 then
			if not gpred.collision.get_prediction(script.rPred, seg, target) then
				player:castSpell("pos", 3, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end
		end
	end
end

local function DetonateBlight()
	for i=0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy.buff["varuswdebuff"] and enemy.buff["varuswdebuff"].stacks==3 then
			--script.CastE(enemy)
			--player:castSpell("pos", 0, game.mousePos) 
			--if qActive then
				--script.CastQ(enemy)
			--end
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
					local pred_pos = gpred.core.lerp(enemy.path, network.latency + script.rPred.delay, enemy.path.dashSpeed)
					if pred_pos and pred_pos:dist(player.path.serverPos2D) <= 1075 then
						player:castSpell("pos", 3, vec3(pred_pos.x, enemy.y, pred_pos.y)) -- cp from ryan
					end
				end
			end
		end
	end
end

local function UltMultiple()
	ultat = 3
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
			if hit >= ultat then
				script.CastR(enemy)
			end
		end
	end
end

local function OnTick()
	local target = ts.target	
	AntiGap()
	if orb.menu.combat:get() then
		UltMultiple()
		DetonateBlight()
		if qActive and target then
			script.CastQ(target)	
		end
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
		qActive = true
		qStart = os.clock()
		orb.core.set_pause_attack(math.huge)
	end
end


local function OnRemoveBuff(buff)
	if buff.name == "VarusQ" then 
		qActive = false
		orb.core.set_pause_attack(0)
	end
end

cb.add(cb.removebuff, OnRemoveBuff)

local function OnDraw()
	graphics.draw_circle(player.pos, 925, 1, graphics.argb(255, 255, 255, 255), 50)
	graphics.draw_circle(player.pos, 1600, 1, graphics.argb(255, 255, 255, 255), 50)
end

cb.add(cb.updatebuff, OnUpdateBuff)
cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)

print("Varus loaded")