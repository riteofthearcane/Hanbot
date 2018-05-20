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
	["aatroxq"] = {count = 0, priority = "high", delay = 0.55, name = "Aatrox Q Dark Flight", champion = "aatrox"},
	["aatroxe"] = {count = 0, priority = "high", delay = 0, name = "Aatrox E Blades of Torment", champion = "aatrox"},
	["ahriseduce"] = {count = 0, priority = "high", delay = 0, name = "Ahri E Charm", champion = "ahri"},
	["pulverize"] = {count = 0, priority = "high", delay = 0, name = "Alistar Q Pulverize", champion = "alistar"},
	["headbutt"] = {count = 0, priority = "high", delay = 0, name = "Alistar W Headbutt", champion = "alistar"},
	["bandagetoss"] = {count = 0, priority = "high", delay = 0, name = "Amumu Q Bandage Toss", champion = "amumu"},
	["curseofthesadmummy"] = {count = 0, priority = "high", delay = 0, name = "Amumu R Curse of the Sad Mummy", champion = "Amumu"},
	["flashfrost"] = {count = 0, priority = "high", delay = 0, name = "Anivia Q Flash Frost", champion = "anivia"},
	["frostbite"] = {count = 0, priority = "high", delay = 0, name = "Anivia E Frostbite", champion = "anivia"},
	["disintegrate"] = {count = 0, priority = "high", delay = 0, name = "Annie Q Disintegrate", champion = "annie"},
	["infernalguardian"] = {count = 0, priority = "high", delay = 0, name = "Annie R Summoner: Tibbers", champion = "annie"},
	["enchantedcrystalarrow"] = {count = 0, priority = "high", delay = 0, name = "Ashe R Enchanted Crystal Arrow", champion = "ashe"},
	["aurelionsolq"] = {count = 0, priority = "high", delay = 0, name = "Aurelion Sol Q Starsurge", champion = "aurelionsol"},
	["aurelionsolr"] = {count = 0, priority = "high", delay = 0, name = "Aurelion Sol R Voice of Light", champion = "aurelionsol"},
	["azirr"] = {count = 0, priority = "high", delay = 0, name = "Azir R Emperor's Divide", champion = "azir"},
	["bardq"] = {count = 0, priority = "high", delay = 0, name = "Bard Q Cosmic Binding", champion = "bard"},
	["rocketgrab"] = {count = 0, priority = "high", delay = 0, name = "Blitzcrank Q Rocket Grab", champion = "blitzcrank"},
	["powerfistattack"] = {count = 0, priority = "high", delay = 0, name = "Blitzcrank E Power Fist (empowered auto)", champion = "blitzcrank"},
	["staticfield"] = {count = 0, priority = "high", delay = 0, name = "Blitzcrank R Static Field", champion = "blitzcrank"},
	--["brandq"] = {count = 0, priority = "high", delay = 0}, --check for buff
	["braumbasicattackpassiveoverride"] = {count = 0, priority = "high", delay = 0, name = "Braum P Concussive Bhighs (stun)", champion = "braum"},
	["braumrwrapper"] = {count = 0, priority = "high", delay = 0, name = "Braum R Glacial Fissure", champion = "braum"},
	["caitlynheadshotmissile"] = {count = 0, priority = "high", delay = 0, name = "Caitlyn P Headshot", champion = "caitlyn" },
	["caitlynpiltoverpeacemaker"] = {count = 0, priority = "high", delay = 0, name = "Caitlyn Q Piltover Peacemaker", champion = "caitlyn"},
	["caitlynaceinthehole"] = {count = 0, priority = "high", delay = 1, name = "Caitlyn R Ace in the Hole", champion = "caitlyn" },
	["camilleqattackempowered"] = {count = 0, priority = "high", delay = 0, name = "Camille Q Precision Protocol (2nd auto)", champion = "camille" },
	--["camillew"] = {count = 0, priority = "high", delay = 0, name = "Camille W Tactical Sweep", champion = "camille" }, --check
	["camilleedash2"] = {count = 0, priority = "high", delay = 0, name = "Camille E Hookshot (2nd dash)", champion = "camille" }, --check
	["cassiopeiar"] = {count = 0, priority = "high", delay = 0.4, name = "Cassiopeia R Petrifying Gaze", champion = "cassiopeia" },
	["rupture"] = {count = 0, priority = "high", delay = 1.0, name = "Cho'Gath Q Rupture", champion = "chogath" },
	["phosphorusbomb"] = {count = 0, priority = "high", delay = 0.4, name = "Corki Q Phosphorus Bomb", champion = "corki"},
	["missilebarrage2"] = {count = 0, priority = "high", delay = 0, name = "Corki R Missile Barrage (Big)", champion = "corki"}, --check
	["dariuscleave"] = {count = 0, priority = "high", delay = 0.55, name = "Darius Q Decimate", champion = "darius"},
	["dariusexecute"] = {count = 0, priority = "high", delay = 0, name = "Darius R Noxian Guillotine", champion = "darius"},
	["dianabasicattack3"] = {count = 0, priority = "high", delay = 0, name = "Diana P Moonsilver Blade", champion = "diana"},
	["dianaarc"] = {count = 0, priority = "high", delay = 0, name = "Diana Q Crescent Strike", champion = "diana"},
	["dianavortex"] = {count = 0, priority = "high", delay = 0, name = "Diana E Moonfall", champion = "diana"},
	["masochismattack"] = {count = 0, priority = "high", delay = 0, name = "Dr Mundo E Masochism (empowered auto)", champion = "drmundo"},
	["dravendoubleshot"] = {count = 0, priority = "high", delay = 0, name = "Draven E Stand Aside", champion = "draven"},
	["dravenrcast"] = {count = 0, priority = "high", delay = 0, name = "Draven R Whirling Death", champion = "draven"},
	["ekkobasicattackp3"] = {count = 0, priority = "high", delay = 0, name = "Ekko P Z-Drive Resonance", champion = "ekko"},
	--["ekkow"] = {count = 0, priority = "high", delay = 0, name = "Ekko W Parallel Convergence", champion = "ekko"},
	["ekkor"] = {count = 0, priority = "high", delay = 0, name = "Ekko R Chronobreak", champion = "ekko"},
	["elisehumanq"] = {count = 0, priority = "high", delay = 0, name = "Elise Human Q Neurotoxin", champion = "elise"},
	["elisehumane"] = {count = 0, priority = "high", delay = 0, name = "Elise Human E Cocoon", champion = "elise"},
	--["evelynnq"] = {count = 0, priority = "high", delay = 0}, --check for buff
	["evelynnr"] = {count = 0, priority = "high", delay = 0, name = "Evelynn R Agony's Embrace", champion = "evelynn"},
	["ezrealtrueshotbarrage"] = {count = 0, priority = "high", delay = 0, name = "Ezreal R Trueshot Barrage", champion = "ezreal"},
	["terrify"] = {count = 0, priority = "high", delay = 0, name = "Fiddlesticks Q Terrify", champion = "fiddlesticks"},
	--["fizzw"] = {count = 0, priority = "high", delay = 0}, --check
	["fizzjumptwo"] = {count = 0, priority = "high", delay = 0, name = "Fizz E Playful Trickster", champion = "fizz"},
	--fizz r
	--["crowstorm"] = {count = 0, priority = "high", delay = 0}, --check
	["galiow2"] = {count = 0, priority = "high", delay = 0, name = "Galio W Shield of Durand", champion = "galio"}, --check
	["galioe"] = {count = 0, priority = "high", delay = 0, name = "Galio E Justice Punch", champion = "galio"},
	["galior"] = {count = 0, priority = "high", delay = 2.2, name = "Galio R Hero's Entrance", champion = "galio"}, --check
	["parley"] = {count = 0, priority = "high", delay = 0, name = "Gangplank Q Parley", champion = "gangplank"},
	--barrel q
	["garenqattack"] = {count = 0, priority = "high", delay = 0, name = "Garen Q Decisive Strike", champion = "garen"},
	["garenr"] = {count = 0, priority = "high", delay = 0, name = "Garen R Demacian Justice", champion = "garen"},
	--gnar w passive
	["gnarbigw"] = {count = 0, priority = "high", delay = 0.3, name = "Mega Gnar W Wallop", champion = "gnar"},
	["gnarr"] = {count = 0, priority = "high", delay = 0, name = "Mega Gnar R GNAR!", champion = "gnar"},
	["gragase"] = {count = 0, priority = "high", delay = 0, name = "Gragas E Body Slam", champion = "gragas"},
	["gragasr"] = {count = 0, priority = "high", delay = 0, name = "Gragas R Explosive Cask", champion = "gragas"},
	--["graveschargeshot"] = {count = 0, priority = "high", delay = 0, missile = "gravesqreturn", name = "Graves Q End of the Line (return)", champion = "graves"},
	["graveschargeshot"] = {count = 0, priority = "high", delay = 0, name = "Graves R Collateral Damage", champion = "graves"},
	["hecarimrampattack"] = {count = 0, priority = "high", delay = 0, name = "Hecarim E Devastating Charge", champion = "hecarim"},
	["hecarimultmissile"] = {count = 0, priority = "high", delay = 0, name = "Hecarim R Onslaught of Shadows", champion = "hecarim"},
	["heimerdingerturretenergyblast"] = {count = 0, priority = "high", delay = 0.1, name = "Heimerdinger Q/RQ Turret Energy Blast", champion = "heimerdinger"},
	["heimerdingere"] = {count = 0, priority = "high", delay = 0.1, name = "Heimerdinger E/RE CH-2 Electron Storm Grenade", champion = "heimerdinger"},
	["illaoiq"] = {count = 0, priority = "high", delay = 0.55, name = "Illaoi Q Tentacle Smash", champion = "illaoi"},
	["illaoiwattack"] = {count = 0, priority = "high", delay = 0,  name = "Illaoi W Harsh Lesson", champion = "illaoi"},
	--irelia e detonate
	["ireliar"] = {count = 0, priority = "high", delay = 0, name = "Irelia R Vanguard's Edge", champion = "irelia"},
	["ivernq"] = {count = 0, priority = "high", delay = 0, name = "Ivern Q Rootcaller", champion = "ivern"},
	--ivern pet knockup
	["howlinggale"] = {count = 0, priority = "high", delay = 0, name = "Janna Q Howling Gale", champion = "janna"},
	["jarvanivdragonstrike"] = {count = 0, priority = "high", delay = 0, name = "Jarvan IV Q Dragon Strike", champion = "jarvaniv" },
	["jarvanivdragonstrike2"] = {count = 0, priority = "high", delay = 0, name = "Jarvan IV EQ", champion = "jarvaniv"},
	["jarvanivcataclysm"] = {count = 0, priority = "high", delay = 0, name = "Jarvan IV R Cataclysm", champion = "jarvaniv"},
	["jaxempowertwo"] = {count = 0, priority = "high", delay = 0, name = "Jax W Empower", champion = "jax"},
	--jax w + q
	--jax r
	["jayceshockblastmis"] = {count = 0, priority = "high", delay = 0, name = "Jayce Cannon Q Shock Blast", champion = "jayce"},
	["jayceshockblastwallmis"] = {count = 0, priority = "high", delay = 0, name = "Jayce Cannon E+Q Shock Blast (fast)", champion = "jayce"},
	["jaycetotheskies"] = {count = 0, priority = "high", delay = 0, name = "Jayce Hammer Q To the Skies", champion = "jayce"},
	["jinxwmissile"] = {count = 0, priority = "high", delay = 0, name = "Jinx W Zap!", champion = "jinx"},
	["jinxr"] = {count = 0, priority = "high", delay = 0, name = "Jinx R Super Mega Death Rocket!", champion = "jinx"},
	["jhinpassiveattack"] = {count = 0, priority = "high", delay = 0, name = "Jhin P Whisper (4th)", champion = "jhin"},
	--jhin q
	["jhinw"] = {count = 0, priority = "high", delay = 0.4, name = "Jhin W Deadly Flourish", champion = "jhin"}, --check buff
	["jhinrshot"] = {count = 0, priority = "high", delay = 0 , missile = "jhinrshotmis4", name = "Jhin R Curtain Call (4th)", champion = "jhin"},
	--kaisa maybe?
	["karmaq"] = {count = 0, priority = "high", delay = 0 , name = "Karma Q Inner Flame", champion = "karma"},
	["karmaqmissilemantra"] = {count = 0, priority = "high", delay = 0 , name = "Karma Q Inner Flame (Mantra)", champion = "karma"},
	--karma w
	["karthusfallenone"] = {count = 0, priority = "high", delay = 2, name = "Karthus R Requiem", champion = "karthus"},
	["nulllance"] = {count = 0, priority = "high", delay = 0, name = "Kassadin Q Null Sphere", champion = "kassadin"},
	["riftwalk"] = {count = 0, priority = "high", delay = 0.1, name = "Kassadin R Riftwalk", champion = "kassadin"},
	--["katarinar"] = {count = 0, priority = "high", delay = 0},
	--kayn w, r
	["kennenshurikenhurlmissile1"] = {count = 0, priority = "high", delay = 0, name = "Kennen Q Thundering Shuriken", champion = "kennen"},
	--more kennen shit
	["khazixq"] = {count = 0, priority = "high", delay = 0, name = "Kha'Zix Q Taste Their Fear", champion = "khazix"},
	["khazixqlong"] = {count = 0, priority = "high", delay = 0, name = "Kha'Zix Q Taste Their Fear (evolved)", champion = "khazix"},
	--kindred
	--kog r with health check
	--kled q yank
	--kled r damage portion
	--lb e
	--lb q proc
	["blindmonkqtwo"] = {count = 0, priority = "high", delay = 0, name = "Lee Sin Q2 Resonating Strike", champion = "leesin"},
	["blindmonkrkick"] = {count = 0, priority = "high", delay = 0, name = "Lee Sin R Dragon's Rage", champion = "leesin"},
	["leonashieldofdaybreak"] = {count = 0, priority = "high", delay = 0, name = "Leona Q Shield of Daybreak", champion = "leona"},
	["leonazenithblade"] = {count = 0, priority = "high", delay = 0, name = "Leona E Zenith Blade", champion = "leona"},
	["leonasolarflare"] = {count = 0, priority = "high", delay = 0.425, name = "Leona R Solar Flare", champion = "leona"},
	["lissandraq"] = {count = 0, priority = "high", delay = 0, name = "Lissandra Q Ice Shard", champion = "lissandra"},
	["lissandrar"] = {count = 0, priority = "high", delay = 0, name = "Lissandra R Frozen Tomb", champion = "lissandra"},
	["lucianq"] = {count = 0, priority = "high", delay = 0, name = "Lucian Q Piercing Light", champion = "lucian"},
	["luluwtwo"] = {count = 0, priority = "high", delay = 0, name = "Lulu W Polymorph", champion = "lulu"},
	--lulur
	["luxlightbinding"] = {count = 0, priority = "high", delay = 0, name = "Lux Q Light Binding", champion = "lux"},
	["luxmalicecannon"] = {count = 0, priority = "high", delay = 0.9, name = "Lux R Final Spark", champion = "lux"},--test
	["seismicshard"] = {count = 0, priority = "high", delay = 0, name = "Malphite Q Seismic Shard", champion = "malphite"},
	["ufslash"] = {count = 0, priority = "high", delay = 0, name = "Malphite R Unstoppable Force", champion = "malphite"},
	["malzaharr"] = {count = 0, priority = "high", delay = 0, name = "Malzahar R Nether Grasp", champion = "malzahar"},
	["maokaiq"] = {count = 0, priority = "high", delay = 0, name = "Maokai Q Arcane Smash", champion = "maokai"},
	["maokaiw"] = {count = 0, priority = "high", delay = 0, name = "Maokai W Twisted Advance", champion = "maokai"},
	["maokair"] = {count = 0, priority = "high", delay = 0, name = "Maokai R Nature's Grasp", champion = "maokai"}, --test
	["missfortunershotextra"] = {count = 0, priority = "high", delay = 0, name = "Miss Fortune Q Double Up (bounce)", champion = "missfortune"},
	["mordekaiserqattack2"] = {count = 0, priority = "high", delay = 0, name = "Mordekaiser Q Mace of Spades (3rd)", champion = "mordekaiser"},
	["mordekaiserchildrenofthegrave"] = {count = 0, priority = "high", delay = 0, name = "Mordekaiser R Children of the Grave", champion = "mordekaiser"}, --need to test
	["darkbindingmissile"] = {count = 0, priority = "high", delay = 0, name = "Morgana Q Dark Binding", champion = "morgana"},
	--morgana R
	["namiqmissile"] = {count = 0, priority = "high", delay = 0, name = "Nami Q Aqua Prison", champion = "nami"},
	["namirmissile"] = {count = 0, priority = "high", delay = 0, name = "Nami R Tidal Wave", champion = "nami"},
	["nasusqattack"] = {count = 0, priority = "high", delay = 0, name = "Nasus Q Siphoning Strike", champion = "nasus"},
	["nautilusravagestrikeattack"] = {count = 0, priority = "high", delay = 0, name = "Nautilus P Staggering Bhigh", champion = "nautilus"},
	["nautilusanchordrag"] = {count = 0, priority = "high", delay = 0, name = "Nautilus Q Dredge Line", champion = "nautilus"},
	--naut r
	["javelintoss"] = {count = 0, priority = "high", delay = 0, name = "Nidalee Human Q Javelin Toss", champion = "nidalee"},
	["nidaleetakedownattack"] = {count = 0, priority = "high", delay = 0, name = "Nidalee Cougar Q Takedown", champion = "nidalee"},
	--nocturne w
	["iceblast"] = {count = 0, priority = "high", delay = 0, name = "Nunu E Ice Blast", champion = "nunu"},
	["olafaxethrowcast"] = {count = 0, priority = "high", delay = 0, name = "Olaf Q Axe Throw", champion = "olaf"},
	["olafrecklessstrike"] = {count = 0, priority = "high", delay = 0, name = "Olaf E Reckless Swing", champion = "olaf"},
	["orianadissonancecommand"] = {count = 0, priority = "high", delay = 0, name = "Orianna W Command: Dissonance", champion = "orianna"},
	["orianadetonatecommand"] = {count = 0, priority = "high", delay = 0.4, name = "Orianna R Command: Detonate", champion = "orianna"},
	--ornn w
	["ornne"] = {count = 0, priority = "high", delay = 0, name = "Ornn E Searing Charge", champion = "ornn"},
	["ornnrcharge"] = {count = 0, priority = "high", delay = 0, name = "Ornn R Call of the Forge God", champion = "ornn"}, --check
	["pantheonq"] = {count = 0, priority = "high", delay = 0, name = "Pantheon Q Spear Shot", champion = "pantheon"},
	["pantheonw"] = {count = 0, priority = "high", delay = 0 ,name = "Pantheon W Aegis of Zeonia", champion = "pantheon"},
	--pantheon r
	["poppypassiveattack"] = {count = 0, priority = "high", delay = 0, name = "Poppy P Iron Ambassador", champion = "poppy"},
	["poppye"] = {count = 0, priority = "high", delay = 0, name = "Poppy E Steadfast Presence", champion = "poppy"},
	["poppyrspellinstant"] = {count = 0, priority = "high", delay = 0, name = "Poppy R Keeper's Verdict (knockup)", champion = "poppy"},
	["quinnq"] = {count = 0, priority = "high", delay = 0, name = "Quinn Q Blinding Assault", champion = "quinn"},
	["quinne"] = {count = 0, priority = "high", delay = 0, name = "Quinn E Vault", champion = "quinn"},
	["rakanw"] = {count = 0, priority = "high", delay = 0.55, name = "Rakan W Grand Entrance", champion = "rakan"},
	["puncturingtaunt"] = {count = 0, priority = "high", delay = 0, name = "Rammus E Puncturing Taunt", champion = "rammus"},
	["reksaiwburrowed"] = {count = 0, priority = "high", delay = 0, name = "Rek'Sai W Unburrow", champion = "reksai"},
	["reksaie"] = {count = 0, priority = "high", delay = 0, name = "Rek'Sai E Furious Bite", champion = "reksai"},
	["reksairwrapper"] = {count = 0, priority = "high", delay = 0, name = "Rek'Sai R Void Rush", champion = "reksai"},  --check delay
	["renektonexecute"] = {count = 0, priority = "high", delay = 0, name = "Renekton W Ruthless Predator", champion = "renekton"}, --work
	["renektonsuperexecute"] = {count = 0, priority = "high", delay = 0, name = "Renekton W Ruthless Predator (fury)", champion = "renekton"},
	["rengarq"] = {count = 0, priority = "high", delay = 0, name = "Rengar Q Savagery", champion = "rengar"},
	--rengar q empowered
	--riven third q
	["rivenizunablade"] = {count = 0, priority = "high", delay = 0, name = "Riven R Izuna Blade", champion = "riven"},
	["ryzeqwrapper"] = {count = 0, priority = "high", delay = 0, name = "Ryze Q Overload", champion = "ryze"}, --check for e
	["ryzew"] = {count = 0, priority = "high", delay = 0, name = "Ryze W Rune Prison", champion = "ryze"},
	["sejuaniq"] = {count = 0, priority = "high", delay = 0, name = "Sejuani Q Arctic Assault", champion = "sejuani" },
	["sejuanie"] = {count = 0, priority = "high", delay = 0, name = "Sejuani E Permafrost", champion = "sejuani" },
	["sejuanir"] = {count = 0, priority = "high", delay = 0, name = "Sejuani R Glacial Prison", champion = "sejuani" },
	["twoshivpoison"] = {count = 0, priority = "high", delay = 0, name = "Shaco E Two Shiv Poison", champion = "shaco" },
	--shen q autos
	["shene"] = {count = 0, priority = "high", delay = 0, name = "Shen E Shadow Dash", champion = "shen" },
	["shyvanadoubleattack"] = {count = 0, priority = "high", delay = 0, name = "Shyvana Human Q Twin Bite ", champion = "shyvana" },
	["shyvanadoubleattackdragon"] = {count = 0, priority = "high", delay = 0, name = "Shyvana Dragon Q Twin Bite ", champion = "shyvana"},
	["shyvanafireball"] = {count = 0, priority = "high", delay = 0, name = "Shyvana Human E Flame Breath ", champion = "shyvana"},
	["shyvanafireballdragon2"] = {count = 0, priority = "high", delay = 0, name = "Shyvana Dragon E Flame Breath ", champion = "shyvana"},
	["shyvanatransformcast"] = {count = 0, priority = "high", delay = 0, name = "Shyvana R Dragon's Descent", champion = "shyvana"},
	["fling"] = {count = 0, priority = "high", delay = 0, name = "Singed E Fling", champion = "singed"},
	["sionq"] = {count = 0, priority = "high", delay = 0, name = "Sion Q Decimating Smash", champion = "sion"},
	["sione"] = {count = 0, priority = "high", delay = 0, name = "Sion E Roar of the Slayer", champion = "sion"}, --check
	["sionr"] = {count = 0, priority = "high", delay = 0, name = "Sion R Soul Furnace", champion = "sion"},
	["sivirq"] = {count = 0, priority = "high", delay = 0, name = "Sivir Q Boomerang Blade", champion = "sivir"},
	--skarner e auto
	["skarnerimpale"] = {count = 0, priority = "high", delay = 0, name = "Skarner R Impale", champion = "skarner"},
	["sonar"] = {count = 0, priority = "high", delay = 0, name = "Sona R Crescendo", champion = "sona"},
	["swainpdummycast"] = {count = 0, priority = "high", delay = 0, name = "Swain P Ravenous Flock", champion = "swain"},
	["swaine"] = {count = 0, priority = "high", delay = 0,  name = "Swain E Nevermove", champion = "swain"},
	["swainrsoulflare"] = {count = 0, priority = "high", delay = 0, name = "Swain R Demonflare", champion = "swain"},
	["syndraq"] = {count = 0, priority = "high", delay = 0.4, name = "Syndra Q Dark Sphere", champion = "syndra"},
	["syndrawcast"] = {count = 0, priority = "high", delay = 0, name = "Syndra W Force of Will", champion = "syndra"},
	["syndrae"] = {count = 0, priority = "high", delay = 0, name = "Syndra E Scatter of the Weak", champion = "syndra"},
	["syndrar"] = {count = 0, priority = "high", delay = 0, name = "Syndra R Unleashed Power", champion = "syndra"},
	--tahm kench q stun
	--talon passive
	["talonw"] = {count = 0, priority = "high", delay = 0, name = "Talon W", champion = "talon"},
	["talonwmissile"] = {count = 0, priority = "high", delay = 0, name = "Talon W (return)", champion = "talon"},
	["taliyahwvc"] = {count = 0, priority = "high", delay = 0.250, name = "Taliyah W Seismic Shove", champion = "taliyah"},
	["tarice"] = {count = 0, priority = "high", delay = 0.9, name = "Taric E Dazzle", champion = "taric"},
	["blindingdart"] = {count = 0, priority = "high", delay = 0, name = "Taric Q Blinding Dart", champion = "teemo"},
	["threshq"] = {count = 0, priority = "high", delay = 0, name = "Thresh Q Death Sentence", champion = "thresh"},
	["threshe"] = {count = 0, priority = "high", delay = 0, name = "Thresh E Flay", champion = "thresh"},
	--tristana e detonate
	["tristanar"] = {count = 0, priority = "high", delay = 0, name = "Tristana R Buster Shot", champion = "tristana"},
	["trundleq"] = {count = 0, priority = "high", delay = 0, name = "Trundle Q Chomp", champion = "trundle"},
	["bluecardpreattack"] = {count = 0, priority = "high", delay = 0, name = "Twisted Fate W Pick a Card (blue)", champion = "twistedfate"},
	["redcardpreattack"] = {count = 0, priority = "high", delay = 0, name = "Twisted Fate W Pick a Card (red)", champion = "twistedfate"},
	["goldcardpreattack"] = {count = 0, priority = "high", delay = 0, name = "Twisted Fate W Pick a Card (gold)", champion = "twistedfate"},
	["udyrbearstance"] = {count = 0, priority = "high", delay = 0, name = "Udyr E Bear Stance", champion = "udyr"},
	["urgote"] = {count = 0, priority = "high", delay = 0, name = "Urgot E Disdain", champion = "urgot"},
	--block varus w stacks?
	["varusr"] = {count = 0, priority = "high", delay = 0, name = "Varus R Chain of Corruption", champion = "varus"},
	["vaynecondemnmissile"] = {count = 0, priority = "high", delay = 0, name = "Vayne E Condemn", champion = "vayne"}, --wall check
	["veigarbalefulstrike"] = {count = 0, priority = "high", delay = 0, name = "Veigar Q Baleful Strike", champion = "veigar"},
	["veigardarkmatter"] = {count = 0, priority = "high", delay = 1.0, name = "Veigar W Dark Matter", champion = "veigar"},
	["veigareventhorizon"] = {count = 0, priority = "high", delay = 0.3, name = "Veigar E Event Horizon", champion = "veigar"},
	["veigarr"] = {count = 0, priority = "high", delay = 0, name = "Veigar R Primordial Burst", champion = "veigar"},
	["velkoze"] = {count = 0, priority = "high", delay = 0, name = "Vel'Koz E Tectonic Disruption", champion = "velkoz"},
	--velkoz stacks
	["viqmissile"] = {count = 0, priority = "high", delay = 0, name = "Vi Q Vault Breaker", champion = "vi"},
	--vi w proc
	["vir"] = {count = 0, priority = "high", delay = 0, name = "Vi R Assault and Battery", champion = "vi"},
	["viktorgravitonfield"] = {count = 0, priority = "high", delay = 1.3, name = "Viktor W Gravity Field", champion = "viktor"},
	["viktordeathray3"] = {count = 0, priority = "high", delay = 0.3, name = "Viktor E Death Ray (aftershock)", champion = "viktor"},
	--vlad q special
	--vlad r
	["volibearqattack"] = {count = 0, priority = "high", delay = 0, name = "Volibear Q Rolling Thunder", champion = "volibear"},
	--volibear w frenzy
	--warwick q
	["warwickq"] = {count = 0, priority = "high", delay = 0, name = "Warwick Q Jaws of the Beast", champion = "warwick"},
	["warwickr"] = {count = 0, priority = "high", delay = 0, name = "Warwick R Infinite Duress", champion = "warwick"},
	["monkeykingqattack"] = {count = 0, priority = "high", delay = 0, name = "Wukong Q Crushing Bhigh", champion = "monkeyking"},
	["monkeykingspintowin"] = {count = 0, priority = "high", delay = 0, name = "Wukong R Cyclone", champion = "monkeyking"},
	["xayahe"] = {count = 0, priority = "high", delay = 0, name = "Xayah E Bladecaller", champion = "xayah"},
	["xerathmagespear"] = {count = 0, priority = "high", delay = 0, name = "Xerath E Shocking Orb", champion = "xerath"},
	["xinzhaoqthrust3"] = {count = 0, priority = "high", delay = 0, name = "Xin Zhao Q Three Talon Strike (3rd)", champion = "xinzhao"},
	["xinzhaow"] = {count = 0, priority = "high", delay = 0, name = "Xin Zhao W Wind Becomes Lightning", champion = "xinzhao"},
	["xinzhaor"] = {count = 0, priority = "high", delay = 0, name = "Xin Zhao R Crescent Guard", champion = "xinzhao"},
	["yasuoq3w"] = {count = 0, priority = "high", delay = 0, name = "Yasuo Q Steel Tempest (tornado)", champion = "yasuo"},
	["yorickq"] = {count = 0, priority = "high", delay = 0, name = "Yorick Q Last Rites", champion = "yorick"},--check
	["zace"] = {count = 0, priority = "high", delay = 0, name = "Zac E Elastic Slingshot", champion = "zac"},
	["zacr"] = {count = 0, priority = "high", delay = 0.9, name = "Zac R Let's Bounce!", champion = "zac"}, 	--check
	["zedq"] = {count = 0, priority = "high", delay = 0, name = "Zed Q Deadly Shuriken", champion = "zed"},
	["zedr"] = {count = 0, priority = "high", delay = 0.74, name = "Zed R Death Mark", champion = "zed"},
	["ziggsr"] = {count = 0, priority = "high", delay = 0, name = "Ziggs R Mega Inferno Bomb", champion = "ziggs"},
