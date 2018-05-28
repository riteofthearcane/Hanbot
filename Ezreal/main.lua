local avada_lib = module.lib('avada_lib')
if not avada_lib or avada_lib.version < 1 then
	print("You need Avada Lib to run Ezreal")
end

local common = avada_lib.common
local ts = module.internal('TS')
local orb = module.internal("orb")
local gpred = module.internal("pred")

q = {slot = 0, speed = 2000, range = 1150, delay = 0.25, width = 80, boundingRadiusMod = 1, collision = {hero = true, minion = true}}
w = {slot = 1, speed = 1550, range = 1000, delay = 0.25, width = 80, boundingRadiusMod = 1}
r = {slot = 3, speed = 2000, range = 25000, delay = 1, width = 160, boundingRadiusMod = 1}

searchRange = 3000
predPos = {}


menu = menu("ezreal", "Ezreal")
	menu:keybind("autoQ", "Auto Q", nil, "T")
	menu:keybind("r", "R Key", "Z", nil)
	ts.load_to_menu(menu)
	

function toVec3(vec2)
	return vec3(vec2.x, game.mousePos.y, vec2.y)
end

function toVec2(vec3)
	return vec2(vec3.x, vec3.z)
end

function TraceFilter(spell, seg, obj)
	dist = player.pos:dist(toVec3(seg.endPos))
	if dist > spell.range then
		return false
	end
	
	if gpred.trace.linear.hardlock(spell, seg, obj) then
		return true
	end

	if gpred.trace.linear.hardlockmove(spell, seg, obj) then
		return true
	end
	
	if dist < player.attackRange and spell ~= r then
		return true
	end

	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

function Cast(target, spell)
	if player:spellSlot(spell.slot).state == 0  then
		local seg = gpred.linear.get_prediction(spell, target)
		if seg and TraceFilter(spell, seg, target) then
			if not spell.collision or not gpred.collision.get_prediction(spell, seg, target) then
				player:castSpell("pos", spell.slot, toVec3(seg.endPos))
			end
		end
	end
end

function CastR()
	if not player:spellSlot(r.slot).state == 0 then
		return
	end
	
	targets = common.GetEnemyHeroesInRange(searchRange, player.pos)
	for _, target in pairs (targets) do
		if target.buff[5] or target.buff[8] or target.buff[24] or target.buff[11] or target.buff[22] or target.buff[8] or target.buff[21] then
			Cast(target, r)
			return 
		else
			seg = gpred.linear.get_prediction(r, target)
			if seg then
				predPos[target] = toVec3(seg.endPos)
			end
		end
	end
	
	maxHit = {target = nil, count = 0}
	for i, j in pairs(predPos) do 
		count = 0
		for k, l in pairs(predPos) do 
			if l == j then
				count = count + 1
			else
				closest = toVec3(mathf.closest_vec_line(toVec2(l), player.pos2D, toVec2(j)))
				if closest and closest:dist(j) < r.width + k.boundingRadius then
					count = count + 1
				end
			end
			if count > maxHit.count then
				maxHit.count = count
				maxHit.target = i
			end
		end
	end
	if maxHit.count >= 3 then 
		player:castSpell("pos", r.slot, predPos[maxHit.target])
	end
end

TargetSelection = function(res, obj, dist)
    if dist < q.range then
      res.obj = obj
      return true
    end
end

function Main()
	target = ts.get_result(TargetSelection).obj
	if orb.menu.combat:get() then
		if target then
			Cast(target, q)
			Cast(target, w)
		end
		CastR()
	end 
	if menu.autoQ:get() and target then
		Cast(target, q)
	end                               
end

function OnDraw()
	color = (not menu.autoQ:get() and graphics.argb(255, 255, 255, 255)) or (menu.autoQ:get() and graphics.argb(255, 255, 0, 0))
	graphics.draw_circle(player.pos, q.range, 1, color, 50)
end

orb.combat.register_f_after_attack(Main)
orb.combat.register_f_out_of_range(Main)
cb.add(cb.draw, OnDraw)


print("Ezreal loaded")
