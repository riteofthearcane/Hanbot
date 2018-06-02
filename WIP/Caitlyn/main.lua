local avada_lib = module.lib('avada_lib')
if not avada_lib or avada_lib.version < 1 then
	print("You need Avada Lib to run Caitlyn")
end

local common = avada_lib.common
local ts = module.internal('TS')
local orb = module.internal("orb")
local gpred = module.internal("pred")


q = {delay = 0.625, width = 90, speed = 2200, boundingRadiusMod = 1, collision = {hero = true, minion = false}, range = 1250}
w = {delay = 0.5, radius = 67.5, speed = math.huge, boundingRadiusMod = 1, range = 800}
e = {delay = 0.25, radius = 60, speed = 1500, boundingRadiusMod = 1, collision = {hero = true, minion = true}, range = 750}
e1 = {delay = 0.25, radius = 0.1, speed = 1500, boundingRadiusMod = 0, collision = {hero = true, minion = true}, range = 750}

color = graphics.argb(255, 255, 255, 255)

menu = menu("caitlyn", "Caitlyn")
	menu:keybind("e", "Semi manual E", "Z", nil)
	menu:slider("search", "E Search Angle", 45, 0, 180, 1)
	ts.load_to_menu(menu)
	

function toVec3(vec2)
	return vec2 and vec3(vec2.x, game.mousePos.y, vec2.y) or nil
end

function toVec2(vec3)
	return vec3 and vec2(vec3.x, vec3.z) or nil
end

function TraceFilter(spell, seg, obj, slow)
	sloww = slow or false
	if gpred.trace.linear.hardlock(spell, seg, obj) then
		return true
	end

	if gpred.trace.linear.hardlockmove(spell, seg, obj) then
		return true
	end
	if player.pos:dist(toVec3(seg.endPos)) > spell.range then
		return false
	end
	if not sloww then
		return true
	end
	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

function CastQ(target, collision)
	if player:spellSlot(0).state == 0  then
		local seg = gpred.linear.get_prediction(q, target)
		if seg and TraceFilter(q, seg, target, true) then
			if (collision and gpred.collision.get_prediction(q, seg, target)) or not collision then
				player:castSpell("pos", 0, toVec3(seg.endPos))
			end
		end
	end
end

function CastW(target)
	if player:spellSlot(1).state == 0  then
		local seg = gpred.circular.get_prediction(w, target)
		if seg and player.pos:dist(toVec3(seg.endPos)) < w.range  then
			player:castSpell("pos", 1, toVec3(seg.endPos))
		end
	end
end

function AntiGap()
	if player:spellSlot(1).state == 0  then
		enemiesInRange = common.GetEnemyHeroesInRange(w.range, player.pos)
		for _, enemy in pairs(enemiesInRange) do
			if enemy.path.isActive and enemy.path.isDashing then
				predPos = gpred.core.project(player.path.serverPos2D, enemy.path, network.latency + w.delay, w.speed, enemy.path.dashSpeed)
				if predPos and player.pos2D:dist(predPos) <= w.range then
					player:castSpell("pos", 1, toVec3(predPos))
				end
			end
		end
	end
end


function EPos(target, noWidth)
	spell = noWidth and e1 or e
	if player:spellSlot(2).state == 0  then
		local seg = gpred.linear.get_prediction(spell, target)
		if seg and TraceFilter(spell, seg, target) then
			if not gpred.collision.get_prediction(spell, seg, target) then
				return toVec3(seg.endPos)
			end
		end
	end
end

function CastManualE()

end

TargetSelection = function(res, obj, dist)
    if dist < 2000 then
      res.obj = obj
      return true
    end
end

function Main()
	target = ts.get_result(TargetSelection).obj
	if orb.menu.combat:get() then
		for i=0, objManager.enemies_n - 1 do
			enemy = objManager.enemies[i]
			if enemy.buff["caitlynyordletrapinternal"] and player.pos:dist(enemy.pos)<=player.attackRange + 700 then
				player:attack(enemy)
			end
		end
		if target and player.pos:dist(target.pos) >= player.attackRange + 50 then
			enemiesInRange1 = common.GetEnemyHeroesInRange(player.attackRange, player.pos)
			if #enemiesInRange1 == 0 then
				CastQ(target)
			end
		else
			enemiesInRange2 = common.GetEnemyHeroesInRange(q.range, player.pos)
			for _, enemy in pairs(enemiesInRange2) do
				CastQ(enemy, true)
				if (enemy.buff[5] or enemy.buff[8] or enemy.buff[24] or enemy.buff[11] or enemy.buff[22] or enemy.buff[8] or enemy.buff[21]) and player:spellSlot(1).state ~= 0  then
					CastQ(enemy)
				end	
			end
		end
	end
	if target and orb.menu.hybrid:get() then
		CastQ(target)
	end
	
end

function OnTick()
	AntiGap()
	if menu.e:get()  then
		CastManualE()
	end
	enemiesInRange = common.GetEnemyHeroesInRange(w.range, player.pos)
	for _, enemy in pairs(enemiesInRange) do
		if (enemy.buff[5] or enemy.buff[8] or enemy.buff[24] or enemy.buff[11] or enemy.buff[22] or enemy.buff[8] or enemy.buff[21]) then
			CastW(enemy)
		end	
	end
end



function OnDraw()
	-- castPos = player.pos:lerp(game.mousePos,-1)
	-- graphics.draw_circle(castPos, 100, 1, color, 50)
	--graphics.draw_line(player.pos, player.pos + vec3(1000,game.mousePos.y, 0), 2, color)
	enemiesInRange = common.GetEnemyHeroesInRange(e.range, player.pos)
	angle = mathf.angle_between(player.pos2D, toVec2(game.mousePos), (player.pos2D + vec2(10,0)))*180/math.pi
	if angle then
		high = angle + menu.search:get()/2
		low = angle - menu.search:get()/2
		if high > 180 then 
			high = high - 360
		end
		if low < -180 then
			low = 360 + low
		end
		high = high * math.pi / 180
		low = low * math.pi / 180
		highLinePos = player.pos - toVec3(vec2(-mathf.cos(high), mathf.sin(high)):norm() * e.range)
		lowLinePos = player.pos - toVec3(vec2(-mathf.cos(low), mathf.sin(low)):norm() * e.range)
		graphics.draw_line(highLinePos, player.pos, 2, color)
		graphics.draw_line(lowLinePos, player.pos, 2, color)
	end
	for _, enemy in pairs(enemiesInRange) do
		-- graphics.draw_line(castPos, player.pos, 2, color)
		-- graphics.draw_line(player.pos, enemy.pos, 2, color)
		-- angle = mathf.angle_between(castPos, player.pos, enemy.pos)
		-- graphics.draw_text_2D(tostring(angle*180/math.pi), 50, 1000, 500, color)
	end
end

cb.add(cb.tick, OnTick)
orb.combat.register_f_after_attack(Main)
orb.combat.register_f_out_of_range(Main)
cb.add(cb.draw, OnDraw)

print("Caitlyn loaded")
