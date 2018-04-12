--[[
Bugs:

-if manual E then press combo too fast, will cast E1 instead of E2
]]

local script = {}
script.name = "Irelia"
script.developer = "asdf"
script.version = 1.1

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

script.q = {range = 625}

script.e = {
	delay = 0.5, 
	radius =70, --originally 70 
	speed = 2000, 
	boundingRadiusMod = 0,
	range = 900}
	
script.e_parameters = {
	e1Pos = vec3(0,0,0),
	target2 = nil,
	nextCast = os.clock()
}
	
script.e_faux = {
	delay = 1, 
	radius =1, 
	speed = math.huge, 
	boundingRadiusMod = 0, 
	range = 900}
	
script.e_obj = nil

script.w = {
	delay = 0.25, 
	width = 120, 
	speed = math.huge, 
	boundingRadiusMod = 0, 
	range = 825} 
	
script.r = {
	delay = 0.4,
	width = 100, --originally 160
	speed = 2000, 
	boundingRadiusMod = 0, 
	collision = {hero = true, minion = false}, 
	range = 700}

passiveBaseScale = {2.5, 2,5, 3.5, 3.5, 4.5, 4.5, 5.5, 5.5, 6,5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5, 14.5, 15.5, 16.5}
passiveADScale = {2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4}
PTAScale = { 0.08, 0.08, 0.08, 0.09, 0.09, 0.09, 0.09, 0.10, 0.10, 0.10, 0.10, 0.11, 0.11, 0.11, 0.11, 0.12, 0.12, 0.12 }
sheenTimer = os.clock()

script.menu = menu("ireliamenu", script.name)
	ts.load_to_menu(script.menu)
	script.menu:keybind("r", "Semi-manual R", "Z", nil)
	script.menu:slider("searchrange", "Enemy Search Range", 500, 0, 900, 1)

function QReductionMultiplier(target)
  local multiplier = 1
  
  if player.buff["summonerexhaust"] then
	multiplier = multiplier * 0.6
  end
  
  if player.buff["itemphantomdancerdebuff"] then
	multiplier = multiplier * 0.88
  end
  
  if player.buff["itemsmitechallenge"] then
	multiplier = multiplier * 0.8
  end
  
  if target.buff["ferocioushowl"] then
	multiplier = multiplier * (0.55 - (target:spellSlot(3).level * 0.1))	
  end
  
  if target.buff["braumshieldraise"] then --idk if this applies to twitch/kalista e
	multiplier = multiplier * (0.725 - (target:spellSlot(2).level * 0.025))
  end
  
  if target.buff["garenw"] then
	multiplier = multiplier * 0.7
  end
  
  if target.buff["gragaswself"] then
	multiplier = multiplier * (0.92 - (target:spellSlot(1).level * 0.02))
  end
  
  if target.buff["galiorallybuff"] then
	multiplier = multiplier * ((0.85 - (target:spellSlot(3).level * 0.05)) - (0.08 * (target.bonusSpellBlock / 100)))
  end
  
  if target.buff["moltenshield"] then
	multiplier = multiplier * (0.90 - (target:spellSlot(2).level * 0.06))
  end
  
  if target.buff["meditate"] then
	multiplier = multiplier * (0.55 - (target:spellSlot(1).level * 0.05))
  end
  
  if target.buff["sonapassivedebuff"] then
	multiplier = multiplier * (0.75 - (0.04 * (common.GetTotalAP(target) / 100)))
  end
  
  if target.buff["malzaharpassiveshield"] then
	multiplier = multiplier * 0.1
  end
  
  if target.buff["warwicke"] then
	multiplier = multiplier * (0.70 - (target:spellSlot(1).level * 0.05))
  end
  
  return multiplier
end

