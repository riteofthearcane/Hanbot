local script = {}
script.name = "Syndra"
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

color = graphics.argb(255, 255, 255, 255)
orbs = {}
q =  {
	type = 'circular',
	speed = math.huge,
	range = 800,
	delay = 0.625,
	radius = 200,
	boundingRadiusMod = 0,
	mana = {40, 50, 60, 70, 80}
}

qq = false


w = {
	type = 'circular',
	speed = 1450,
	range = 950,
	delay = 0.25,
	radius = 225,
	boundingRadiusMod = 0
}


eVar = {
	testSpeed = 2000,
	speed1 = 2500,
	speed2 = 2000,
	range = 700,
	QEdelay = 0.25,
	human = 0.05,
	EQdelay = 0.4,
	angle = 40
}

qe = {
	type = "linear",
	speed = 10,
	range = 1250,
	delay = eVar.QEdelay,
	width = 50,
	boundingRadiusMod = 1
}

WDelay = os.clock()

r = {
	damage = {90, 135, 180},
	range = 675,
}

interrupt = {
	"caitlynaceinthehole",
	"ezrealtrueshotbarrage",
	"drain",
	"crowstorm",
	"karthusfallenone",
	"katarinar",
	"lucianr",
	"luxmalicecannon",
	"malzaharr",
	"meditate",
	"missfortunebullettime",
	"absolutezero",
	"shenr",
	"gate",
	"warwickr",
	"sionq",
	"varusq",
	"jhinr",
	"pantheonrjump",
	"reapthewhirlwind",
	"xerathlocusofpower2",
}

menu = menu("syndra", script.name)
	menu:keybind("qe", "Stun Key", "Z", nil)
	menu:menu("useR", "Use R on")
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		menu.useR:boolean(enemy.charName, enemy.charName, true)
	end
	ts.load_to_menu(menu)

function toVec3(vec2)
	return vec3(vec2.x, game.mousePos.y, vec2.y)
end

function toVec2(vec3)
	return vec2(vec3.x, vec3.z)
end

function TraceFilter(spell, seg, obj, slow)
	if player.pos:dist(toVec3(seg.endPos)) > spell.range then
		return false
	end
	sloww = slow or false
	if spell.type == "circular" then
		if gpred.trace.circular.hardlock(spell, seg, obj) then
			return true
		end

		if gpred.trace.circular.hardlockmove(spell, seg, obj) then
			return true
		end
	end

	if spell.type == "linear" then
		if gpred.trace.linear.hardlock(spell, seg, obj) then
			return true
		end

		if gpred.trace.linear.hardlockmove(spell, seg, obj) then
			return true
		end
	end
	if not sloww then
		return true
	end
	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