--zilean bomb 2
	["zoeq"] = {count = 0, priority = "high", delay = 0, name = "Zoe Q Paddle Star", champion = "zoe"},
	["zoeqrecast"] = {count = 0, priority = "high", delay = 0, name = "Zoe Q Paddle Star (recast)", champion = "zoe"},
	--zoe e
	["zyraq"] = {count = 0, priority = "high", delay = 0, name = "Zyra Q Deadly Bloom", champion = "zyra" },
	["zyrae"] = {count = 0, priority = "high", delay = 0, name = "Zyra E Grasping Roots", champion = "zyra" },
	["zyrar"] = {count = 0, priority = "high", delay = 0, name = "Zyra R Strangle Thorns", champion = "zyra" },
}

--[[
special cases

Tahm Kench Stun
Talon passive

Rakan Ult
Skarner E Stun
Zilean Q 2nd
Zoe E
]]


passiveBaseScale = {2.5, 2,5, 3.5, 3.5, 4.5, 4.5, 5.5, 5.5, 6,5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5, 14.5, 15.5, 16.5}
passiveADScale = {2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4}
PTAScale = { 0.08, 0.08, 0.08, 0.09, 0.09, 0.09, 0.09, 0.10, 0.10, 0.10, 0.10, 0.11, 0.11, 0.11, 0.11, 0.12, 0.12, 0.12 }
sheenTimer = os.clock()
inFountain = true
itemList = {
	hasSheen = false,
    hasTF = false,
	hasBOTRK = false,
	hasTitanic = false,
	hasWitsEnd = false,
	hasRecurve = false,
	hasGuinsoo = false,
}
target = nil
target2 = nil

