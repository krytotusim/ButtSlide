local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local PhysicsService = game:GetService("PhysicsService")

local Config = require(RS:WaitForChild("GameConfig"))
local Rules=require(RS:WaitForChild("ExpeditionRules"))
local Profile=require(SSS:WaitForChild("ProgressProfile"))
local Store=require(SSS:WaitForChild("ProgressStore"))
local Scenery=require(SSS:WaitForChild("IslandScenery"))
local Hub=require(SSS:WaitForChild("IslandHub"))
local Homes=require(SSS:WaitForChild("PetHomes"))
local Features=require(SSS:WaitForChild("TrailFeatures"))
local Builder = require(SSS:WaitForChild("TrackBuilder"))

-- remotes
local Remotes = RS:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder"); Remotes.Name = "Remotes"; Remotes.Parent = RS
end
for _, n in ipairs({"Launch", "Steer", "Action", "Sync", "Fx", "Buy", "Result", "Notify","Trick","Wallet"}) do
	if not Remotes:FindFirstChild(n) then
		local r = Instance.new("RemoteEvent"); r.Name = n; r.Parent = Remotes
	end
end

-- players do not collide with each other
pcall(function() PhysicsService:RegisterCollisionGroup("Players") end)
pcall(function() PhysicsService:CollisionGroupSetCollidable("Players", "Players", false) end)
local function setGroup(char)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then d.CollisionGroup = "Players" end
	end
end

-- disable streaming: huge track parts must never unload mid-run
pcall(function() workspace.StreamingEnabled = false end)

-- tracks (built in Studio; rebuilt here if the floor is missing)
local tracks = workspace:FindFirstChild("Tracks")
local function floorMissing()
	local s = tracks and tracks.Jungle and tracks.Jungle:FindFirstChild("Structure")
	return not (s and s:FindFirstChild("Floor") and tracks.Jungle:GetAttribute("ArtVersion")==2)
end
if not tracks or floorMissing() then
	if tracks then tracks:Destroy() end
	tracks = Instance.new("Folder"); tracks.Name = "Tracks"; tracks.Parent = workspace
	for _, loc in ipairs(Config.Locations) do Builder.Build(loc, tracks, task.wait) end
end

local Buckets, Slingshots, Spawns = {}, {}, {}
local movingMonsters = {}
for _, loc in ipairs(Config.Locations) do
	local folder = tracks:WaitForChild(loc.id)
	local old=folder:FindFirstChild("Catapult")
 if old then old:Destroy() end
 local sling=folder:FindFirstChild("Slingshot")
 if sling and sling:GetAttribute("Revision")~=2 then sling:Destroy(); sling=nil end
 Slingshots[loc.id]=sling or Builder.BuildStart(folder,loc)
 Hub.Build(folder,loc)
 Scenery.Build(folder,loc)
 Features.Build(folder,loc)
 local oldPods=folder:FindFirstChild("Podiums"); if oldPods then oldPods:Destroy() end
	Spawns[loc.id] = folder:FindFirstChild("Spawn_" .. loc.id)
	local b = {}
	Buckets[loc.id] = b
	for _, container in ipairs({folder.Obstacles, folder.Pickups}) do
		for _, o in ipairs(container:GetChildren()) do
			local e = {
				kind = o:GetAttribute("Kind"), x = o:GetAttribute("X"), z = o:GetAttribute("Z"),
				y = o:GetAttribute("Y") or Builder.FLOOR_Y, r = o:GetAttribute("R") or 4, h = o:GetAttribute("H") or 8,
				slow = o:GetAttribute("Slow") or 0.5, label = o:GetAttribute("Label") or "OUCH!",
			}
			if o:GetAttribute("Moving") then
    table.insert(movingMonsters,{entry=e, model=o, pivot=o:GetPivot(), z=e.z, phase=e.x/30})
   end
   local bi = math.floor(e.x / 60)
			b[bi] = b[bi] or {}
			table.insert(b[bi], e)
		end
	end
end



-- data

local D = {}
local departures=0
local runs, launching = {}, {}

local function totalIncome(d)
	local now, t = os.time(), 0
	for _, a in ipairs(d.animals) do
		local def = Config.AnimalById[a.id]
		if def and a.podium and a.podium>=1 and a.podium<=d.slots then
			local inc = Config.AnimalIncome(def, a.lvl)
			if (a.bu or 0) > now then inc *= Config.BOOST_MULT end
			t += inc
		end
	end
	return t
end

