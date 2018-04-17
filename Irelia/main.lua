local script = {}
script.name = "Irelia"
script.developer = "asdf"
script.version = 3.0

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
local evade = module.seek("evade")
local orb = module.internal("orb")
local gpred = module.internal("pred")

q = {range = 625}

w = {
	delay = 0.25, 
	width = 120, 
	speed = math.huge, 
	boundingRadiusMod = 0, 
	range = 825
} 

w_parameters = {
	damageDur = 0.75,
	fullDur = 1.5,
	releaseTime = os.clock(),
	last = os.clock(),
	nonMissileCheck = {},
	castTime = {}
}

e_parameters = {
	e1Pos = vec3(0,0,0),
	target2 = nil,
	nextCast = os.clock(),
	missileSpeed = 2000,
	delayFloor = 0.625
}

e = {
	delay = e_parameters.delayFloor, 
	width =70, --originally 70 
	speed = math.huge, 
	boundingRadiusMod = 1,
	range = 900
}


	
e_obj = nil

r = {
	delay = 0.4,
	width = 100, --originally 160
	speed = 2000, 
	boundingRadiusMod = 0, 
	collision = {hero = true, minion = false}, 
	range = 700
}

debugPos = {
	e1Pos = vec3(0,0,0),
	e2Pred = vec3(0,0,0),
	closest = vec3(0,0,0),
	e2Cast = vec3(0,0,0),
	targetPosAtCast = vec3(0,0,0),
	targetPathEnd = vec3(0,0,0),
}
	
interruptSpells = { 
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
	"sionq",
	"jhinr",
	"pantheonrjump",
	"reapthewhirlwind",
	"xerathlocusofpower2",
}