script.menu = menu("ireliamenu", script.name)
	ts.load_to_menu(script.menu)
	script.menu:keybind("r", "Semi-manual R", "Z", nil)
	script.menu:keybind("e", "Semi-manual E", "T", nil)
	script.menu:slider("erange", "E Range", 500, 0, 900, 1)
	script.menu:slider("searchrange", "Enemy Search Range", 500, 0, 900, 1)
	script.menu:menu("w", "W Usage")
	local enemyList = {}
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		enemyList[enemy.charName:lower()] = true
	end
	for name, spell in pairs(blockSpells) do
		if enemyList[spell.champion] then
			script.menu.w:menu(name,spell.name)
			local defaultPriorityList = {"high", "medium", "low", "ignore"}
			local defaultCountList = {0,1,2,3}
			local defaultPriority = 0
			local defaultCount = 0
			for i = 0, 4 do
				if spell.priority == defaultPriorityList[i] then
					defaultPriority = i
				end
				if spell.count == defaultCountList[i] then
					defaultCount = i
				end
			end
			script.menu.w[name]:dropdown("priority", "Priority",defaultPriority,{"Always","In Combat","Poke","Ignore"})
			script.menu.w[name]:dropdown("count", "Count",defaultCount,{"Always","Alone or dueling","Near 2 or more enemies","Near 3 or more enemies"})
			script.menu.w[name]:slider("HP", "HP under",100,1,100,1)
		end
	end


