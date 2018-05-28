local avada_lib = module.lib('avada_lib')
if not avada_lib or avada_lib.version < 1 then
	print("You need Avada Lib to run Ezreal")
end

local common = avada_lib.common
local ts = module.internal('TS')
local orb = module.internal("orb")
local gpred = module.internal("pred")

q = {
	slot = 0,
	range = 600,
}

w = {
	speed = 1760,
	range = 2400, 
	delay = 0.4,
	width = 150, 
	collision = {
      hero = true,
      minion = true,
      wall = true,
    },
	boundingRadiusMod = 1
}

menu = menu("kaisa", "Kai'Sa")
	menu:dropdown("q", "Use Q when", 1, {"Always", "Enemy isolated", "Never"})
	menu:dropdown("w", "Use W when", 1, {"Always", "CC / out of range", "Never"})
	menu:slider("search", "W search range", 1200, 500, 3000, 100)
	ts.load_to_menu(menu)
	

function toVec3(vec2)
	return vec2 and vec3(vec2.x, game.mousePos.y, vec2.y) or nil
end


function CanW(seg, obj)
	dist = player.pos:dist(toVec3(seg.endPos))
	if dist > w.range then
		return false
	end
	
	if gpred.trace.linear.hardlock(spell, seg, obj) then
		return true
	end
	
	if gpred.trace.linear.hardlockmove(spell, seg, obj) then
		return true
	end
	
	if dist > menu.search:get() then
		return false
	end
	
	enemiesInRange = common.GetEnemyHeroesInRange(player.attackRange, player.pos)
	minionsInRange = common.GetMinionsInRange(300, TEAM_ENEMY, obj,pos)
	monstersInRange = common.GetMinionsInRange(300, TEAM_NEUTRAL, obj.pos)
	
	if dist > player.attackRange and #minionsInRange + #monstersInRange > 2  then
		return false
	end
	
	if menu.w:get() == 2 and #enemiesInRange ~= 0 then 
		return false
	end
	
	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end


function CastQ()
	if menu.q:get() == 3 or not orb.menu.combat:get() then
		return
	end
	if player:spellSlot(0).state == 0  then
		targets = common.GetEnemyHeroesInRange(q.range, player.pos)
		minionsInRange = common.GetMinionsInRange(q.range, TEAM_ENEMY)
		monstersInRange = common.GetMinionsInRange(q.range, TEAM_NEUTRAL)
		if #targets > 2 or (#targets == 1 and (#minionsInRange + #monstersInRange < 2 or menu.w:get() == 1)) then
			player:castSpell("self", 0)
		end
	end
end


function CastW(target)
	if menu.w:get() == 3 then
		return
	end
	if player:spellSlot(1).state == 0  then
		local seg = gpred.linear.get_prediction(w, target)
		if seg and CanW(seg, target) then
			if not gpred.collision.get_prediction(w, seg, target) then
				player:castSpell("pos", 1, toVec3(seg.endPos))
			end
		end
	end
end

TargetSelection = function(res, obj, dist)
    if dist < w.range then
      res.obj = obj
      return true
    end
end

function Main()
	target = ts.get_result(TargetSelection).obj
	if target and orb.menu.combat:get() then
		CastW(target)
	end
end

function OnUpdateBuff(buff)
	if buff.owner.ptr == player.ptr and buff.name == "KaisaE" then
		orb.core.set_pause_attack(math.huge)
	end
end

function OnRemoveBuff(buff)
	if buff.owner.ptr == player.ptr and buff.name == "KaisaE" then
		orb.core.set_pause_attack(0)
	end
end

function OnDraw()
	graphics.draw_circle(player.pos, menu.search:get(), 1, graphics.argb(255, 255, 255, 255), 50)
end

orb.combat.register_f_after_attack(Main)
orb.combat.register_f_out_of_range(Main)
cb.add(cb.updatebuff, OnUpdateBuff)
cb.add(cb.removebuff, OnRemoveBuff)
cb.add(cb.tick, CastQ)
cb.add(cb.draw, OnDraw)

print("Kai'Sa loaded")