blockSpells = { --add passives like braum and talon
	["aatroxq"] = {priority = "high", delay = 0.55},
	["aatroxe"] = {priority = "low", delay = 0},
	["ahriseduce"] = {priority = "high", delay = 0},
	["pulverize"] = {priority = "high", delay = 0},
	["headbutt"] = {priority = "high", delay = 0},
	["bandagetoss"] = {priority = "count", delay = 0},
	["curseofthesadmummy"] = {priority = "high", delay = 0},
	["flashfrost"] = {priority = "high", delay = 0},
	["frostbite"] = {priority = "low", delay = 0},
	["disintegrate"] = {priority = "low", delay = 0},
	["infernalguardian"] = {priority = "high", delay = 0},
	["enchantedcrystalarrow"] = {priority = "high", delay = 0},
	["aurelionsolq"] = {priority = "high", delay = 0},
	["aurelionsolr"] = {priority = "high", delay = 0},
	["azirr"] = {priority = "high", delay = 0},
	["bardq"] = {priority = "high", delay = 0},
	["rocketgrab"] = {priority = "high", delay = 0},
	["powerfistattack"] = {priority = "medium", delay = 0},
	["staticfield"] = {priority = "low", delay = 0},
	["brandq"] = {priority = "high", delay = 0}, --check for buff
	["braumbasicattackpassiveoverride"] = {priority = "high", delay = 0},
	["braumrwrapper"] = {priority = "high", delay = 0},
	["caitlynheadshotmissile"] = {priority = "low", delay = 0},
	["caitlynpiltoverpeacemaker"] = {priority = "low", delay = 0},
	["caitlynaceinthehole"] = {priority = "high", delay = 1},
	["camilleq"] = {priority = "high", delay = 0}, --check back
	["camillew"] = {priority = "low", delay = 0}, --check
	["camillee"] = {priority = "medium", delay = 0}, --check
	["cassiopeiar"] = {priority = "high", delay = 0.4}, 
	["rupture"] = {priority = "high", delay = 1.0}, 
	["phosphorusbomb"] = {priority = "low", delay = 0.4}, 
	["missilebarrage2"] = {priority = "low", delay = 0}, 
	["dariuscleave"] = {priority = "high", delay = 0.55}, 
	["dariusexecute"] = {priority = "high", delay = 0}, 
	["dianabasicattack3"] = {priority = "low", delay = 0}, 
	["dianaarc"] = {priority = "low", delay = 0}, 
	["dianavortex"] = {priority = "high", delay = 0}, 
	["dravendoubleshot"] = {priority = "high", delay = 0}, 
	["dravenrcast"] = {priority = "low", delay = 0}, 
	["masochismattack"] = {priority = "medium", delay = 0}, 
	["ekkobasicattackp3"] = {priority = "medium", delay = 0}, 
	["ekkor"] = {priority = "high", delay = 0}, 
	["elisehumanq"] = {priority = "low", delay = 0}, 
	["elisehumane"] = {priority = "high", delay = 0}, 
	["evelynnq"] = {priority = "high", delay = 0}, --check for buff
	["evelynnr"] = {priority = "high", delay = 0}, 
	["ezrealtrueshotbarrage"] = {priority = "low", delay = 0}, 
	["terrify"] = {priority = "high", delay = 0}, 
	["crowstorm"] = {priority = "high", delay = 0}, --check
	["galiow"] = {priority = "high", delay = 0}, --check
	["galioe"] = {priority = "high", delay = 0},
	["galior"] = {priority = "high", delay = 1.35},
	["fizzw"] = {priority = "low", delay = 0}, --check
	["fizzjumptwo"] = {priority = "medium", delay = 0}, 
	["parley"] = {priority = "low", delay = 0}, 
	--barrel q
	["garenqattack"] = {priority = "low", delay = 0}, 
	["garenr"] = {priority = "high", delay = 0}, 
	["gnarbigw"] = {priority = "high", delay = 0.3}, 
	["gnarr"] = {priority = "high", delay = 0}, 
	["gragase"] = {priority = "high", delay = 0}, 
	["gragasr"] = {priority = "high", delay = 0}, 
	--graves q back
	["graveschargeshot"] = {priority = "high", delay = 0}, 
	["hecarimrampattack"] = {priority = "high", delay = 0},
	["hecarimultmissile"] = {priority = "high", delay = 0}, 	
	["heimerdingere"] = {priority = "low", delay = 0}, 
	["illaoiq"] = {priority = "high", delay = 0.55}, 
	["illaoiwattack"] = {priority = "high", delay = 0}, 
	--irelia e detonate
	["ireliar"] = {priority = "high", delay = 0}, 
	["howlinggale"] = {priority = "count", delay = 0}, 
	["reapthewhirlwind"] = {priority = "count", delay = 0}, 
	["jarvanivdragonstrike2"] = {priority = "high", delay = 0}, --check for knockup
	["jarvanivcataclysm"] = {priority = "high", delay = 0},
	["jaxempowertwo"] = {priority = "low", delay = 0},
	["jaycetotheskies"] = {priority = "low", delay = 0},
	["jayceshockblast"] = {priority = "low", delay = 0},
	["jayceshockblastwallmis"] = {priority = "high", delay = 0},
	["jinxr"] = {priority = "high", delay = 0},
	--jhin 4th shot
	["jhinw"] = {priority = "high", delay = 0.4}, --check buff
	["jhinr"] = {priority = "high", delay = 0}, --4th shot missile = "jhinrshotmis4"
	["karthusfallenone"] = {priority = "high", delay = 2},
	["nulllance"] = {priority = "low", delay = 0},
	["katarinar"] = {priority = "high", delay = 0},
	["kennenshurikenhurlmissile1"] = {priority = "low", delay = 0},
	["khazixq"] = {priority = "high", delay = 0},
	["khazixqlong"] = {priority = "high", delay = 0},
	--kled q yank
	--kled r damage portion
	["blindmonkqtwo"] = {priority = "medium", delay = 0},
	["blindmonkrkick"] = {priority = "high", delay = 0},
	["leonashieldofdaybreak"] = {priority = "high", delay = 0},
	["leonazenithblade"] = {priority = "high", delay = 0},
	["leonasolarflare"] = {priority = "high", delay = 0.425},
	["lissandraq"] = {priority = "low", delay = 0},
	["lissandrar"] = {priority = "high", delay = 0},
	["lucianq"] = {priority = "low", delay = 0},
	["luluwtwo"] = {priority = "high", delay = 0},
	--lulur
	["luxlightbinding"] = {priority = "high", delay = 0},
	["luxmalicecannon"] = {priority = "high", delay = 0.9},
	["seismicshard"] = {priority = "low", delay = 0},
	["ufslash"] = {priority = "high", delay = 0},
	["malzaharr"] = {priority = "high", delay = 0},
	["maokaiq"] = {priority = "medium", delay = 0},
	["maokaiw"] = {priority = "count", delay = 0},
	["maokair"] = {priority = "count", delay = 0},
	["missfortunershotextra"] = {priority = "low", delay = 0},
	["mordekaiserqattack2"] = {priority = "high", delay = 0},
	["mordekaiserchildrenofthegrave"] = {priority = "high", delay = 0}, --need to test
	["darkbindingmissile"] = {priority = "high", delay = 0}, 
	["namiqmissile"] = {priority = "high", delay = 0},
	["namirmissile"] = {priority = "count", delay = 0},
	["nasusqattack"] = {priority = "medium", delay = 0}, 
	["nautilusravagestrikeattack"] = {priority = "high", delay = 0}, 
	["nautilusanchordrag"] = {priority = "low", delay = 0}, 
	--naut r
	["javelintoss"] = {priority = "low", delay = 0},
	["nidaleetakedownattack"] = {priority = "high", delay = 0},
	["olafrecklessstrike"] = {priority = "medium", delay = 0},
	["orianadissonancecommand"] = {priority = "high", delay = 0.4}, 
	["orianadetonatecommand"] = {priority = "high", delay = 0.4}, 
	["ornnw"] = {priority = "medium", delay = 0}, --check 
	["ornne"] = {priority = "high", delay = 0},
	["ornnr"] = {priority = "high", delay = 0}, --check 
	["pantheonq"] = {priority = "low", delay = 0}, 
	["pantheonw"] = {priority = "high", delay = 0}, 
	["poppypassiveattack"] = {priority = "low", delay = 0}, 
	["poppye"] = {priority = "high", delay = 0}, 
	["quinnq"] = {priority = "low", delay = 0}, 
	["quinne"] = {priority = "high", delay = 0}, 
	["rakanw"] = {priority = "high", delay = 1.0}, --check delay 
	--rammus q
	["puncturingtaunt"] = {priority = "high", delay = 0}, 
	["reksaiwburrowed"] = {priority = "high", delay = 0}, 
	["reksaie"] = {priority = "medium", delay = 0}, 
	["reksairwrapper"] = {priority = "high", delay = 0},  --work
	["renektonexecute"] = {priority = "high", delay = 0}, --work
	["renektonsuperexecute"] = {priority = "high", delay = 0}, 
	["rengarq"] = {priority = "medium", delay = 0}, 
	--riven third q
	["rivenizunablade"] = {priority = "high", delay = 0}, 
	["ryzeqwrapper"] = {priority = "low", delay = 0}, --check for e
	["ryzew"] = {priority = "high", delay = 0}, 
	["sejuanie"] = {priority = "high", delay = 0}, 
	["sejuanir"] = {priority = "high", delay = 0},
	["twoshivpoison"] = {priority = "low", delay = 0}, 
	--shen q autos
	["shene"] = {priority = "high", delay = 0}, 
	["shyvanadoubleattack"] = {priority = "medium", delay = 0}, 
	["shyvanadoubleattackdragon"] = {priority = "medium", delay = 0}, 
	["shyvanafireball"] = {priority = "low", delay = 0}, 
	["shyvanafireballdragon2"] = {priority = "low", delay = 0}, 
	["shyvanatransformcast"] = {priority = "high", delay = 0}, 
	["fling"] = {priority = "high", delay = 0}, 
	["sionq"] = {priority = "low", delay = 0}, 
	["sionr"] = {priority = "high", delay = 0}, 
	["skarnerimpale"] = {priority = "high", delay = 0}, 
	["sonar"] = {priority = "high", delay = 0}, 
	--need new swain
	--syndra stun
	["syndraq"] = {priority = "low", delay = 0.4}, 	
	["syndrawcast"] = {priority = "low", delay = 0}, 	
	["syndrae"] = {priority = "high", delay = 0}, 	
	["syndrar"] = {priority = "high", delay = 0}, 	
	["taliyahwvc"] = {priority = "high", delay = 0.250}, 	
	["tarice"] = {priority = "high", delay = 0.9}, 	
	["blindingdart"] = {priority = "low", delay = 0}, 	
	["threshq"] = {priority = "high", delay = 0}, 	
	["threshe"] = {priority = "high", delay = 0}, 	
	["tristanar"] = {priority = "high", delay = 0}, 	
	["tristanar"] = {priority = "high", delay = 0}, 	
	["trundleq"] = {priority = "medium", delay = 0}, 	
	["tristanar"] = {priority = "high", delay = 0}, 	
	["goldcardpreattack"] = {priority = "high", delay = 0}, 	
	["udyrbearstance"] = {priority = "high", delay = 0}, 	
	["urgote"] = {priority = "high", delay = 0}, 	
	["varusr"] = {priority = "high", delay = 0}, 
	["vaynecondemnmissile"] = {priority = "high", delay = 0}, 		
	["veigardarkmatter"] = {priority = "low", delay = 1.0}, 	
	["veigareventhorizon"] = {priority = "high", delay = 0}, 	
	["veigarr"] = {priority = "high", delay = 0}, 	
	["velkoze"] = {priority = "high", delay = 0}, 	
	["viqmissile"] = {priority = "high", delay = 0}, 	
	["vir"] = {priority = "high", delay = 0}, 	
	["viktorgravitonfield"] = {priority = "high", delay = 1.3}, 	
	["viktordeathray3"] = {priority = "low", delay = 0.3}, 	
	--vlad q special
	["volibearqattack"] = {priority = "high", delay = 0}, 	
	["infiniteduress"] = {priority = "low", delay = 0}, 	
	["monkeykingqattack"] = {priority = "medium", delay = 0}, 	
	["monkeykingspintowin"] = {priority = "high", delay = 0}, 	
	["xayahe"] = {priority = "low", delay = 0}, 	
	["xerathmagespear"] = {priority = "high", delay = 0}, 	
	["xinzhaoqthrust3"] = {priority = "high", delay = 0}, 	
	["xinzhaow"] = {priority = "medium", delay = 0}, 	
	["xinzhaor"] = {priority = "high", delay = 0}, 	
	["yasuoq3w"] = {priority = "high", delay = 0}, 
	["yorickq"] = {priority = "medium", delay = 0}, 	
	--zac q 2nd
	["zace"] = {priority = "high", delay = 0}, 	
	["zacr"] = {priority = "high", delay = 0}, 	--check
	["ziggsr"] = {priority = "high", delay = 0}, 	
	--["zacr"] = {priority = "high", delay = 0}, 
	["zedq"] = {priority = "low", delay = 0}, 		
	["zedr"] = {priority = "high", delay = 0.74}, 	
	["zoeq"] = {priority = "medium", delay = 0}, 	
	["zyrae"] = {priority = "high", delay = 0}, 	
}