local TargetSelectionNearMouse = function(res, obj, dist)
	if dist < 2000 and obj.pos:dist(game.mousePos) <= script.menu.searchrange:get() then --add mouse check
	  res.obj = obj
	  return true
	end
end

local TargetSelection = function(res, obj, dist)
	if dist <= e.range then
		if target and obj ~= target then
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
	if target.buff["garenw"] then --first 0.75 seconds reduces 60%
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
		multiplier = multiplier * (0.70 - (target:spellSlot(2).level * 0.05))
	end
	if target.buff["ireliawdefense"] then
		multiplier = multiplier * ((0.60 - (target:spellSlot(1).level * 0.05)) - (0.07 * (common.GetTotalAP(target) / 100)))
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
		total = total * 1.7
	end
	totalPhysical = total + totalPhysical

	--onhit

	local onhitPhysical = 0
	local onhitMagical = 0

	if itemList.hasTF and (os.clock() >= sheenTimer or player.buff[sheen]) then
			onhitPhysical = onhitPhysical + 2*player.baseAttackDamage
	end
	if itemList.hasSheen and not itemList.hasTF and (os.clock() >= sheenTimer or player.buff[sheen]) then
		onhitPhysical = onhitPhysical + player.baseAttackDamage
	end
	if itemList.hasBOTRK then
		if target.type == TYPE_MINION then
			onhitPhysical = onhitPhysical + math.min(math.max(15, target.health*0.08),60)
		else
			onhitPhysical = onhitPhysical + math.max(15, target.health*0.08)
		end
	end
	if itemList.hasTitanic then
		if player.buff["itemtitanichydracleavebuff"] then
			onhitPhysical = onhitPhysical + 40 + player.maxHealth/10
		else
			onhitPhysical = onhitPhysical + 5 + player.maxHealth/100
		end
	end
	if itemList.hasRecurve then
		onhitPhysical = onhitPhysical+10
	end
	if itemList.hasWitsEnd then
		onhitMagical = onhitMagical + 42
	end

	--passive
	if player.buff["ireliapassivestacks"] then
		local passiveTotalDmg = common.GetTotalAD() * passiveADScale[player.levelRef] / 100
		passiveTotalDmg = (player.buff["ireliapassivestacks"].stacks2+1)*passiveTotalDmg
		onhitMagical = onhitMagical + passiveTotalDmg
	end

	if itemList.hasGuinsoo then
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
	if spell.range < player.pos2D:dist(seg.endPos) then
		return false
	end
	
	if gpred.trace.linear.hardlock(spell, seg, obj) then
		return true
	end
	if gpred.trace.linear.hardlockmove(spell, seg, obj) then
		return true
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

	monstersInRange = common.GetMinionsInRange(q.range, TEAM_NEUTRAL)

	for i, monster in pairs(monstersInRange) do
		if monster then
			local minionDist = monster.pos:dist(pos)
			if CanKS(monster) or monster.buff["ireliamark"] then
				if  minionDist < minDistance then
					minDistance = minionDist
					minDistObj = monster
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
	if not script.menu.w[spell.name:lower()].priority:get() then
		return false
	end
	local priority = script.menu.w[spell.name:lower()].priority:get()
	if priority == 1 then
		return true
	end
	if priority == 2 then
		if target and (player.pos:dist(target) < player.attackRange + 150 or target.buff["ireliamark"] or CanKS(target)) and spell.owner.ptr == target.ptr then
			return true
		end
	end
	if priority == 3 then
		if orb.menu.last_hit:get() or orb.menu.lane_clear:get() or orb.menu.hybrid:get() and not (target and player.pos:dist(target) < player.attackRange + 150) then
			return true
		end
	end