function GetQDamage(target)
	local totalPhysical = 0
	local totalMagical = 0

	local flat = -10 + 20*player:spellSlot(0).level
	local ratio = common.GetTotalAD()*0.7
	local total = flat + ratio 
	if target.type == TYPE_MINION then
		total = total * 1.6
	end
	totalPhysical = total + totalPhysical
	
	--onhit
	local hasSheen = false
	local hasTF = false
	local hasBOTRK = false
	local hasTitanic = false
	local hasWitsEnd = false
	local hasRecurve = false
	local hasGuinsoo = false
	for i = 0, 5 do 
		if player:itemID(i) == 3078 then
			hasTF = true	
		end
		if player:itemID(i) == 3057 then
			hasSheen = true
		end
		if player:itemID(i) == 3153 then
			hasBOTRK = true
		end
		if player:itemID(i) == 3748 then
			hasTitanic = true
		end
		if player:itemID(i) == 3748 then
			hasTitanic = true
		end
		if player:itemID(i) == 3091 then
			hasWitsEnd = true
		end
		if player:itemID(i) == 1043 then
			hasRecurve = true
		end
		if player:itemID(i) == 3124 then
			hasGuinsoo = true
		end
	end
		
	local onhitPhysical = 0
	local onhitMagical = 0
		
	if hasTF and (os.clock() >= sheenTimer or player.buff[sheen]) then
			onhitPhysical = onhitPhysical + 2*player.baseAttackDamage
	end
	if hasSheen and not hasTF and (os.clock() >= sheenTimer or player.buff[sheen]) then
		onhitPhysical = onhitPhysical + player.baseAttackDamage
	end
	if hasBOTRK then
		if target.type == TYPE_MINION then
			onhitPhysical = onhitPhysical + math.min(math.max(15, target.health*0.08),60)
		else 
			onhitPhysical = onhitPhysical + math.max(15, target.health*0.08)
		end
	end
	if hasTitanic then
		if player.buff["itemtitanichydracleavebuff"] then
			onhitPhysical = onhitPhysical + 40 + player.maxHealth/10
		else
			onhitPhysical = onhitPhysical + 5 + player.maxHealth/100
		end
	end
	if hasRecurve then
		onhitPhysical = onhitPhysical+10
	end
	if hasWitsEnd then
		onhitMagical = onhitMagical + 42
	end
		
	--passive 
	if player.buff["ireliapassivestacks"] then
		local passiveTotalDmg = 1.5 + common.GetTotalAD() * passiveADScale[player.levelRef] / 100
		passiveTotalDmg = (player.buff["ireliapassivestacks"].stacks2+1)*passiveTotalDmg
		onhitMagical = onhitMagical + passiveTotalDmg
	end
	
	if hasGuinsoo then
		onhitPhysical = onhitPhysical + 5 + common.GetBonusAD(player)/10
		onhitMagical = onhitMagical + 5 + common.GetTotalAP(player)/10	
	end
	
	totalPhysical = totalPhysical + onhitPhysical
	totalMagical = totalMagical + onhitMagical
	
	if target.type == TYPE_HERO then
		--PTA
		totalPhysical = totalPhysical*(1+PTAScale[player.levelRef])
		totalMagical = totalMagical*(1+PTAScale[player.levelRef])
		--Conqueror
		--Other Reductions
		local reduction = QReductionMultiplier(target)
		totalPhysical = totalPhysical * reduction
		totalMagical = totalMagical * reduction
		if target.charName == "Kassadin" then
			totalMagical = totalMagical * 0.85
		end
	end
	return totalPhysical*common.PhysicalReduction(target) + totalMagical*common.MagicReduction(target)
end
	
local function lTraceFilter(seg, obj, spell)
	if gpred.trace.linear.hardlock(spell, seg, obj) then
		return true
	end
	if gpred.trace.linear.hardlockmove(spell, seg, obj) then
		return true
	end
	if not obj.path.isActive then
		if spell.range < seg.startPos:dist(obj.pos2D) + (obj.moveSpeed * 0.333) then
			return false
		end
	end
	return true
end	

local function cTraceFilter(seg, obj, spell)
	if gpred.trace.circular.hardlock(spell, seg, obj) then
		return true
	end
	if gpred.trace.circular.hardlockmove(spell, seg, obj) then
		return true
	end
	if not obj.path.isActive then
		if spell.range < seg.startPos:dist(obj.pos2D) + (obj.moveSpeed * 0.333) then
			return false
		end
	end
	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end	
	
function script.CastQ(target)
	if player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= script.q.range then
		player:castSpell("obj", 0, target)	 
	end
end

function CanKS(obj)
	return GetQDamage(obj) > common.GetShieldedHealth("ALL", obj)
end

