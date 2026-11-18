local Config=require(game.ReplicatedStorage.GameConfig)
local Rules=require(game.ReplicatedStorage.ExpeditionRules)
local function defaults()
	return {training={},cake="Berry",music=0.35,effects=0.75,theme="Cottage",themes={Cottage=true},glow=true,schema=4,totalDistance=0,legacyWorlds={},tricks=0,journeys=0,achievements={},cupUntil=0,streak=0, coins = 0, power = 0, slide = 0, xp = 0, best = {}, animals = {}, trails = {}, trail = "", loc = "Jungle", rebirths = 0, boost = 0, slots = Config.BASE_SLOTS}
end

return function(saved)
 local d=defaults()
 if saved then
  for k,v in pairs(saved) do d[k]=v end
  if not saved.schema or saved.schema<4 then
   for _,loc in ipairs(Config.Locations) do
    if Config.LevelFromXP(d.xp)>=loc.unlock or d.loc==loc.id or (d.best[loc.id] or 0)>0 then d.legacyWorlds[loc.id]=true end
   end
   local known=0; for _,meters in pairs(d.best) do known+=meters end
   d.totalDistance=math.max(known,d.totalDistance)
   d.schema=4
  end
 end
 if not Config.LocById[d.loc] or not Rules.CanTravel(d,d.loc) then d.loc="Jungle" end
 d.slots = math.clamp(math.max(d.slots or Config.BASE_SLOTS,#d.animals),Config.BASE_SLOTS,Config.MAX_SLOTS)
 local used={}
 for _,a in ipairs(d.animals) do
  if type(a.podium)~="number" or a.podium%1~=0 or a.podium<1 or a.podium>d.slots or used[a.podium] then a.podium=nil else used[a.podium]=true end
 end
 return d
end