end

function EvalCount(spell)
	if player.buff["ireliawdefense"] then
		return true
	end
	if not script.menu.w[spell.name:lower()].count:get() then
		return false
	end
	local count = script.menu.w[spell.name:lower()].count:get()
	if count == 1 then
		return true
	end
	local enemiesInRange = common.GetEnemyHeroesInRange(q.range*2, player.pos)
	local enemyCount = 0
	for i, enemy in pairs(enemiesInRange) do
		enemyCount = enemyCount + 1
	end
	if count == 2 and enemyCount <= 1 then
		return true
	end
	if count == 3 and enemyCount >= 2 then
		return true
	end
	if count == 4 and enemyCount >= 3 then
		return true
	end
end

function EvalHP(spell)
	if player.buff["ireliawdefense"] then
		return true
	end
	if not script.menu.w[spell.name:lower()].HP:get() then
		return false
	end
	if common.GetPercentHealth(player) <= script.menu.w[spell.name:lower()].HP:get() then
		return true
	end
end
--[[
function ReceiveSpell(spell) --want to have a list of castTime
	if blockSpells[spell.name:lower()] and not w_parameters.castTime[spell.name:lower()] then
		local dist = spell.endPos and player.path.serverPos:dist(spell.endPos) or nil
		if (spell.target and spell.target.ptr == player.ptr) or dist < player.boundingRadius then
			w_parameters.castTime[spell.name:lower()] = os.clock() + blockSpells[spell.name:lower()].delay
			print("3")
			print(spell.name)
		end
	end
end
]]
function WBlock()
	if evade then
		for _, spell in pairs(evade.core.active_spells) do
			if type(spell) == "table" and blockSpells[spell.name:lower()] then
				if spell.missile and spell.missile.speed then
					if (spell.polygon and spell.polygon:Contains(player.pos)==1) or (spell.target and spell.target.ptr) then
						local hitTime = (player.pos:dist(spell.missile.pos)-player.boundingRadius)/spell.missile.speed
						if hitTime > 0 and hitTime < 0.10  and EvalPriority(spell) and EvalCount(spell) and EvalHP(spell) then
							return true
						end
					end
				else
					if w_parameters.nonMissileCheck[spell.name:lower()] then
						if ((not player.buff["ireliawdefense"] and os.clock() >= w_parameters.nonMissileCheck[spell.name:lower()]) or
						(player.buff["ireliawdefense"] and os.clock() >= w_parameters.nonMissileCheck[spell.name:lower()] - 0.2)) and EvalPriority(spell) and EvalCount(spell) and EvalHP(spell) and
						((spell.polygon and spell.polygon:Contains(player.pos)==1) or (spell.target and spell.target.ptr == player.ptr)) then
							return true
						end
					else
						w_parameters.nonMissileCheck[spell.name:lower()] = os.clock() + blockSpells[spell.name:lower()].delay
					end
				end
			end
		end
	end
	--[[local lowest = 10000000
	for i, spell in pairs(w_parameters.castTime) do
		if spell and spell+1 <= os.clock() then
			spell = nil
		end
		if  spell and spell < lowest then
			lowest = spell
		end
	end

	if (not player.buff["ireliawdefense"] and os.clock() >= lowest) or (player.buff["ireliawdefense"] and os.clock() >= lowest - 0.2) then
		return true
	end]]
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
	local castMode = 0
		if target.path.isActive and target.path.isDashing then
			local dashPos = gpred.core.project(player.path.serverPos2D, target.path, network.latency + e_parameters.delayFloor,e_parameters.missileSpeed, target.path.dashSpeed)
			if dashPos and player.pos2D:dist(dashPos) <= e.range then
				player:castSpell("pos", 2, vec3(dashPos.x, target.pos.y, dashPos.y))
				setDebug(target, vec3(dashPos.x, target.pos.y, dashPos.y)*1, vec3(dashPos.x, target.pos.y, dashPos.y)*1,vec3(0,0,0))
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
				e1Pos2D = vec2(e_parameters.e1Pos.x, e_parameters.e1Pos.z)
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
						local castPos = mathf.closest_vec_line(player.pos2D, e1Pos2D,predPos2)
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
						else 
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