local function updateStats(plr)
	local d = D[plr]
	local ls = plr:FindFirstChild("leaderstats")
	if not d or not ls then return end
	ls.Coins.Value = math.floor(d.coins)
	ls.Level.Value = Config.LevelFromXP(d.xp)
	ls.Power.Value = d.power
	ls.Rebirths.Value = d.rebirths
	local best = 0
	for _, v in pairs(d.best) do if v > best then best = v end end
	ls.Best.Value = best
 ls.Tricks.Value=d.tricks; ls.Meters.Value=d.totalDistance; plr:SetAttribute("Island",d.loc); plr:SetAttribute("TotalMeters",d.totalDistance)
	plr:SetAttribute("Boost", d.boost)
	plr:SetAttribute("PowerCost", Config.PowerCost(d.power))
	plr:SetAttribute("BoostCost", Config.SlideCost(d.slide))
	plr:SetAttribute("RebirthCost", math.floor(1000 * 1.8 ^ d.rebirths))
end

local function updateTag(plr)
	local d = D[plr]
	local head = plr.Character and plr.Character:FindFirstChild("Head")
	local bb = head and head:FindFirstChild("LvTag")
	if bb and d then bb.LvLabel.Text = "Lv." .. Config.LevelFromXP(d.xp) end
end

local function makeTag(plr, char)
	local head = char:WaitForChild("Head", 5)
	if not head then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	local bb = Instance.new("BillboardGui")
	bb.Name = "LvTag"; bb.Adornee = head; bb.Size = UDim2.new(0,200,0,52); bb.StudsOffset = Vector3.new(0,3,0); bb.MaxDistance = 200
	local n = Instance.new("TextLabel"); n.Name = "NameLabel"; n.Size = UDim2.new(1,0,0.5,0); n.BackgroundTransparency = 1
	n.Text = plr.DisplayName; n.TextScaled = true; n.Font = Enum.Font.FredokaOne; n.TextColor3 = Color3.new(1,1,1); n.TextStrokeTransparency = 0; n.Parent = bb
	local l = Instance.new("TextLabel"); l.Name = "LvLabel"; l.Size = UDim2.new(1,0,0.5,0); l.Position = UDim2.new(0,0,0.5,0)
	l.BackgroundTransparency = 1; l.TextScaled = true; l.Font = Enum.Font.FredokaOne; l.TextColor3 = Color3.fromRGB(255,220,50); l.TextStrokeTransparency = 0; l.Parent = bb
	bb.Parent = head
	updateTag(plr)
end

local function applyTrail(plr)
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	local d = D[plr]
	if not root or not d then return end
	for _, n in ipairs({"TrailA0", "TrailA1", "RunTrail"}) do
		local o = root:FindFirstChild(n)
		if o then o:Destroy() end
	end
	local def = Config.TrailById[d.trail]
	if not def then return end
	local a0 = Instance.new("Attachment"); a0.Name = "TrailA0"; a0.Position = Vector3.new(0,1,0); a0.Parent = root
	local a1 = Instance.new("Attachment"); a1.Name = "TrailA1"; a1.Position = Vector3.new(0,-1,0); a1.Parent = root
	local t = Instance.new("Trail"); t.Name = "RunTrail"; t.Attachment0 = a0; t.Attachment1 = a1
	t.Lifetime = 1.1; t.LightEmission = 1
	t.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.1), NumberSequenceKeypoint.new(1,1)})
	if def.rainbow then
		t.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,60,60)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255,220,60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60,255,120)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60,160,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200,60,255)),
		})
	else
		t.Color = ColorSequence.new(def.c1, def.c2)
	end
	t.Parent = root
end

local function payload(d)
	return {
		coins = math.floor(d.coins), power = d.power, slide = d.slide, xp = d.xp, level = Config.LevelFromXP(d.xp),
		income = totalIncome(d), best = d.best, animals = d.animals, trails = d.trails, trail = d.trail, loc = d.loc, now = os.time(),
		training=d.training,cake=d.cake,music=d.music,effects=d.effects,theme=d.theme,themes=d.themes,glow=d.glow,daily=Rules.Daily(d),lastGift=d.lastGift,streak=d.streak,achievements=d.achievements,cupUntil=d.cupUntil,totalDistance=d.totalDistance,legacyWorlds=d.legacyWorlds,tricks=d.tricks,journeys=d.journeys,rebirths = d.rebirths, boost = d.boost, slots = d.slots,
	}
end
local function sync(plr)
	local d = D[plr]
	if d then
		Homes.Refresh(plr,d)
  updateStats(plr)
		Remotes.Sync:FireClient(plr, payload(d))
	end
end
local function fx(plr, data) Remotes.Fx:FireClient(plr, data) end

local function save(plr,release)
 local d=D[plr]
 if d and not Store.Save(plr.UserId,d,release) then warn("Could not save progress",plr.UserId) end
