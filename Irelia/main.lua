local script = {}
script.name = "Irelia"
script.developer = "asdf"
script.version = 2.1

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

script.w = {
	delay = 0.25, 
	width = 120, 
	speed = math.huge, 
	boundingRadiusMod = 0, 
	range = 825
} 

script.e_parameters = {
	e1Pos = vec3(0,0,0),
	target2 = nil,
	nextCast = os.clock(),
	missileSpeed = 2000,
	delayFloor = 0.5
}
	
script.e = {
	delay = script.e_parameters.delayFloor, 
	width =70, --originally 70 
	speed = math.huge, 
	boundingRadiusMod = 1,
	range = 900
}

	
script.e_obj = nil


script.r = {
	delay = 0.4,
	width = 100, --originally 160
	speed = 2000, 
	boundingRadiusMod = 0, 
	collision = {hero = true, minion = false}, 
	range = 700
}

script.debug = {
	e1Pos = vec3(0,0,0),
	e2Pred = vec3(0,0,0),
	closest = vec3(0,0,0),
	e2Cast = vec3(0,0,0),
	targetPosAtCast = vec3(0,0,0),
	targetPathEnd = vec3(0,0,0),
}
	
script.interruptSpells = { --add jhin ult
	"caitlynaceinthehole", 
	"drain", 
	"crowstorm", 
	"karthusfallenone", 
	"katarinar", 
	"malzaharr", 
	"meditate",
	"missfortunebullettime", 
	"absolutezero", 
	"shenr", 
	"gate", 
	"warwickr",
	"sionq"
}

script.dispelSpells = {
	"vladimirhemoplaguedebuff",
	"tristanaechargesound",
	"karmaspiritbind",
	"karthusfallenone",
	"leblancsoulshackle",
	"leblancsoulshacklem",
	"soulshackles",
	"zedultexecute",
	"fizzmarinerdoombomb",
}

--spells only dodged in combat
script.lowPrioritySpells = {

}

--CC and high dmg ultimates
script.highPrioritySpells = {

}


passiveBaseScale = {2.5, 2,5, 3.5, 3.5, 4.5, 4.5, 5.5, 5.5, 6,5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5, 14.5, 15.5, 16.5}
passiveADScale = {2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4}
PTAScale = { 0.08, 0.08, 0.08, 0.09, 0.09, 0.09, 0.09, 0.10, 0.10, 0.10, 0.10, 0.11, 0.11, 0.11, 0.11, 0.12, 0.12, 0.12 }
sheenTimer = os.clock()

script.menu = menu("ireliamenu", script.name)
	ts.load_to_menu(script.menu)
	script.menu:keybind("r", "Semi-manual R", "Z", nil)
	script.menu:keybind("e", "Semi-manual E", "T", nil)
	script.menu:slider("erange", "E Range", 500, 0, 900, 1)
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
		local passiveTotalDmg = common.GetTotalAD() * passiveADScale[player.levelRef] / 100
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
	