function updateItems()
	for i in pairs(itemList) do
		itemList[i] = false
	end
	for i = 0, 5 do
		if player:itemID(i) == 3078 then
			itemList.hasTF = true
		end
		if player:itemID(i) == 3057 then
			itemList.hasSheen = true
		end
		if player:itemID(i) == 3153 then
			itemListhasBOTRK = true
		end
		if player:itemID(i) == 3748 then
			itemList.hasTitanic = true
		end
		if player:itemID(i) == 3091 then
			itemList.hasWitsEnd = true
		end
		if player:itemID(i) == 1043 then
			itemList.hasRecurve = true
		end
		if player:itemID(i) == 3124 then
			itemList.hasGuinsoo = true
		end
	end
end

local function OnTick()
	target = ts.get_result(TargetSelectionNearMouse).obj
	target2 = ts.get_result(TargetSelection).obj
	local bestQ = nil

	if common.NearFountain() then
		inFountain = true
	else
		if inFountain~= common.NearFountain() then
			updateItems()
		end
		inFountain = false
	end

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
					if (orb.menu.combat:get() and ((bestQ ~= nil and bestQ.pos:dist(target.pos) < script.menu.erange:get()) or
					(bestQ == nil and player.pos:dist(target.pos) < script.menu.erange:get()))) or script.menu.e:get() then
						CastE1(target)
					end
				end
			else
				if target2 and script.menu.e:get() and (not target2.buff["ireliamark"] or CanKS(target2)) then
					CastE1(target2)
				end
			end
		else
			if player:spellSlot(2).name == "IreliaE2" then
				if common.IsValidTarget(e_parameters.target2) and player.pos:dist(e_parameters.target2.pos)<=e.range then
					if e_parameters.target2.buff["ireliamark"] or not CanKS(e_parameters.target2) then
						CastE2(e_parameters.target2)
					end
				else
					if target then
						if target.buff["ireliamark"] or not CanKS(target) then
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

	if WBlock() and not player.buff["ireliawdefense"] then
		CastW1()
	end
	if player.buff["ireliawdefense"] then
		if not (player.buff[5] or player.buff[8] or player.buff[24] or player.buff[11] or player.buff[22] or player.buff[8] or player.buff[21] or
		WBlock()) or os.clock() >= w_parameters.last + w_parameters.fullDur - 0.05 then
			if w_parameters.releaseTime and w_parameters.releaseTime <= os.clock() then
				if target then
					CastW2(target)
				else
					if target2 then
						CastW2(target2)
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
	--ReceiveSpell(spell)
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