function CastQ(target, slow)
	sloww = slow or false
	if player:spellSlot(0).state == 0 and not qq then
		local seg = gpred.circular.get_prediction(q, target)
		if seg and TraceFilter(q, seg, target, sloww) then
			player:castSpell("pos", 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
		end
	end
end

function GetGrabTarget()
	--annie and ivern
	lowTime = math.huge
	lowOrb = nil
	for i, j in pairs (orbs) do
		if j < lowTime and i.pos:dist(player.pos) <= w.range then
			lowTime = j
			lowOrb = i
		end
	end
	if lowOrb then
		return lowOrb
	end

	minionsInRange = common.GetMinionsInRange(w.range, TEAM_ENEMY)
	monstersInRange = common.GetMinionsInRange(w.range, TEAM_NEUTRAL)
	lowHealth = math.huge
	lowMinion = nil
	for _, minion in pairs(minionsInRange) do
		if minion then
			if minion.health < lowHealth then
				lowHealth = minion.health
				lowMinion = minion
			end
		end
	end
	for _, minion in pairs(monstersInRange) do
		if minion then
			if minion.health < lowHealth then
				lowHealth = minion.health
				lowMinion = minion
			end
		end
	end
	if lowMinion then
		return lowMinion
	end
end

function CastW1() --need to add range checks
	if player:spellSlot(1).state == 0 and player:spellSlot(1).name == "SyndraW" and os.clock() >= WDelay then
		enemiesInRange = common.GetEnemyHeroesInRange(w.range, player.pos)
		if #enemiesInRange >= 1 then
			target = GetGrabTarget()
			if target then
				player:castSpell("pos", 1, target.pos)
			end
		end
	end
end

function CastW2(target, sloww)
	sloww = slow or false
	if player:spellSlot(1).state == 0 and player:spellSlot(1).name == "SyndraWCast" and os.clock() >= WDelay then
		local seg = gpred.circular.get_prediction(w, target)
		if seg and TraceFilter(w, seg, target, sloww) then
			player:castSpell("pos", 1, toVec3(seg.endPos))
		end
	end
end

function QEMana()
	return 50 + q.mana[player:spellSlot(0).level]
end

function CalcQE(target, orbDist)
	orbDist = math.min(q.range, orbDist)
	qe.speed = eVar.testSpeed
	seg = gpred.linear.get_prediction(qe, target)
	if seg and TraceFilter(qe, seg, target) then
		startPos = toVec3(seg.startPos)
		endPos = toVec3(seg.endPos)
		dist = startPos:dist(endPos)
		qe.speed = (eVar.speed1 * (orbDist) + (dist - orbDist) * eVar.speed2)/ dist
		if dist >= orbDist then
			qe.delay = eVar.QEdelay
		else
			qe.delay = eVar.EQdelay
		end
	end
end

function CanEQ(qPos, predPos, target)
	--e orb check
	for orb in pairs(orbs) do
		if player.pos:dist(target.pos) >= player.pos:dist(orb.pos) and math.abs(mathf.angle_between(player.pos, orb.pos, qPos)*180/math.pi) <= eVar.angle / 2 + 5 then
			closest = mathf.closest_vec_line_seg(toVec2(predPos), player.pos2D, toVec2(qPos))
			if closest and toVec3(closest):dist(predPos) <= qe.width + target.boundingRadius + 15 then
				return false
			end
		end
	end
	--wall check
	interval = 50
	count = math.floor(predPos:dist(qPos)/ interval)
	diff = (qPos - player.pos):norm()
	for i = 0, count do
		pos = predPos + diff * i * interval
		if navmesh.isWall(pos) then
			return false
		end
	end
	--cc check
	if target.buff[5] or target.buff[8] or target.buff[24] or target.buff[11] or target.buff[22] or target.buff[8] or target.buff[21] then
		return false
	end
	return true
end

function StunQE(pos1, pos2)
	player:castSpell("pos", 0, pos1)
	common.DelayAction(function(pos)
		player:castSpell("pos", 2, pos)
	end,
	eVar.human, {pos2})
end

function StunEQ(pos1, pos2)
	player:castSpell("pos", 2, pos2)
	qq = true
	common.DelayAction(function(pos)
		player:castSpell("pos", 0, pos)
		qq = false
	end,
	eVar.EQCastDelay, {pos1})
end

function QE(startPos, endPos, target)
	if player.mana < QEMana() then
		return
	end
	dist = startPos:dist(endPos)
	qPos = startPos:lerp(endPos, (q.range-75) / startPos:dist(endPos))
	if dist >= q.range - 75 then
		if qe.delay == eVar.QEdelay then
			StunQE(qPos, endPos)
		end
	else
		if CanEQ(qPos, endPos, target) and qe.delay == eVar.EQdelay then
			StunEQ(qPos, endPos)
		end
	end
	WDelay = os.clock() + 0.5
end

function CastQE(target, sloww)
	if player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and player.mana >= QEMana() and player.pos:dist(target.pos) >= 150 then
		CalcQE(target, q.range - 75)
		seg = gpred.linear.get_prediction(qe, target)
		if seg and TraceFilter(qe, seg, target, true) then
			startPos = vec3(seg.startPos.x, target.pos.y, seg.startPos.y)
			endPos = vec3(seg.endPos.x, target.pos.y, seg.endPos.y)
			QE(startPos, endPos, target)
		end
	end
end


function Interrupt(spell)
	if player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 then
		if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
			for _, sp in pairs(interrupt) do
				if string.lower(spell.name) == sp and common.IsValidTarget(spell.owner) and player.pos:dist(spell.owner.pos) <= qe.range then
					CastQE(target)
				end
			end
		end
	end
end

function QEKey()
	enemiesInRange = common.GetEnemyHeroesInRange(qe.range, player.pos)
	closest = nil
	closestRange = math.huge
	for _, enemy in pairs(enemiesInRange) do
		dist = game.mousePos:dist(enemy)
		if dist < closestRange and common.IsValidTarget(enemy) then
			closestRange = dist
			closest = enemy
		end
	end
	if closest then
		CastQE(closest)
	end
end

function CastE(target)
	if player:spellSlot(2).state == 0 then
		if common.IsValidTarget(target) then
			for orb in pairs(orbs) do
				if player.pos:dist(orb.pos) <= q.range then
					CalcQE(target, player.pos:dist(orb.pos))
					seg = gpred.linear.get_prediction(qe, target)
					if seg and TraceFilter(qe, seg, target) then
						endPos = vec3(seg.endPos.x, target.pos.y, seg.endPos.y)
						diff = (orb.pos - player.pos):norm()
						extendPos = player.pos + diff * qe.range
						closest = mathf.closest_vec_line_seg(toVec2(endPos), player.pos2D, toVec2(extendPos))
						if closest and toVec3(closest):dist(endPos) <= qe.width + target.boundingRadius then
							player:castSpell('pos', 2, orb.pos)
							return
						end
					end
				end
			end
		end
	end
end

function GetRDamage(target)
	damage = math.max(player:spellSlot(3).stacks, 3) * (r.damage[player:spellSlot(3).level]+ 0.2 * common.GetTotalAP(player))
	return common.CalculateMagicDamage(target, damage, player)
end

function RConditions(target)
	if target.pos:dist(player.pos) > r.range then
		return false
	end
	if common.GetPercentHealth(player) <= common.GetPercentHealth(target) then
		return true
	end
	if common.GetPercentHealth(player) <= 0.15 then
		return true
	end
	if common.GetShieldedHealth("AP", target) <= GetRDamage(target) / player:spellSlot(3).stacks * 2 then
		return false
	end
	enemiesInRange1 = common.GetEnemyHeroesInRange(400, player.pos)
	enemiesInRange2 = common.GetEnemyHeroesInRange(2500, player.pos)
	alliesInRange = common.GetAllyHeroesInRange(400, target.pos)
	if #enemiesInRange1 > #alliesInRange then
		return true
	end

	if player.mana < 200 then
		return true
	end

	if target.spellBlock < 50 then
		return true
	end

	if #enemiesInRange2 <= 2 then
		return true
	end

end

function CastR(target)
	if player:spellSlot(3).state == 0 then

		if menu.useR[target.charName]:get() and GetRDamage(target) >= common.GetShieldedHealth("AP", target) and RConditions(target) then
			player:castSpell('obj', 3, target)
		end
	end
end

function TargetSelection(res, obj, dist)
    if dist < qe.range then
      res.obj = obj
      return true
    end
end


function OnTick()
	for i, j in pairs(orbs) do
		if not i or i.isDead or os.clock() >= j then
			orbs[i] = nil
		end
	end
	local target = ts.get_result(TargetSelection).obj
	if target then
		if orb.menu.combat.key:get() then
			enemiesInRange = common.GetEnemyHeroesInRange(qe.range, player.pos)
			for _, enemy in pairs(enemiesInRange) do
				CastR(enemy)
				CastE(enemy)
			end
			CastW2(target, true)
			CastQE(target)
			CastW1()
			CastQ(target, true)
		end
		if orb.menu.hybrid.key:get() then
			CastQ(target, true)
		end
	end
	if menu.qe:get() then
		QEKey()
	end

end

function CreateObj(obj)
	if obj.name == "Seed" and obj.team == TEAM_ALLY then
		orbs[obj] = os.clock() + 6
	end
	if obj.name == "Syndra_Base_W_heldTarget_buf_02" then
		for orb in pairs (orbs) do
			if orb.pos:dist(obj.pos) < 55 then
				orbs[orb] = os.clock() + 6
			end
		end
	end
end

function DeleteObj(obj)
	if obj.name == "Seed" and obj.team == TEAM_ALLY then
		orbs[obj] = nil
	end
end

function OnSpell(spell)
	Interrupt(spell)
	if spell.name == "SyndraE" then
		startT = os.clock()
	end
end

function OnDraw()
	for orb in pairs(orbs) do
		graphics.draw_circle(orb.pos, 35, 1, graphics.argb(255, 255, 255, 255), 50)
	end

	graphics.draw_circle(player.pos, q.range, 1, graphics.argb(255, 255, 255, 255), 50)
	graphics.draw_circle(player.pos, qe.range, 1, graphics.argb(255, 255, 255, 255), 50)

end

cb.add(cb.tick, OnTick)
cb.add(cb.spell, OnSpell)
cb.add(cb.draw, OnDraw)
cb.add(cb.createobj, CreateObj)
cb.add(cb.deleteobj, DeleteObj)


print("Syndra loaded")