local function TraceFilter(seg, obj, spell, slow)
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
	
	if not slow then
		return true
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
		if seg and TraceFilter(seg, target, script.w, false) then
			player:castSpell("release", 3, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			
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
			local tempPred = common.GetPredictedPos(target, 1)
			
			if tempPred then
				local dist1 = player.pos:dist(tempPred)
				if dist1 <= script.e.range then
					local dist2 = player.pos:dist(target.pos)					
					if dist1<dist2 then
						pathNorm = pathNorm*-1
					end
					local enough = false
					local cast2 = RaySetDist(target.pos, pathNorm, player.pos, script.e.range)
					
					if target.pos:dist(cast2) >= target.moveSpeed * script.e_parameters.delayFloor*1.5 then
						enough = true						
					else
						cast2 = RaySetDist(target.pos, -1*pathNorm, player.pos, script.e.range)
						if target.pos:dist(cast2) >= target.moveSpeed * script.e_parameters.delayFloor*1.5 then
							enough = true
						end
					end
					
					if enough then
						player:castSpell("pos", 2, cast2)
						script.e_parameters.e1Pos = cast2
						script.e_parameters.nextCast = os.clock() + 0.25
						script.e_parameters.target2 = target
					end
				end
			end
		end
	end
end

function script.MultiE1(target, nextTarget) 
	if player:spellSlot(2).state == 0 then
		local target1Pos = common.GetPredictedPos(target, 1.25)
		local target2Pos = common.GetPredictedPos(nextTarget, 1.25)
		if target1Pos and target2Pos and player.pos:dist(target1Pos) <= script.e.range and player.pos:dist(target2Pos) < script.e.range then
			local pathNorm = (target1Pos - target2Pos):norm()
			local castPos = RaySetDist(target1Pos, pathNorm, player.pos, script.e.range)
			player:castSpell("pos", 2, castPos)
			script.e_parameters.e1Pos = castPos
			script.e_parameters.nextCast = os.clock() + 0.25
			script.e_parameters.target2 = nextTarget
		end
	end
end

function setDebug(target, e2Cast, e2Pred, closest)
	script.debug.e1Pos = script.e_parameters.e1Pos*1
	script.debug.targetPosAtCast = target.pos*1
	script.debug.targetPathEnd = target.path.point[target.path.count]*1
	script.debug.e2Cast = e2Cast
	script.debug.e2Pred = e2Pred
	script.debug.closest = closest
end

function resetE()
	script.e_parameters.e1Pos = vec3(0,0,0)
	script.e_parameters.target2 = nil
	script.e_parameters.nextCast = os.clock() + 0.25
end

function script.CastE2(target)
	if player:spellSlot(2).state == 0 then
	local castMode = 0
		if target.path.isActive and target.path.isDashing then
			local dashPos = gpred.core.project(player.path.serverPos2D, target.path, network.latency + script.e_parameters.delayFloor,script.e_parameters.missileSpeed, target.path.dashSpeed)
			if dashPos and player.pos2D:dist(dashPos) <= script.e.range then
				player:castSpell("pos", 2, vec3(dashPos.x, target.pos.y, dashPos.y))
				setDebug(target, vec3(dashPos.x, target.pos.y, dashPos.y)*1, vec3(dashPos.x, target.pos.y, dashPos.y)*1,vec3(0,0,0))
				resetE()
				print ("5")
			end
			
		else
			if not target.path.isActive then
				local inActive = script.e_parameters.e1Pos + (target.pos-script.e_parameters.e1Pos):norm()*(target.pos:dist(script.e_parameters.e1Pos)+target.moveSpeed*script.e_parameters.delayFloor*2)
				if target.pos:dist(player.pos) < script.e.range then 
					player:castSpell("pos", 2, inActive)
					setDebug(target, inActive*1,target.pos*1, vec3(0,0,0))
					resetE()
					print ("6")
				end
				
			else
				local short1 = false
				local short2 = false
				script.e.delay = script.e_parameters.delayFloor + player.pos:dist(target.pos)/script.e_parameters.missileSpeed
				local seg1 = gpred.linear.get_prediction(script.e, target, vec2(script.e_parameters.e1Pos.x,script.e_parameters.e1Pos.y ))
				--local tempPos = vec3(seg1.endPos.x, target.pos.y, seg1.endPos.y)
				--local predPos3D1 = script.e_parameters.e1Pos:lerp(tempPos,(tempPos:dist(script.e_parameters.e1Pos)+script.e.radius)/tempPos:dist(script.e_parameters.e1Pos))
				local predPos3D1 = vec3(seg1.endPos.x, target.pos.y, seg1.endPos.y)
				local predPos1 = vec2(seg1.endPos.x, seg1.endPos.y)
				
				if seg1 and player.pos2D:dist(predPos1)<=script.e.range then
					if gpred.trace.linear.hardlock(script.e, seg1, target) or gpred.trace.linear.hardlockmove(script.e, seg1, target) then
						player:castSpell("pos", 2, predPos3D1)
						setDebug(target, predPos3D1*1,target.pos*1, vec3(0,0,0))
						resetE()
						print("4")
					end
					local e1Pos2D = vec2(script.e_parameters.e1Pos.x, script.e_parameters.e1Pos.z)
					local tempCastPos = mathf.closest_vec_line(player.pos2D, e1Pos2D, predPos1)
					local tempCastPos3D = vec3(tempCastPos.x, target.pos.y, tempCastPos.y)
					if tempCastPos3D:dist(player.pos)>script.e.range or predPos3D1:dist(script.e_parameters.e1Pos) > tempCastPos3D:dist(script.e_parameters.e1Pos) or tempCastPos3D:dist(script.e_parameters.e1Pos) < target.moveSpeed*script.e_parameters.delayFloor*1.5 then 
						--tempCastPos3D = vec3(predPos1.x, target.pos.y, predPos1.y)
						short1 = true
						local pathNorm = (predPos3D1-script.e_parameters.e1Pos):norm()
						local extendPos = script.e_parameters.e1Pos + pathNorm*(predPos3D1:dist(script.e_parameters.e1Pos)+target.moveSpeed*script.e_parameters.delayFloor*1.5)
						if player.pos:dist(extendPos)<script.e.range then
							tempCastPos3D = extendPos
						else
							tempCastPos3D = RaySetDist(script.e_parameters.e1Pos, pathNorm, player.pos, script.e.range)
						end
					end
					
					if tempCastPos3D then
						script.e.delay = script.e_parameters.delayFloor + player.pos:dist(tempCastPos3D)/script.e_parameters.missileSpeed
						local seg2 = gpred.linear.get_prediction(script.e, target, vec2(script.e_parameters.e1Pos.x,script.e_parameters.e1Pos.y ))
						local predPos3D2 = vec3(seg2.endPos.x, target.pos.y, seg2.endPos.y)
						--tempPos = vec3(seg2.endPos.x, target.pos.y, seg2.endPos.y)
						--local predPos3D2 = script.e_parameters.e1Pos:lerp(tempPos,(tempPos:dist(script.e_parameters.e1Pos)+script.e.radius)/tempPos:dist(script.e_parameters.e1Pos))
						local predPos2 = vec2(seg2.endPos.x, seg2.endPos.y)
						
						if seg2 and TraceFilter(seg2, target,script.e, true) then
							local castPos = mathf.closest_vec_line(player.pos2D, e1Pos2D, predPos2)
							local castPos3D = vec3(castPos.x, target.pos.y, castPos.y)
							
							if castPos3D:dist(player.pos)>script.e.range or predPos3D2:dist(script.e_parameters.e1Pos) > castPos3D:dist(script.e_parameters.e1Pos) or castPos3D:dist(script.e_parameters.e1Pos) <target.moveSpeed*script.e_parameters.delayFloor*1.5 then 
								--castPos3D = predPos3D2
								short2 = true
								--temp code
								pathNorm = (predPos3D2-script.e_parameters.e1Pos):norm()
								extendPos = script.e_parameters.e1Pos + pathNorm*(predPos3D2:dist(script.e_parameters.e1Pos)+target.moveSpeed*script.e_parameters.delayFloor*1.5)
								if player.pos:dist(extendPos)<script.e.range then
									castPos3D = extendPos
									castMode = 1
								else
									castPos3D = RaySetDist(script.e_parameters.e1Pos, pathNorm, player.pos, script.e.range)
									castMode = 2
								end
							else 
								castMode = 3
							end
							if short1 == short2 then
								player:castSpell("pos", 2, castPos3D)
								setDebug(target, castPos3D*1,predPos3D2*1, vec3(tempCastPos.x, target.pos.y, tempCastPos.y))
								resetE()
								print (castMode)
							end
						end
					end
				end
			end
		end
	end
end

function script.CastR(target)
	if player:spellSlot(3).state == 0  then
		local seg = gpred.linear.get_prediction(script.r, target)
		if seg and TraceFilter(seg, target, script.r, false) then
			if not gpred.collision.get_prediction(script.r, seg, target) then
				player:castSpell("pos", 3, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end
		end
	end
end

function script.AutoInterrupt(spell)
	if player:spellSlot(2).state == 0 and script.e_parameters.e1Pos == vec3(0,0,0) then
		if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
			for i, interruptable in pairs(script.interruptSpells) do 
				if string.lower(spell.name) == interruptable and common.IsValidTarget(spell.owner) and player.pos:dist(spell.owner.pos) <= script.e.range then
					script.CastE1(spell.owner)
				end
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
	if dist <= script.e.range then	
		targetNearMouse = ts.get_result(TargetSelectionNearMouse).obj
		if targetNearMouse and obj ~= targetNearMouse then
			res.obj = obj
			return true
		end
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
	end
	
	if os.clock() >= script.e_parameters.nextCast then 
		if script.e_parameters.e1Pos == vec3(0,0,0) and player:spellSlot(2).name == "IreliaE" then 
			if target and (not target.buff["ireliamark"] or CanKS(target)) then
				if target2 then
					if orb.menu.combat:get() or script.menu.e:get() then
						script.MultiE1(target2,target)
					end
				else
					if (orb.menu.combat:get() and ((bestQ ~= nil and bestQ.pos:dist(target.pos) < script.menu.erange:get()) or (bestQ == nil and player.pos:dist(target.pos) < script.menu.erange:get()))) or script.menu.e:get() then
						script.CastE1(target)
					end
				end
			else 
				if target2 and script.menu.e:get() and (not target2.buff["ireliamark"] or CanKS(target2)) then
					script.CastE1(target2)
				end
			end	
		else
			if orb.menu.combat:get() or script.menu.e:get() then
				if common.IsValidTarget(script.e_parameters.target2) and player.pos:dist(script.e_parameters.target2.pos)<=script.e.range then
					if script.e_parameters.target2.buff["ireliamark"] or not CanKS(script.e_parameters.target2) then
						script.CastE2(script.e_parameters.target2)
					end
				else
					if target then
						if  target.buff["ireliamark"] or not  CanKS(target) then
							script.CastE2(target)
						end
					else 
						if target2 then
							if target2.buff["ireliamark"] or not CanKS(target2) then
								script.CastE2(target2)
							end
						end
					end
				end
			end
		end
	end
end


local function OnSpell(spell)
	script.AutoInterrupt(spell)
end

local function CreateObj(object)
	if object.name == "Blade" and object.team == TEAM_ALLY then 
		script.e_obj = object
		script.e_parameters.e1Pos = object.pos
	end
end

local function DeleteObj(object)
	if object.name == "IreliaESecondary" and object.team == TEAM_ALLY then
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
	graphics.draw_circle(player.pos, script.e.range, 1, graphics.argb(255, 255, 255, 255), 50)

	if script.debug.e2Pred ~= vec3(0,0,0) then
		graphics.draw_circle(script.debug.e2Pred, 30, 1, graphics.argb(255, 0, 0, 255), 50)
	end
	
	if script.debug.e2Cast ~= vec3(0,0,0) and script.debug.e1Pos ~= vec3(0,0,0) then
		graphics.draw_circle(script.debug.e2Cast, 10, 1, graphics.argb(255, 0, 255, 0), 50)
		graphics.draw_circle(script.debug.e1Pos, 10, 1, graphics.argb(255, 0, 255, 0), 50)
		graphics.draw_line(script.debug.e1Pos, script.debug.e2Cast, 3, graphics.argb(255, 0, 255, 0))
	end
	
	if script.debug.closest ~= vec3(0,0,0) then
		graphics.draw_circle(script.debug.closest, 30, 1, graphics.argb(255, 255, 0, 0), 50)
	end
	
	if script.debug.targetPosAtCast ~= vec3(0,0,0) and script.debug.targetPathEnd ~= vec3(0,0,0) then
		graphics.draw_line(script.debug.targetPosAtCast, script.debug.targetPathEnd, 3, graphics.argb(255, 255, 255, 255))
		graphics.draw_circle(script.debug.targetPathEnd, 20, 1, graphics.argb(255, 255, 255, 255), 50)
	end
	
	if script.e_parameters.e1Pos ~= vec3(0,0,0) then
		graphics.draw_circle(script.e_parameters.e1Pos, 20, 1, graphics.argb(255, 255, 255, 255), 50)
	end
end

cb.add(cb.updatebuff, OnUpdateBuff)
cb.add(cb.removebuff, OnRemoveBuff)
cb.add(cb.createobj, CreateObj)
cb.add(cb.deleteobj, DeleteObj)
cb.add(cb.spell, OnSpell)
cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)

print("Irelia loaded")