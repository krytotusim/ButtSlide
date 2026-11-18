-- GitHub collaboration test
local C = {}

C.Locations = {
	{id = "Jungle", name = "Джунгли", unlock = 0, z = 0, length = 6000, fric = 1.0, grip = 9, coin = 1, boost = 28},
	{id = "Snow", name = "Зимний остров", unlock = 4, z = 2000, length = 8000, fric = 0.5, grip = 3, coin = 6, boost = 48},
	{id = "Moon", name = "Луна", unlock = 11, z = 4000, length = 10000, fric = 0.4, grip = 5, coin = 40, boost = 72},
}
C.LocById = {}
for _, l in ipairs(C.Locations) do C.LocById[l.id] = l end

-- income is per second at level 1, upgrade cost multiplier "cost"
C.Rarities = {
	{name = "Common", inc = 0.25, cost = 1, color = Color3.fromRGB(190,190,190)},
	{name = "Rare", inc = 1, cost = 3, color = Color3.fromRGB(60,160,255)},
	{name = "Epic", inc = 4, cost = 10, color = Color3.fromRGB(190,80,255)},
	{name = "Legendary", inc = 16, cost = 40, color = Color3.fromRGB(255,170,30)},
	{name = "Mythic", inc = 64, cost = 150, color = Color3.fromRGB(255,60,90)},
}
C.RarityIndex = {}
C.RarityByName = {}
for i, r in ipairs(C.Rarities) do C.RarityIndex[r.name] = i; C.RarityByName[r.name] = r end

local names = {
	Jungle = {Common = {"Banana Monkey", "Sleepy Sloth"}, Rare = {"Rainbow Toucan", "Emerald Frog"}, Epic = {"Mountain Gorilla"}, Legendary = {"Shadow Jaguar"}, Mythic = {"Golden Capybara"}},
	Snow = {Common = {"Emperor Penguin", "Snow Seal"}, Rare = {"Arctic Fox", "Frosty Yeti"}, Epic = {"Royal Walrus"}, Legendary = {"Polar Bear"}, Mythic = {"Ice Dragon Capybara"}},
	Moon = {Common = {"Alien Capybara", "Moon Bunny"}, Rare = {"Astro Cat", "Comet Dog"}, Epic = {"Cosmo Cow"}, Legendary = {"Meteor Wolf"}, Mythic = {"Lunar Phoenix"}},
}
C.Animals = {}
C.AnimalById = {}
C.AnimalsByLoc = {}
for _, loc in ipairs(C.Locations) do
	C.AnimalsByLoc[loc.id] = {}
	for _, rar in ipairs(C.Rarities) do
		C.AnimalsByLoc[loc.id][rar.name] = {}
		for i, n in ipairs(names[loc.id][rar.name]) do
			local a = {id = loc.id .. "_" .. rar.name .. "_" .. i, name = n, rarity = rar.name, loc = loc.id}
			table.insert(C.Animals, a)
			C.AnimalById[a.id] = a
			table.insert(C.AnimalsByLoc[loc.id][rar.name], a)
		end
	end
end

-- cases: price grows with the island, odds order = Common, Rare, Epic, Legendary, Mythic
local caseTiers = {
	{suffix = 1, base = 100, odds = {62, 28, 8, 1.8, 0.2}},
	{suffix = 2, base = 600, odds = {30, 38, 22, 8, 2}},
	{suffix = 3, base = 3000, odds = {10, 28, 34, 22, 6}},
}
local caseNames = {
	Jungle = {"Wood Crate", "Vine Case", "Golden Idol Case"},
	Snow = {"Frost Crate", "Glacier Case", "Aurora Case"},
	Moon = {"Moon Crate", "Crater Case", "Cosmic Case"},
}
local caseUnlock = {Jungle = {0, 1, 3}, Snow = {4, 6, 8}, Moon = {11, 13, 15}}
local caseColors = {Color3.fromRGB(150,100,55), Color3.fromRGB(80,200,255), Color3.fromRGB(255,200,50)}
C.Cases = {}
C.CaseById = {}
for _, loc in ipairs(C.Locations) do
	C.Cases[loc.id] = {}
	for i, t in ipairs(caseTiers) do
		local c = {id = loc.id .. "_Case" .. i, loc = loc.id, name = caseNames[loc.id][i], price = t.base * loc.coin,
			odds = t.odds, unlock = caseUnlock[loc.id][i], tier = i, color = caseColors[i]}
		table.insert(C.Cases[loc.id], c)
		C.CaseById[c.id] = c
	end
end

C.BASE_SLOTS = 6
C.MAX_SLOTS = 30
C.MAX_ANIMAL = 25
C.MAX_POWER = 30
C.MAX_SLIDE = 25
C.BOOST_SECONDS = 120
C.BOOST_MULT = 3

function C.AnimalIncome(a,lvl)
 return C.RarityByName[a.rarity].inc*C.LocById[a.loc].coin*(1+0.4*(lvl-1))
end
function C.AnimalUpCost(a, lvl)
	return math.floor(20 * C.RarityByName[a.rarity].cost * C.LocById[a.loc].coin * 1.6 ^ (lvl - 1))
end
function C.AnimalBoostCost(a, lvl) return math.floor(C.AnimalIncome(a, lvl) * 160) end
function C.SellPrice(a, lvl)
	return math.floor(20 * C.RarityByName[a.rarity].cost * C.LocById[a.loc].coin * (1 + 0.6 * (lvl - 1)))
end
function C.SlotCost(slots) return math.floor(260 * 1.22 ^ (slots - C.BASE_SLOTS) + (slots%10==0 and 600 or 0)) end
function C.PowerCost(l) return math.floor(50 * 1.5 ^ l) end
function C.SlideCost(l) return math.floor(70 * 1.55 ^ l) end
function C.XPForLevel(l) return 30 * l ^ 2 end
function C.LevelFromXP(xp) return math.floor(math.sqrt(xp / 30)) end

C.Trails = {
	{id = "Flame", name = "Flame Trail", cost = 400, c1 = Color3.fromRGB(255,200,40), c2 = Color3.fromRGB(255,40,0)},
	{id = "Toxic", name = "Toxic Trail", cost = 1200, c1 = Color3.fromRGB(170,255,60), c2 = Color3.fromRGB(0,140,60)},
	{id = "Galaxy", name = "Galaxy Trail", cost = 4000, c1 = Color3.fromRGB(80,200,255), c2 = Color3.fromRGB(200,60,255)},
	{id = "Rainbow", name = "Rainbow Trail", cost = 12000, rainbow = true},
}
C.TrailById = {}
for _, t in ipairs(C.Trails) do C.TrailById[t.id] = t end

-- Shared road profile: distance is X, steering is relative to the centre.
function C.TrackPoint(loc, x)
 local u = math.max(0, x - 80)
 local fade = math.min(1, u / 180)
 local amp = loc.id == "Moon" and 90 or (loc.id == "Snow" and 75 or 60)
 local z = loc.z + fade * amp * math.sin(u / 210)
 local y = 0.3 + fade * (18 * (1 - math.cos(u / 135)) + 7 * (1 - math.cos(u / 55)))
 return Vector3.new(x, y, z)
end
function C.CasePosition(loc,tier) return Vector3.new(-65-(tier-1)*48,0.3,loc.z-65) end
function C.PodiumPosition(loc,index)
 return Vector3.new(-48-((index-1)%6)*27,0.3,loc.z+57+math.floor((index-1)/6)*24)
end
return C