--[[
special cases

Evelyn Q check
Tahm Kench Stun	
Talon passive
Gnar W 3 hit
Karma W
LB E
LB Mark
Nocturne W
Rakan Ult
Skarner E Stun
Tristana E detonate
Velkoz stacks
Zilean Q 2nd
Fizz Ult
Vlad R
Zoe E
]]


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
	
local TargetSelectionNearMouse = function(res, obj, dist)
	if dist < 2000 and obj.pos:dist(game.mousePos) <= script.menu.searchrange:get() then --add mouse check
	  res.obj = obj
	  return true
	end
end

local TargetSelection = function(res, obj, dist)
	if dist <= e.range then	
		targetNearMouse = ts.get_result(TargetSelectionNearMouse).obj
		if targetNearMouse and obj ~= targetNearMouse then
			res.obj = obj
			return true
		end
	end
end

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

function CastQ(target)
	if player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= q.range then
		player:castSpell("obj", 0, target)	 
	end
end

function CanKS(obj)
	return GetQDamage(obj) > common.GetShieldedHealth("ALL", obj)
end


function GetBestQ(pos)
	local minDistance = player.pos:dist(pos)
	local minDistObj = nil
	local minionsInRange = common.GetMinionsInRange(q.range, TEAM_ENEMY)
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
	
	local enemiesInRange = common.GetEnemyHeroesInRange(q.range, player.pos)
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

