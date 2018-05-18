local script = {}
script.name = "Caitlyn"
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

q = {delay = 0.625, width = 90, speed = 2200, boundingRadiusMod = 1, collision = {hero = true, minion = false}, range = 1250} 
w = {delay = 1, radius = 67.5, speed = math.huge, boundingRadiusMod = 0, range = 800} 
e = {delay = 0.25, radius = 60, speed = 1500, boundingRadiusMod = 1, collision = {hero = true, minion = true}, range = 750}
e1 = {delay = 0.25, radius = 0.1, speed = 1500, boundingRadiusMod = 0, collision = {hero = true, minion = true}, range = 750}

color = graphics.argb(255, 255, 255, 255) 

menu = menu("caitlynmenu", script.name)
	script.menu:keybind("e", "Semi manual E", "Z", nil)
	ts.load_to_menu(script.menu)
		
function TraceFilter(spell, seg, obj, slow)
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
	if not obj.path.isActive then
		if spell.range < seg.startPos:dist(obj.pos2D) + (obj.moveSpeed * 0.333) then
			return false
		end
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
				player:castSpell("pos", 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end 
		end
	end
end	


function CastE(target)
	if player:spellSlot(0).state == 0  then
		local seg = gpred.linear.get_prediction(e, target)
		if seg and TraceFilter(e, seg, target) then
			if not gpred.collision.get_prediction(e, seg, target) then
				player:castSpell("pos", 2, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end 
		end
	end
end	

function CastManualE()
	
end

local TargetSelection = function(res, obj, dist)
    if dist < 2000 then
      res.obj = obj
      return true
    end
end

local function OnTick()
	local target = ts.get_result(TargetSelection).obj
	if orb.menu.combat:get() then
		for i=0, objManager.enemies_n - 1 do
			enemy = objManager.enemies[i]
			if enemy.buff["caitlynyordletrapinternal"] and player.pos:dist(enemy.pos)<=player.attackRange + 700 then
				player:attack(enemy)
			end
		end
		if target and player.pos:dist(target.pos) >= player.attackRange + 50 then
			enemiesInRange = common.GetEnemyHeroesInRange(player.attackRange, player.pos)
			if #enemiesInRange == 0 then
				CastQ(target, false)
		else
			for i=0, objManager.enemies_n - 1 do 
				enemy = objManager.enemies[i]
				CastQ(enemy, true)
			end
		end
	end
	if target and orb.menu.hybrid:get() then
		CastQ(target, false)
	end
	if menu.e:get()  then			
		CastManualE()
	end
end

local function OnDraw()
	castPos = player.pos:lerp(game.mousePos,-1)
	graphics.draw_circle(castPos, 100, 1, color, 50)
	for i=0, objManager.enemies_n - 1 do 		
		enemy = objManager.enemies[i]
		if player.pos:dist(enemy.pos)<=e.range then
			graphics.draw_line(castPos, player.pos, 2, color)
			graphics.draw_line(player.pos, enemy.pos, 2, color)
			angle = mathf.angle_between(castPos, player.pos, enemy.pos)
			graphics.draw_text_2D(tostring(angle*180/math.pi), 50, 1000, 500, color)
		end
	end
end

local function OnUpdateBuff(buff)

end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.updatebuff, OnUpdateBuff)

print("Caitlyn loaded")