local script = {}
script.name = "Xerath+"
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
local evade = module.seek("evade")


script.menu = menu("xerathmenu", script.name)
	script.menu:boolean("evade","Disable Evade during R", true)
	script.menu:boolean("qdraw","Q drawings", true)
	script.menu:boolean("rdraw","R drawings", true)
	script.menu:boolean("rdrawmini","R drawings on minimap", true)
	script.menu:menu("antigap", "Anti-gapcloser E")
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		script.menu.antigap:boolean(enemy.charName, enemy.charName, false)
	end

r = player:spellSlot(3)
color = graphics.argb(255, 255, 255, 255)
	
local function AntiGap()
	if player:spellSlot(2).state == 0  then
		for i=0, objManager.enemies_n - 1 do
			local enemy = objManager.enemies[i]
			if common.IsValidTarget(enemy) and enemy.path.isActive and enemy.path.isDashing then
				name = enemy.charName
				if script.menu.antigap[name]:get() then
					local pred_pos = gpred.core.project(player.path.serverPos2D, enemy.path, network.latency + 0.25, 1400, enemy.path.dashSpeed)
					if pred_pos and pred_pos:dist(player.path.serverPos2D) <= 800 then
						player:castSpell("pos", 2, vec3(pred_pos.x, enemy.y, pred_pos.y))
					end
				end
			end
		end
	end
end

local function OnTick()
	AntiGap()
end

local function OnDraw()
	if script.menu.qdraw:get() then
		graphics.draw_circle(player.pos, 1550, 1, color, 32)
	end
	if r.level > 0 then 
		if script.menu.rdraw:get() then
			graphics.draw_circle(player.pos, (2000 + (1200*r.level)), 1, color, 32)
		end
		if script.menu.rdrawmini:get() then
			minimap.draw_circle(player.pos, (2000 + (1200*r.level)), 1, color, 32)
		end
	end
end

local function OnUpdateBuff(buff)
	if buff.name == "xerathrshots" then
		evade.core.set_pause(math.huge)
	end
end

local function OnRemoveBuff(buff)
	if buff.name == "xerathrshots" then
		evade.core.set_pause(0)
	end
end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)

if evade and script.menu.evade:get() then
	cb.add(cb.updatebuff,OnUpdateBuff)
	cb.add(cb.removebuff,OnRemoveBuff)
end

print("Xerath+ loaded")