function LastHitQ()
	local minionsInRange = common.GetMinionsInRange(q.range, TEAM_ENEMY)
	for i, minion in pairs(minionsInRange) do 
		if minion and minion.pos:dist(game.mousePos) <= script.menu.searchrange:get() and CanKS(minion) then
			CastQ(minion)
		end
	end
end

function EvalPriority(spell)
	if player.buff["ireliawdefense"] then
		return true
	end
	local priority = blockSpells[spell.name:lower()].priority 
	local target = ts.get_result(TargetSelectionNearMouse).obj
	if priority == "high" then 
		return true
	end
	if priority == "count" then
		local enemies = common.GetEnemyHeroesInRange(1200, player.pos)
		local count = 0
		for i, enemy in pairs(enemies) do
			count = count + 1
		end
		if count >= 2 then
			return true
		end
	end
	if priority == "medium" then
		if target and (player.pos:dist(target) < player.attackRange + 150 or target.buff["ireliamark"] or CanKS(target)) and spell.owner.ptr == target.ptr then
			return true
		end
	end
	if priority == "low" then
		if orb.menu.last_hit:get() or orb.menu.lane_clear:get() or orb.menu.hybrid:get() and not (target and player.pos:dist(target) < player.attackRange + 150) then
			return true
		end
	end