function GetBestQ(pos)
	local minDistance = player.pos:dist(pos)
	local minDistObj = nil
	local minionsInRange = common.GetMinionsInRange(script.q.range, TEAM_ENEMY)
	for i, minion in pairs(minionsInRange) do 
		if minion then
			local minionDist = minion.pos:dist(pos)
			if CanKS(minion) or minion.buff["ireliamark"] then
				if  minionDist < minDistance then
					minDistance = minionDist
					minDistObj = minion
				end
			end
		end
	end
	
	local enemiesInRange = common.GetEnemyHeroesInRange(script.q.range, player.pos)
	for i, enemy in pairs(enemiesInRange) do 
		local enemyDist = enemy.pos:dist(pos)
		if CanKS(enemy) or enemy.buff["ireliamark"] then
			if enemyDist < minDistance then
				minDistance = enemyDist
				minDistObj = enemy
			end
		end
	end 
	
	if minDistance < player.pos:dist(pos) - 100 then
		return minDistObj
	else 
		return nil
	end
end

function script.CastW1(target) --spellblock
	if player:spellSlot(3).state == 0  then
	end
end

function script.CastW2(target)
	if player.buff[ireliawdefense]then
		local seg = gpred.linear.get_prediction(script.w, target)
		if seg and lTraceFilter(seg, target, script.w) then
			if not gpred.collision.get_prediction(script.r, seg, target) then
				player:castSpell("release", 3, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end
		end
	end
end

function RaySetDist(start, path, center, dist)
	local a = start.x - center.x
	local b = start.y - center.y
	local c = start.z - center.z
	local x = path.x
	local y = path.y
	local z = path.z
	
	local n1 = a*x+ b*y+ c*z
	local n2 = z^2*dist^2-a^2*z^2-b^2*z^2+2*a*c*x*z+2*b*c*y*z+2*a*b*x*y+dist^2*x^2+dist^2*y^2-a^2*y^2-b^2*x^2-c^2*x^2-c^2*y^2
	local n3 = x^2+y^2+z^2
	
	local r1 = -(n1+math.sqrt(n2))/n3
	local r2= -(n1-math.sqrt(n2))/n3
	local r = math.max(r1,r2)
	
	return start + r*path
		
end

function script.CastE1(target) 
	if player:spellSlot(2).state == 0 then
		if not target.path.isActive then
			if target.pos:dist(player.pos) <= script.e.range then
				local cast1 = player.pos + (target.pos-player.pos):norm()*script.e.range
				player:castSpell("pos", 2, cast1)
				script.e_parameters.e1Pos = cast1
				script.e_parameters.target2 = target
				script.e_parameters.nextCast = os.clock() + 0.25
			end
		else
			local pathStartPos = target.path.point[0]
			local pathEndPos = target.path.point[target.path.count]
			local pathNorm = (pathEndPos - pathStartPos):norm()
			local seg = gpred.circular.get_prediction(script.e_faux, target)
			if seg then

				local tempPred = vec3(seg.endPos.x, target.pos.y, seg.endPos.y)
				local dist1 = player.pos:dist(tempPred)
				if dist1 <= script.e.range then
					local dist2 = player.pos:dist(target.pos)
					if dist1<dist2 then
						pathNorm = pathNorm*-1
					end
					local cast2 = RaySetDist(target.pos, pathNorm, player.pos, script.e.range)
					player:castSpell("pos", 2, cast2)
					script.e_parameters.e1Pos = cast2
					script.e_parameters.nextCast = os.clock() + 0.25
				end
			end
		end
	end
end

function script.CastE2(target)
	if player:spellSlot(2).state == 0 then --delay e for now
		script.e.delay = 0.5
		local seg1 = gpred.circular.get_prediction(script.e, target)
		local predPos1 = vec2(seg1.endPos.x, seg1.endPos.y)
		local predPos3D = vec3(seg1.endPos.x, target.pos.y, seg1.endPos.y)
		if seg1 and player.pos2D:dist(predPos1)<=script.e.range then
			local e1Pos2D = vec2(script.e_parameters.e1Pos.x, script.e_parameters.e1Pos.y)
			local tempCastPos = mathf.closest_vec_line(player.pos2D, e1Pos2D, predPos1)
			local tempCastPos3D = vec3(tempCastPos.x, target.pos.y, tempCastPos.y)
			if tempCastPos3D:dist(player.pos)>script.e.range or predPos3D:dist(script.e_parameters.e1Pos) > tempCastPos3D:dist(script.e_parameters.e1Pos) then 
				player:castSpell("pos", 2, predPos3D)
			end
			script.e.delay = script.e.delay + (player.pos:dist(tempCastPos3D)-player.pos:dist(predPos3D))/script.e.speed
			local seg2 = gpred.circular.get_prediction(script.e, target)
			local predPos2 = vec2(seg2.endPos.x, seg2.endPos.y)
			predPos3D = vec3(seg2.endPos.x, target.pos.y, seg2.endPos.y)
			if seg2 and cTraceFilter(seg2, target,script.e) then
				local castPos = mathf.closest_vec_line(player.pos2D, e1Pos2D, predPos2)
				local castPos3D = vec3(castPos.x, target.pos.y, castPos.y)
				if castPos3D:dist(player.pos)>script.e.range or predPos3D:dist(script.e_parameters.e1Pos) > castPos3D:dist(script.e_parameters.e1Pos) then 
					player:castSpell("pos", 2, predPos3D)
				end
				player:castSpell("pos", 2, castPos3D)
				script.e_parameters.e1Pos = vec3(0,0,0)
				script.e_parameters.nextCast = os.clock() + 0.25
			end
		end
	end
end

function script.CastR(target)
	if player:spellSlot(3).state == 0  then
		local seg = gpred.linear.get_prediction(script.r, target)
		if seg and lTraceFilter(seg, target, script.r) then
			if not gpred.collision.get_prediction(script.r, seg, target) then
				player:castSpell("pos", 3, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end
		end
	end
end

local TargetSelectionNearMouse = function(res, obj, dist)
	if dist < 2000 and obj.pos:dist(game.mousePos) <= script.menu.searchrange:get() then --add mouse check
	  res.obj = obj
	  return true
	end
end

local TargetSelection = function(res, obj, dist)
	if dist < 2000 then 
	  res.obj = obj
	  return true
	end
end

local function OnTick()
	local target = ts.get_result(TargetSelectionNearMouse).obj
	local target2 = ts.get_result(TargetSelection).obj
	local bestQ = nil
	
	if target and common.IsValidTarget(target) then
		if orb.menu.combat:get() then	
			if target.buff["ireliamark"] or CanKS(target) then 
				script.CastQ(target)
			else
				if os.clock() >= script.e_parameters.nextCast then
					if script.e_parameters.e1Pos == vec3(0,0,0) then 
						script.CastE1(target)
					else
						script.CastE2(target)
					end
				end
			end
			
			if player.pos:dist(target.pos) > player.attackRange + 100 then 
				bestQ = GetBestQ(target.pos)
			end
		end
		
		if script.menu.r:get() then
			script.CastR(target)
		end
		
	else 
		if orb.menu.combat:get() then
			bestQ = GetBestQ(game.mousePos)	
		end
	end
	
	
	
	if orb.menu.combat:get() then
		if bestQ ~= nil then
			script.CastQ(bestQ)
		end
		if not target and target2 then
			if os.clock() >= script.e_parameters.nextCast and script.e_parameters.e1Pos~= vec3(0,0,0) then
				script.CastE2(target2)
			end
		end
	end
end

local function OnMissile(missile)
	
end

local function CreateObj(object)
	if object.name == "Blade" then 
		script.e_obj = object
		script.e_parameters.e1Pos = object.pos
	end
end

local function DeleteObj(object)
	if object.name == "Blade" or object.name == "IreliaESecondary" then
		script.e_obj = nil
		script.e_parameters.e1Pos = vec3(0,0,0)
	end
end

local function OnUpdateBuff(buff)
end

local function OnRemoveBuff(buff)
	if buff.owner.ptr == player.ptr and buff.name == "sheen" then
		sheenTimer = os.clock() + 1.7
	end
end

	
local function OnDraw()
	graphics.draw_circle(game.mousePos, script.menu.searchrange:get(), 1, graphics.argb(255, 255, 255, 255), 50)
	if script.e_parameters.e1Pos ~= vec3(0,0,0) then
		graphics.draw_circle(script.e_parameters.e1Pos, 50, 1, graphics.argb(255, 255, 255, 255), 50)
	end
	--[[if script.e_obj ~= nil then
		graphics.draw_circle(script.e_obj, 50, 1, graphics.argb(255, 255, 255, 255), 50)
	end]]
end

cb.add(cb.updatebuff, OnUpdateBuff)
cb.add(cb.removebuff, OnRemoveBuff)
cb.add(cb.createobj, CreateObj)
cb.add(cb.deleteobj, DeleteObj)
cb.add(cb.missile, OnMissile)
cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)

print("Irelia loaded")