end

local function giveAnimal(d, def)
	for _, a in ipairs(d.animals) do
		if a.id == def.id then
			if a.lvl < Config.MAX_ANIMAL then a.lvl += 1 end
			return true, a.lvl
		end
	end
	if #d.animals >= d.slots then return nil, 0 end
	table.insert(d.animals, {id = def.id, lvl = 1, bu = 0})
	return false, 1
end

local function rollAnimal(locId, odds)
	local r, acc, chosen = math.random() * 100, 0, "Common"
	for i, rar in ipairs(Config.Rarities) do
		acc += (odds or Config.Cases[locId][1].odds)[i]
		if r <= acc then chosen = rar.name break end
	end
	local pool = Config.AnimalsByLoc[locId][chosen]
	return pool[math.random(#pool)]
end

-- ================= RUN LOGIC =================
local function endRun(plr, st)
	if st.ended then return end
	st.ended = true
	runs[plr] = nil
	
 local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
 if root then root.Anchored = false; root:SetAttribute("RunSpeed",nil); root:SetAttribute("Airborne",nil) end
	local d = D[plr]
	if not d or not plr.Parent then return end
	local loc = st.loc
	local dist = math.max(0, math.floor(st.maxX - st.x0))
	local placed=0
 for _,animal in ipairs(d.animals) do if animal.podium then placed+=1 end end
 local factor=Rules.Factor(dist,st.points,d.power,placed,st.cupcake,st.secrets,d.training,d.rebirths)
 local bossPrize=dist>loc.length*0.71+20 and not st.bossHit and 180*loc.coin or 0
 st.loot+=bossPrize
 local coins=math.floor(dist*0.25*Rules.RunRates[loc.id]*factor)+st.loot
 local before=d.totalDistance
 d.totalDistance+=dist; d.tricks+=st.completed; d.journeys+=1
 local daily=Rules.Daily(d); daily.runs+=1; daily.tricks+=st.completed; daily.meters+=dist
 local unlocked
 for _,world in ipairs(Config.Locations) do
  local threshold=Rules.WorldDistance[world.id]
  if before<threshold and d.totalDistance>=threshold and not d.legacyWorlds[world.id] then unlocked=world.name end
 end
 local prizes=0
 for _,goal in ipairs({{"first",d.journeys,1,75},{"km",d.totalDistance,1000,200},{"explorer",d.totalDistance,10000,500},{"moon",d.totalDistance,50000,1500},{"voyager",d.totalDistance,100000,5000},{"acrobat",d.tricks,100,800},{"legend",d.tricks,1000,3500}}) do
  if goal[2]>=goal[3] and not d.achievements[goal[1]] then d.achievements[goal[1]]=true; prizes+=goal[4] end
 end
 d.coins+=prizes
	local oldBest = d.best[loc.id] or 0
	local record = dist > oldBest and dist > 20
	local recBonus = 0
	if record then
		recBonus = math.floor(dist * 0.15 * Rules.RunRates[loc.id])
		d.best[loc.id] = dist
	end
	local xpGain = math.floor(dist / 6 + st.maxSpeed / 2)
	local oldLv = Config.LevelFromXP(d.xp)
	d.xp += xpGain
	local newLv = Config.LevelFromXP(d.xp)
	d.coins += coins + recBonus
	updateTag(plr)
	fx(plr, {type = "result", dist = dist, speed = math.floor(st.maxSpeed), coins = coins, record = record, recBonus = recBonus,
		mult=factor,tricks=st.completed,loot=st.loot,prizes=prizes,unlocked=unlocked,oldBest = oldBest, xp = xpGain, levelUp = (newLv > oldLv) and newLv or nil})
	sync(plr)
	plr:SetAttribute("Returning",true)
	task.spawn(function()
		task.wait(2.8)
		if plr.Parent then plr:SetAttribute("Returning",false) end
		if plr.Parent and plr.Character==st.character then
			plr.RespawnLocation = Spawns[d.loc]
			plr:LoadCharacter()
		end
	end)
end

local function handleHit(plr, st, e, root)
	local kind=e.kind
 if kind=="Friend" or kind=="Ramp" then
  st.speed=math.min(650,st.speed+(kind=="Friend" and (st.loc.boost+5*(D[plr].training.Impulse or 0)) or 8))
  st.phase="air"; st.vy=math.max(st.vy,kind=="Friend" and 48 or 66); st.y+=1
  fx(plr,{type=kind=="Friend" and "gas" or "boost",text=kind=="Friend" and "ПФ-Ф! Попутный газ" or "Трамплин!"})
 elseif kind=="Secret" then
  st.secrets=math.min(3,st.secrets+1); fx(plr,{type="boost",text="Тайные ворота • бонус к награде"})
 elseif kind=="Chest" then
  local roll=math.random(100); local amount=(roll<=65 and 25 or roll<=90 and 60 or roll<=98 and 140 or 350)*st.loc.coin
  st.loot+=amount; fx(plr,{type="boost",text="Тайник  +"..amount.." монет"})
 elseif kind=="Sweep" or kind=="Boss" then
  if kind=="Boss" then st.bossHit=true end
  st.speed*=kind=="Boss" and 0.52 or 0.70
  st.phase="air"; st.vy=35; st.y+=0.8
  st.vz=(root.Position.Z>=e.z and 1 or -1)*55
  fx(plr,{type="hit",text=kind=="Boss" and "Страж перевала!" or "Удар бампера!"})
 elseif kind=="Mire" or kind=="Obstacle" then
  st.speed*=kind=="Mire" and 0.74 or e.slow
  st.vz=(root.Position.Z>=e.z and 1 or -1)*30
  fx(plr,{type="hit",text=kind=="Mire" and "Вязкий участок" or e.label})
 elseif kind=="Boost" then
  st.speed=math.min(650,st.speed+st.loc.boost)
  if st.event=="Gold" then st.loot+=6*st.loc.coin end
  fx(plr,{type="boost",text="Разгон +"..st.loc.boost})
 end
end

local function stepRun(plr, st, dt)
 local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
 local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
 local d = D[plr]
 if not root or not hum or hum.Health <= 0 or not d or plr.Character~=st.character then endRun(plr,st) return end
 -- Bounded substeps keep collision checks reliable at high speed.
 local count = math.max(1,math.ceil(math.min(dt,0.25)/0.016))
 local h = math.min(dt,0.25)/count
 for _=1,count do
  st.t += h
  local loc = st.loc
  local q = Config.TrackPoint(loc,st.x)
  local q2 = Config.TrackPoint(loc,st.x+1)
  st.vz += (st.steer*(32+st.speed*0.16)-st.vz)*math.min(1,h*loc.grip)
  st.offset = math.clamp(st.offset + st.vz*h,-26,26)
  if st.phase == "slide" then
   local friction = 14*loc.fric*math.max(0.25,1-0.03*d.slide)
   st.speed = math.clamp(st.speed-(friction+65*(q2.Y-q.Y))*h,0,650)
  else
   st.vy -= (loc.id == "Moon" and 48 or 110)*h
   st.y += st.vy*h
  end
  st.x += st.speed*h / math.sqrt(1+(q2.Z-q.Z)^2)
  q = Config.TrackPoint(loc,st.x)
  if Features.InGorge(st.x,loc) and st.offset<13 and st.y<q.Y+3.1 and st.vy<=0 then
   fx(plr,{type="hit",text="Ущелье! Выбирай трамплин или правый мост"}); endRun(plr,st); return
  end
  if st.flip and st.t-st.flip.start>=st.flip.def.time then
   st.flip=nil; st.completed+=1; st.chain+=1; st.points+=1
   fx(plr,{type="combo",text=({"NICE!","GREAT!","INSANE!","AMAZING!","LEGENDARY!"})[math.min(st.chain,5)].." ×"..st.chain})
  end
  if st.phase=="air" and st.vy<0 and st.y<=q.Y+2.7 then
   if st.flip then st.points=math.max(0,st.points-0.5); st.flip=nil; fx(plr,{type="combo",text="Неполный оборот"})
   elseif st.chain>0 then st.points+=0.5; fx(plr,{type="combo",text="PERFECT! Чистая посадка"}) end
   st.chain=0
  end
  if st.phase == "slide" or (st.vy < 0 and st.y <= q.Y+2.7) then
   st.phase = "slide"; st.y = q.Y+2.7
  end
  local mark=Rules.DistanceFactor(st.x-st.x0)
  if mark>(st.mark or 1) then
   st.mark=mark; fx(plr,{type="milestone",text=string.format("×%g  •  %d м",mark,math.floor(st.x-st.x0))})
  end
  local pos = Vector3.new(st.x,st.y,q.Z+st.offset)
  local ahead = Config.TrackPoint(loc,st.x+4)
  local dir = Vector3.new(4,st.phase=="slide" and ahead.Y-q.Y or 0,ahead.Z-q.Z)
  root.CFrame = CFrame.lookAt(pos,pos+dir)
  if st.flip then
   local def=st.flip.def; local angle=math.pi*2*def.turns*math.clamp((st.t-st.flip.start)/def.time,0,1)
   root.CFrame*=CFrame.Angles((def.axis=="pitch" or def.axis=="mixed") and angle or 0,def.axis=="yaw" and angle or 0,(def.axis=="roll" or def.axis=="mixed") and angle or 0)
  end
  root:SetAttribute("Airborne",st.phase=="air")
  if st.t>=(st.hudAt or 0) then
   st.hudAt=st.t+0.10
   root:SetAttribute("RunSpeed",math.floor(st.speed))
   root:SetAttribute("RewardFactor",Rules.Factor(st.x-st.x0,st.points,d.power,st.placed,st.cupcake,st.secrets,d.training,d.rebirths))
  end
  st.maxX = math.max(st.maxX,st.x); st.maxSpeed = math.max(st.maxSpeed,st.speed)
  if st.speed < 3 then st.still += h else st.still=0 end
  if st.still > 0.7 or st.x >= loc.length-3 or st.t > 150 then endRun(plr,st) return end
  local bi = math.floor(st.x/60)
  for bucket=bi-1,bi+1 do
   for _,entry in ipairs(Buckets[loc.id][bucket] or {}) do
    if not st.touched[entry] and math.abs(entry.x-pos.X)<entry.r+2 and math.abs(entry.z-pos.Z)<entry.r+2
     and pos.Y-entry.y < entry.h and pos.Y >= entry.y-2 then
     st.touched[entry]=true; handleHit(plr,st,entry,root)
    end
   end
  end
 end
end

local monsterClock=0
RunService.Heartbeat:Connect(function(dt)
 monsterClock+=dt
 local now=os.clock()
 if monsterClock>=0.08 then
 monsterClock=0
 for _,m in ipairs(movingMonsters) do
  local amplitude=m.entry.kind=="Sweep" and 21 or m.entry.kind=="Boss" and 14 or 5
  local offset=math.sin(now*1.1+m.phase)*amplitude
  m.entry.z=m.z+offset
  local near=false
  for plr in pairs(D) do local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart"); if root and (root.Position-m.pivot.Position).Magnitude<500 then near=true break end end
  if near then m.model:PivotTo(m.pivot+Vector3.new(0,math.sin(now*2+m.phase)*0.25,offset)) end
 end
 end
	for plr, st in pairs(runs) do stepRun(plr, st, dt) end
end)

Remotes.Steer.OnServerEvent:Connect(function(plr, dir)
	local st = runs[plr]
	if st and type(dir) == "number" and dir == dir and math.abs(dir) < math.huge then st.steer = math.clamp(dir, -1, 1) end
end)

Remotes.Trick.OnServerEvent:Connect(function(plr)
 local st=runs[plr]
 if not st or st.phase~="air" or st.flip or st.attempts>=Rules.MaxTricks or st.t<st.nextTrick then return end
 local def=Rules.Tricks[1+st.attempts%#Rules.Tricks]
 st.attempts+=1; st.flip={def=def,start=st.t}; st.nextTrick=st.t+def.time+0.09
 fx(plr,{type="combo",text=def.name})
end)

local function launch(plr)
	local d = D[plr]
	if not d or runs[plr] or launching[plr] or plr:GetAttribute("Returning") or os.clock()<(plr:GetAttribute("RevealUntil") or 0) then return end
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end
	local loc = Config.LocById[d.loc]
	local cat=Slingshots[loc.id]
 if (root.Position-cat.Foundation.Position).Magnitude>46 then fx(plr,{type="message",text="Подойди к рогатке у спавна"}); return end
 if cat:GetAttribute("Busy") then fx(plr,{type="message",text="Рогатка натягивается. Ещё секунду!"}); return end
 cat:SetAttribute("Busy",true); launching[plr]=true
 root.Anchored=true; hum.Sit=true
 fx(plr,{type="pull",duration=Rules.PullTime})
 local elapsed=0
 while elapsed<Rules.PullTime+0.13 and root.Parent and hum.Health>0 and plr.Character==char do
  elapsed+=RunService.Heartbeat:Wait()
  local t=math.min(elapsed/Rules.PullTime,1)
  local draw=t*t*(3-2*t)
  if elapsed>Rules.PullTime then draw=1-1.22*math.min(1,(elapsed-Rules.PullTime)/0.13) end
  if t>=0.76 and not cat:GetAttribute("PullSpark") then cat:SetAttribute("PullSpark",true); cat.Cradle.Sparks:Emit(10) end
  local pos=Builder.Draw(cat,draw,d.power)
  root.CFrame=CFrame.lookAt(pos,pos+Vector3.xAxis)
 end
 cat.Cradle.Sparks:Emit(25)
 Builder.Draw(cat,0,d.power); cat:SetAttribute("PullSpark",nil); cat:SetAttribute("Busy",false); launching[plr]=nil
 if not root.Parent or hum.Health<=0 or plr.Character~=char or not D[plr] then
  if root.Parent then root.Anchored=false end
  return
 end
 local cake=d.cupUntil>os.time() and d.cake or nil
 local placed=0; for _,a in ipairs(d.animals) do if a.podium then placed+=1 end end
 local v=(116+12*d.power+2*d.boost)*(cake=="Citrus" and 1.18 or 1)
 runs[plr]={character=char,x=root.Position.X,y=root.Position.Y,vy=v*0.65,offset=0,loc=loc,x0=root.Position.X,phase="air",t=0,speed=v*0.82,steer=0,vz=0,still=0,
  touched={},maxX=root.Position.X,maxSpeed=v*0.82,nextTrick=0,attempts=0,completed=0,chain=0,points=0,placed=placed,loot=0,event=math.random(5)==1 and "Gold" or nil,secrets=0,cupcake=cake}
 fx(plr,{type="launch",startX=root.Position.X,event=runs[plr].event})
end
Remotes.Launch.OnServerEvent:Connect(launch)
for _,cat in pairs(Slingshots) do cat.Foundation.SlingPrompt.Triggered:Connect(launch) end

-- ================= SHOP / ACTIONS =================
Remotes.Action.OnServerEvent:Connect(function(plr, kind, arg)
	local d = D[plr]
	if not d or type(kind) ~= "string" or runs[plr] or launching[plr] then return end
 local now = os.clock()
 if now-(plr:GetAttribute("LastAction") or 0)<0.15 then return end
 plr:SetAttribute("LastAction",now)
 local daily=Rules.Daily(d)
 if (kind=="music" or kind=="effects") and type(arg)=="number" and (arg==0 or arg==0.35 or arg==0.75 or arg==1) then d[kind]=arg
 elseif kind=="Spawn" then
  local sp=Spawns[d.loc]; local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  if root and sp then local pos=sp.Position+Vector3.new(0,5,0); root.CFrame=CFrame.lookAt(pos,pos+Vector3.xAxis) end
 elseif kind=="Visit" and type(arg)=="number" then
  local guestRoot=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  local host=Players:GetPlayerByUserId(arg)
  if guestRoot and host and D[host] and D[host].loc==d.loc then
   local door=Homes.Door(host); if door then guestRoot.CFrame=CFrame.lookAt(door,door+Vector3.zAxis) end
  end
 elseif kind=="Home" then
  local pos=Homes.Door(plr); local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  if pos and root then root.CFrame=CFrame.lookAt(pos,pos+Vector3.zAxis) end
 elseif kind=="Glow" then d.glow=not d.glow
 elseif kind=="Theme" and type(arg)=="string" and Rules.Themes[arg] then
  local style=Rules.Themes[arg]
  if not d.themes[arg] and d.coins>=style.cost then d.coins-=style.cost; d.themes[arg]=true end
  if d.themes[arg] then d.theme=arg end
 elseif kind=="Gift" and d.lastGift~=daily.day then
  d.streak=d.lastGift==daily.day-1 and (d.streak%7+1) or 1
  d.lastGift=daily.day; local prize=70*d.streak; d.coins+=prize
  if d.streak==3 or d.streak==7 then d.cake="Berry"; d.cupUntil=math.max(os.time(),d.cupUntil)+300 end
  fx(plr,{type="message",text="День "..d.streak.." • +"..prize.." монет"})
 elseif kind=="Quest" and type(arg)=="string" and Rules.DailyGoals[arg] and daily[arg]>=Rules.DailyGoals[arg] and not daily.claimed[arg] then
  daily.claimed[arg]=true; d.coins+=Rules.DailyPrizes[arg]
 elseif kind=="Train" and type(arg)=="string" and Rules.Training[arg] then
  local lvl=d.training[arg] or 0; local cost=Rules.TrainingCost(arg,lvl)
  if lvl<Rules.Training[arg].limit and d.coins>=cost then d.training[arg]=lvl+1; d.coins-=cost; fx(plr,{type="message",text=Rules.Training[arg].name.."  •  ур. "..(lvl+1)}) end
 elseif kind=="Cupcake" and type(arg)=="string" and Rules.Cakes[arg] and d.cupUntil<=os.time() then
  local cake=Rules.Cakes[arg]
  if d.coins>=cake.price then
   d.coins-=cake.price; d.cake=arg; d.cupUntil=os.time()+300
   fx(plr,{type="message",text=cake.name.." кекс  •  "..cake.effect.." на 5 минут"})
  end
 elseif kind == "OpenCase" and type(arg)=="string" then
  local case = Config.CaseById[arg]
  if not case or case.loc~=d.loc or Config.LevelFromXP(d.xp)<case.unlock then return end
  local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  if not root or (root.Position-Config.CasePosition(Config.LocById[d.loc],case.tier)).Magnitude>22 then
   fx(plr,{type="message",text="Подойди к стойке этого кейса."}); return
  end
  if now < (plr:GetAttribute("RevealUntil") or 0) then return end
  if #d.animals>=d.slots then fx(plr,{type="message",text="Коллекция заполнена. В доме можно купить место."}) return end
  if d.coins<case.price then fx(plr,{type="message",text="Недостаточно монет"}) return end
  plr:SetAttribute("RevealUntil",now+4)
  d.coins-=case.price
  local def=rollAnimal(case.loc,case.odds)
  local dup,lvl=giveAnimal(d,def)
  fx(plr,{type="chest",purchased=true,id=def.id,caseId=case.id,name=def.name,rarity=def.rarity,dup=dup,lvl=lvl,bonus=0})
 elseif kind=="PlaceAnimal" and type(arg)=="table" and type(arg.id)=="string" then
  local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  local slot=arg.slot
  if type(slot)~="number" or slot~=slot or slot%1~=0 or slot<1 or slot>d.slots then return end
  local target=Homes.Position(plr,slot)
  if not target or not root or (root.Position-target).Magnitude>10 then fx(plr,{type="message",text="Подойди к месту в своём доме."}); return end
  local chosen
  for _,animal in ipairs(d.animals) do if animal.id==arg.id then chosen=animal break end end
  if not chosen then return end
  for _,animal in ipairs(d.animals) do if animal.podium==slot then animal.podium=nil end end
  chosen.podium=slot
  fx(plr,{type="message",text=Config.AnimalById[chosen.id].name.." • место "..slot})
 elseif kind=="UnplaceAnimal" and type(arg)=="string" then
  for _,animal in ipairs(d.animals) do if animal.id==arg then animal.podium=nil; break end end
 elseif kind=="BuySlot" then
  local cost=Config.SlotCost(d.slots)
  if d.slots<Config.MAX_SLOTS and d.coins>=cost then d.coins-=cost; d.slots+=1 end
 elseif kind=="SellAnimal" and type(arg)=="string" then
  for i,a in ipairs(d.animals) do
   if a.id==arg then d.coins+=Config.SellPrice(Config.AnimalById[a.id],a.lvl); table.remove(d.animals,i); break end
  end
 end
	if kind == "Power" then
		if d.power < Config.MAX_POWER then
			local c = Config.PowerCost(d.power)
			if d.coins >= c then d.coins -= c; d.power += 1 end
		end
	elseif kind == "Slide" then
		if d.slide < Config.MAX_SLIDE then
			local c = Config.SlideCost(d.slide)
			if d.coins >= c then d.coins -= c; d.slide += 1 end
		end
	elseif kind == "Trail" and type(arg) == "string" then
		local def = Config.TrailById[arg]
		if def then
			if d.trails[arg] then
				d.trail = (d.trail == arg) and "" or arg
			elseif d.coins >= def.cost then
				d.coins -= def.cost; d.trails[arg] = true; d.trail = arg
			end
			applyTrail(plr)
		end
	elseif (kind == "UpAnimal" or kind == "BoostAnimal") and type(arg) == "string" then
		for _, a in ipairs(d.animals) do
			if a.id == arg then
				local def = Config.AnimalById[a.id]
				if kind == "UpAnimal" and a.lvl < Config.MAX_ANIMAL then
					local c = Config.AnimalUpCost(def, a.lvl)
					if d.coins >= c then d.coins -= c; a.lvl += 1 end
				elseif kind == "BoostAnimal" and (a.bu or 0) <= os.time() then
					local c = Config.AnimalBoostCost(def, a.lvl)
					if d.coins >= c then d.coins -= c; a.bu = os.time() + Config.BOOST_SECONDS end
				end
				break
			end
		end
	elseif kind == "Travel" and type(arg) == "string" then
		local loc = Config.LocById[arg]
		if loc and not runs[plr] and not launching[plr] and Rules.CanTravel(d,loc.id) then
			d.loc = loc.id
			local sp = Spawns[loc.id]
			plr.RespawnLocation = sp
			local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if root and sp then local pos=sp.Position+Vector3.new(0,5,0); root.CFrame=CFrame.lookAt(pos,pos+Vector3.xAxis) end
		end
	end
	sync(plr)
end)

-- Buy remote (for client compatibility)
Remotes.Buy.OnServerEvent:Connect(function(plr, kind)
 local d = D[plr]
 if not d or type(kind)~="string" or runs[plr] or launching[plr] then return end
 if kind~="Power" and kind~="Boost" and kind~="Rebirth" then return end
 local now=os.clock()
 if now-(plr:GetAttribute("LastLegacyBuy") or 0)<0.2 then return end
 plr:SetAttribute("LastLegacyBuy",now)
	if kind == "Power" then
		if d.power < Config.MAX_POWER then
			local c = Config.PowerCost(d.power)
			if d.coins >= c then d.coins -= c; d.power += 1 end
		end
	elseif kind == "Boost" then
		if d.boost < 25 then
			local c = Config.SlideCost(d.boost)
			if d.coins >= c then d.coins -= c; d.boost += 1 end
		end
	elseif kind == "Rebirth" then
		local c = math.floor(1000 * 1.8 ^ d.rebirths)
		if d.coins >= c then
			d.coins -= c
			d.rebirths += 1
			d.power = 0
			d.slide = 0
			d.xp = 0
		end
	end
	sync(plr)
end)

-- Result remote (for client compatibility)
Remotes.Result.OnServerEvent:Connect(function(plr)
	-- handled by Fx
end)

-- Notify remote (for client compatibility)
Remotes.Notify.OnServerEvent:Connect(function(plr)
	-- handled by Fx
end)

Remotes.Sync.OnServerEvent:Connect(function(plr)
 local now=os.clock()
 if D[plr] and now>=(plr:GetAttribute("SyncAfter") or 0) then plr:SetAttribute("SyncAfter",now+1); sync(plr) end
end)

-- ================= PLAYERS =================
local function onCharacter(plr, char)
 task.spawn(function()
  local root=char:WaitForChild("HumanoidRootPart",5)
  local data=D[plr]
  local spawn=data and Spawns[data.loc]
  if root and spawn then local pos=spawn.Position+Vector3.new(0,5,0); root.CFrame=CFrame.lookAt(pos,pos+Vector3.xAxis) end
 end)
	setGroup(char)
	task.spawn(makeTag, plr, char)
	task.defer(applyTrail, plr)
end

local function join(plr)
 if plr:FindFirstChild("leaderstats") then return end
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"
	for _, n in ipairs({"Coins", "Level", "Best", "Power", "Rebirths","Meters","Tricks"}) do
		local v = Instance.new("IntValue"); v.Name = n; v.Parent = ls
	end
	ls.Parent = plr

		local ok,saved=Store.Load(plr.UserId)
 if not ok then plr:Kick("Прогресс занят или временно недоступен. Попробуй войти снова."); return end
 local d=Profile(saved)
 if not plr.Parent then Store.Save(plr.UserId,d,true); return end
 D[plr] = d
	plr:SetAttribute("Loaded", true)
	plr.RespawnLocation = Spawns[d.loc]

	plr.CharacterAdded:Connect(function(char) onCharacter(plr, char) end)
	if plr.Character then onCharacter(plr, plr.Character) end
	sync(plr)
end
Players.PlayerAdded:Connect(join)
for _,plr in Players:GetPlayers() do task.spawn(join,plr) end

Players.PlayerRemoving:Connect(function(plr)
	departures+=1
 Homes.Release(plr)
 local data=D[plr]; D[plr]=nil
 if data then Store.Save(plr.UserId,data,true) end
	runs[plr] = nil; launching[plr] = nil; D[plr] = nil; departures-=1
end)
game:BindToClose(function()
	local remaining=0
 for p in pairs(D) do remaining+=1; task.spawn(function() save(p,true); remaining-=1 end) end
 while remaining>0 or departures>0 do task.wait(0.1) end
end)

-- passive income from animals + periodic save
task.spawn(function()
	local tick = 0
	while true do
		task.wait(1)
		tick += 1
		for plr, d in pairs(D) do
			local inc = totalIncome(d)
			if inc > 0 then d.coins += inc end
   if tick%15==0 or not d.daily or d.daily.day~=math.floor(os.time()/86400) then
    sync(plr)
   else
    local stats=plr:FindFirstChild("leaderstats")
    if stats then stats.Coins.Value=math.floor(d.coins) end
    Remotes.Wallet:FireClient(plr,math.floor(d.coins),inc,os.time())
   end
		end
		if tick%5==0 then Hub.UpdateBoards(tracks) end
  if tick % 60 == 0 then
			for _, p in ipairs(Players:GetPlayers()) do task.spawn(save,p,false) end
		end
	end
end)