end

function ReceiveSpell(spell) --want to have a list of castTime
	if blockSpells[spell.name:lower()] and w_parameters.castTime == nil then 
		local dist = spell.endPos and player.path.serverPos:dist(spell.endPos) or nil
		if (spell.target and spell.target.ptr == player.ptr) or dist < player.boundingRadius then
			w_parameters.castTime[spell.name:lower()] = os.clock() + blockSpells[spell.name:lower()].delay
		end
	end
end

function WBlock()
	if evade then 	
		for _, spell in pairs(evade.core.active_spells) do
			if type(spell) == "table" and blockSpells[spell.name:lower()] then
				if spell.polygon then
					if spell.missile and spell.missile.speed then 
						if spell.polygon:Contains(player.pos) == 1 then
							local hitTime = (player.pos:dist(spell.missile.pos)-player.boundingRadius)/spell.missile.speed
							if hitTime > 0 and hitTime < 0.10 and EvalPriority(spell) then
								return true
							end
						end
					else
						if w_parameters.nonMissileCheck[spell.name:lower()] then
							if (not player.buff["ireliawdefense"] and os.clock() >= w_parameters.nonMissileCheck[spell.name:lower()]) or (player.buff["ireliawdefense"] and os.clock() >= w_parameters.nonMissileCheck[spell.name:lower()] - 0.2) and EvalPriority(spell) and spell.polygon:Contains(player.pos) ==1 then
								return true
							end
						else
							w_parameters.nonMissileCheck[spell.name:lower()] = os.clock() + blockSpells[spell.name:lower()].delay
						end
					end
				end
			end
		end
	end
	local lowest = 10000000
	for i, spell in pairs(w_parameters.castTime) do 
		if w_parameters.castTime[spell] and w_parameters.castTime[spell] <= os.clock() then
			w_parameters.castTime[spell] = nil
			passed = true
		end
		if w_parameters.castTime[spell] < lowest then
			lowest = w_parameters.castTime[spell]
		end
	end
	if (not player.buff["ireliawdefense"] and os.clock() >= lowest) or (player.buff["ireliawdefense"] and os.clock() >= lowest - 0.2) then
		return true
	end
end

function CastW1() --spellblock
	if player:spellSlot(1).state == 0 and not player.buff["ireliawdefense"] then
		player:castSpell("pos", 1, game.mousePos)
		w_parameters.last = os.clock()
	end
end

function CastW2(target)
	if player.buff["ireliawdefense"] then
		local seg = gpred.linear.get_prediction(w, target)
		if seg and TraceFilter(seg, target, w, false) then
			player:castSpell("release", 1, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
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

function CastE1(target) 
	if player:spellSlot(2).state == 0 then
		if not target.path.isActive then
			if target.pos:dist(player.pos) <= e.range then
				local cast1 = player.pos + (target.pos-player.pos):norm()*e.range
				player:castSpell("pos", 2, cast1)
				e_parameters.e1Pos = cast1
				e_parameters.target2 = target
				e_parameters.nextCast = os.clock() + 0.25
			end
			
		else
			local pathStartPos = target.path.point[0]
			local pathEndPos = target.path.point[target.path.count]
			local pathNorm = (pathEndPos - pathStartPos):norm()
			local tempPred = common.GetPredictedPos(target, 1.2)
			
			if tempPred then
				local dist1 = player.pos:dist(tempPred)
				if dist1 <= e.range then
					local dist2 = player.pos:dist(target.pos)					
					if dist1<dist2 then
						pathNorm = pathNorm*-1
					end
					local enough = true -- false
					local cast2 = RaySetDist(target.pos, pathNorm, player.pos, e.range)
					
					--[[if target.pos:dist(cast2) >= target.moveSpeed * e_parameters.delayFloor then
						enough = true						
					else
						cast2 = RaySetDist(target.pos, -1*pathNorm, player.pos, e.range)
						if target.pos:dist(cast2) >= target.moveSpeed * e_parameters.delayFloor then
							enough = true
						end
					end]]
					
					if enough then
						player:castSpell("pos", 2, cast2)
						e_parameters.e1Pos = cast2
						e_parameters.nextCast = os.clock() + 0.25
						e_parameters.target2 = target
					end
				end
			end
		end
	end
end

function MultiE1(target, nextTarget) 
	if player:spellSlot(2).state == 0 then
		local target1Pos = common.GetPredictedPos(target, 1.5)
		local target2Pos = common.GetPredictedPos(nextTarget, 1.5)
		if target1Pos and target2Pos and player.pos:dist(target1Pos) <= e.range and player.pos:dist(target2Pos) < e.range then
			local pathNorm = (target1Pos - target2Pos):norm()
			local castPos = RaySetDist(target1Pos, pathNorm, player.pos, e.range)
			player:castSpell("pos", 2, castPos)
			e_parameters.e1Pos = castPos
			e_parameters.nextCast = os.clock() + 0.25
			e_parameters.target2 = nextTarget
		end
	end
end

function setDebug(target, e2Cast, e2Pred, closest)
	debugPos.e1Pos = e_parameters.e1Pos*1
	debugPos.targetPosAtCast = target.pos*1
	debugPos.targetPathEnd = target.path.point[target.path.count]*1
	debugPos.e2Cast = e2Cast
	debugPos.e2Pred = e2Pred
	debugPos.closest = closest
end

function resetE()
	e_parameters.e1Pos = vec3(0,0,0)
	e_parameters.target2 = nil
	e_parameters.nextCast = os.clock() + 0.25
end

function CastE2(target)
	if player:spellSlot(2).state == 0 then
		if target.path.isActive and target.path.isDashing then
			local dashPos = gpred.core.project(player.path.serverPos2D, target.path, network.latency + e_parameters.delayFloor,e_parameters.missileSpeed, target.path.dashSpeed)
			if dashPos and player.pos2D:dist(dashPos) <= e.range then
				player:castSpell("pos", 2, vec3(dashPos.x, target.pos.y, dashPos.y))
				setDebug(target, vec3(dashPos.x, target.pos.y, dashPos.y)*1, vec3(dashPos.x, target.pos.y, dashPos.y)*1,vec3(0,0,0))
				resetE()
			end
		else
			if not target.path.isActive then
				local inActive = e_parameters.e1Pos + (target.pos-e_parameters.e1Pos):norm()*(target.pos:dist(e_parameters.e1Pos)+target.moveSpeed*e_parameters.delayFloor*1.5)
				if target.pos:dist(player.pos) < e.range then 
					player:castSpell("pos", 2, inActive)
					setDebug(target, inActive*1,target.pos*1, vec3(0,0,0))
					resetE()
				end
				
			else
				local short1 = false
				local short2 = false
				e.delay = e_parameters.delayFloor + player.pos:dist(target.pos)/e_parameters.missileSpeed
				local seg1 = gpred.linear.get_prediction(e, target, vec2(e_parameters.e1Pos.x,e_parameters.e1Pos.y ))
				--local tempPos = vec3(seg1.endPos.x, target.pos.y, seg1.endPos.y)
				--local predPos3D1 = e_parameters.e1Pos:lerp(tempPos,(tempPos:dist(e_parameters.e1Pos)+e.radius)/tempPos:dist(e_parameters.e1Pos))
				local predPos3D1 = vec3(seg1.endPos.x, target.pos.y, seg1.endPos.y)
				local predPos1 = vec2(seg1.endPos.x, seg1.endPos.y)
				
				if seg1 and player.pos2D:dist(predPos1)<=e.range then
					if gpred.trace.linear.hardlock(e, seg1, target) or gpred.trace.linear.hardlockmove(e, seg1, target) then
						player:castSpell("pos", 2, predPos3D1)
						setDebug(target, predPos3D1*1,target.pos*1, vec3(0,0,0))
						resetE()
					end
					local e1Pos2D = vec2(e_parameters.e1Pos.x, e_parameters.e1Pos.z)
					local tempCastPos = mathf.closest_vec_line(player.pos2D, e1Pos2D, predPos1)
					local tempCastPos3D = vec3(tempCastPos.x, target.pos.y, tempCastPos.y)
					if tempCastPos3D:dist(player.pos)>e.range or predPos3D1:dist(e_parameters.e1Pos) > tempCastPos3D:dist(e_parameters.e1Pos) or tempCastPos3D:dist(e_parameters.e1Pos) < target.moveSpeed*e_parameters.delayFloor*1.5 then 
						--tempCastPos3D = vec3(predPos1.x, target.pos.y, predPos1.y)
						short1 = true
						local pathNorm = (predPos3D1-e_parameters.e1Pos):norm()
						local extendPos = e_parameters.e1Pos + pathNorm*(predPos3D1:dist(e_parameters.e1Pos)+target.moveSpeed*e_parameters.delayFloor*1.5)
						if player.pos:dist(extendPos)<e.range then
							tempCastPos3D = extendPos
						else
							tempCastPos3D = RaySetDist(e_parameters.e1Pos, pathNorm, player.pos, e.range)
						end
					end
					
					if tempCastPos3D then
						e.delay = e_parameters.delayFloor + player.pos:dist(tempCastPos3D)/e_parameters.missileSpeed
						local seg2 = gpred.linear.get_prediction(e, target, vec2(e_parameters.e1Pos.x,e_parameters.e1Pos.y ))
						local predPos3D2 = vec3(seg2.endPos.x, target.pos.y, seg2.endPos.y)
						--tempPos = vec3(seg2.endPos.x, target.pos.y, seg2.endPos.y)
						--local predPos3D2 = e_parameters.e1Pos:lerp(tempPos,(tempPos:dist(e_parameters.e1Pos)+e.radius)/tempPos:dist(e_parameters.e1Pos))
						local predPos2 = vec2(seg2.endPos.x, seg2.endPos.y)
						
						if seg2 and TraceFilter(seg2, target,e, true) then
							local castPos = mathf.closest_vec_line(player.pos2D, e1Pos2D, predPos2)
							local castPos3D = vec3(castPos.x, target.pos.y, castPos.y)
							
							if castPos3D:dist(player.pos)>e.range or predPos3D2:dist(e_parameters.e1Pos) > castPos3D:dist(e_parameters.e1Pos) or castPos3D:dist(e_parameters.e1Pos) <target.moveSpeed*e_parameters.delayFloor*1.5 then 
								--castPos3D = predPos3D2
								short2 = true
								--temp code
								pathNorm = (predPos3D2-e_parameters.e1Pos):norm()
								extendPos = e_parameters.e1Pos + pathNorm*(predPos3D2:dist(e_parameters.e1Pos)+target.moveSpeed*e_parameters.delayFloor*1.5)
								if player.pos:dist(extendPos)<e.range then
									castPos3D = extendPos
								else
									castPos3D = RaySetDist(e_parameters.e1Pos, pathNorm, player.pos, e.range)
								end 
							end
							if short1 == short2 then
								player:castSpell("pos", 2, castPos3D)
								setDebug(target, castPos3D*1,predPos3D2*1, vec3(tempCastPos.x, target.pos.y, tempCastPos.y))
								resetE()
							end
						end
					end
				end
			end
		end
	end
end

function CastR(target)
	if player:spellSlot(3).state == 0  then
		local seg = gpred.linear.get_prediction(r, target)
		if seg and TraceFilter(seg, target, r, false) then
			if not gpred.collision.get_prediction(r, seg, target) then
				player:castSpell("pos", 3, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end
		end
	end
end

function AutoInterrupt(spell)
	if player:spellSlot(2).state == 0 and e_parameters.e1Pos == vec3(0,0,0) then
		if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
			for i, interruptable in pairs(interruptSpells) do 
				if string.lower(spell.name) == interruptable and common.IsValidTarget(spell.owner) and player.pos:dist(spell.owner.pos) <= e.range then
					CastE1(spell.owner)
				end
			end
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
				CastQ(target)
			end
			
			if player.pos:dist(target.pos) > player.attackRange + 100 then 
				bestQ = GetBestQ(target.pos)
			end
		end
		
		if script.menu.r:get() then
			CastR(target)
		end
		
	else 
		if orb.menu.combat:get() then
			bestQ = GetBestQ(game.mousePos)	
		end
	end

	if orb.menu.combat:get() then
		if bestQ ~= nil then
			CastQ(bestQ)
		end
	end
	
	if orb.menu.hybrid:get() then
		LastHitQ()
	end
	
	if os.clock() >= e_parameters.nextCast then 
		if e_parameters.e1Pos == vec3(0,0,0) and player:spellSlot(2).name == "IreliaE" then 
			if target and (not target.buff["ireliamark"] or CanKS(target)) then
				if target2 then
					if orb.menu.combat:get() or script.menu.e:get() then
						MultiE1(target2,target)
					end
				else
					if (orb.menu.combat:get() and ((bestQ ~= nil and bestQ.pos:dist(target.pos) < script.menu.erange:get()) or (bestQ == nil and player.pos:dist(target.pos) < script.menu.erange:get()))) or script.menu.e:get() then
						CastE1(target)
					end
				end
			else 
				if target2 and script.menu.e:get() and (not target2.buff["ireliamark"] or CanKS(target2)) then
					CastE1(target2)
				end
			end	
		else
			if orb.menu.combat:get() or script.menu.e:get() then
				if common.IsValidTarget(e_parameters.target2) and player.pos:dist(e_parameters.target2.pos)<=e.range then
					if e_parameters.target2.buff["ireliamark"] or not CanKS(e_parameters.target2) then
						CastE2(e_parameters.target2)
					end
				else
					if target then
						if  target.buff["ireliamark"] or not  CanKS(target) then
							CastE2(target)
						end
					else 
						if target2 then
							if target2.buff["ireliamark"] or not CanKS(target2) then
								CastE2(target2)
							end
						end
					end
				end
			end
		end
	end
	
	if WBlock() then	
		CastW1()
	end
	if player.buff["ireliawdefense"] then
		if not (player.buff[5] or player.buff[8] or player.buff[24] or player.buff[11] or player.buff[22] or player.buff[8] or player.buff[21] or WBlock()) or os.clock() >= w_parameters.last + w_parameters.fullDur - 0.05 then
			if w_parameters.releaseTime and w_parameters.releaseTime <= os.clock() then
				if target then
					CastW2(target)
				else
					if target2 then
						CastW2(target2)
					else
						player:castSpell("release", 1, game.mousePos)
					end
				end
			else 
				w_parameters.releaseTime = math.min(os.clock() + 0.2, w_parameters.last + w_parameters.fullDur - 0.05) 
			end
		end
	end
	
	if player:spellSlot(1).state ~= 0 and os.clock()>= w_parameters.last + w_parameters.fullDur then
		w_parameters.nonMissileCheck = {}
	end
end


local function OnSpell(spell)
	AutoInterrupt(spell)
	ReceiveSpell(spell)
	if spell.target and spell.target.ptr == player.ptr and spell.owner.type == TYPE_HERO then
		--print(spell.name)
	end
end

local function CreateObj(object)
	if object.name == "Blade" and object.team == TEAM_ALLY then 
		e_obj = object
		e_parameters.e1Pos = object.pos
	end         
end

local function DeleteObj(object)
	if object.name == "IreliaESecondary" and object.team == TEAM_ALLY then
		e_obj = nil
		e_parameters.e1Pos = vec3(0,0,0)
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
	graphics.draw_circle(player.pos, e.range, 1, graphics.argb(255, 255, 255, 255), 50)

	if debugPos.e2Pred ~= vec3(0,0,0) then
		graphics.draw_circle(debugPos.e2Pred, 30, 1, graphics.argb(255, 0, 0, 255), 50)
	end
	
	if debugPos.e2Cast ~= vec3(0,0,0) and debugPos.e1Pos ~= vec3(0,0,0) then
		graphics.draw_circle(debugPos.e2Cast, 10, 1, graphics.argb(255, 0, 255, 0), 50)
		graphics.draw_circle(debugPos.e1Pos, 10, 1, graphics.argb(255, 0, 255, 0), 50)
		graphics.draw_line(debugPos.e1Pos, debugPos.e2Cast, 3, graphics.argb(255, 0, 255, 0))
	end
	
	if debugPos.closest ~= vec3(0,0,0) then
		graphics.draw_circle(debugPos.closest, 30, 1, graphics.argb(255, 255, 0, 0), 50)
	end
	
	if debugPos.targetPosAtCast ~= vec3(0,0,0) and debugPos.targetPathEnd ~= vec3(0,0,0) then
		graphics.draw_line(debugPos.targetPosAtCast, debugPos.targetPathEnd, 3, graphics.argb(255, 255, 255, 255))
		graphics.draw_circle(debugPos.targetPathEnd, 20, 1, graphics.argb(255, 255, 255, 255), 50)
	end
	
	if e_parameters.e1Pos ~= vec3(0,0,0) then
		graphics.draw_circle(e_parameters.e1Pos, 20, 1, graphics.argb(255, 255, 255, 255), 50)
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