local Rules = {}
Rules.WorldDistance = {Jungle = 0, Snow = 10000, Moon = 50000}
Rules.RunRates={Jungle=1,Snow=1.9,Moon=3.2}
Rules.Goal = 100000
Rules.PullTime = 1.15
Rules.MaxTricks = 10
Rules.Tricks = {
 {name="Сальто", axis="pitch", turns=1, time=0.44},
 {name="Штопор", axis="roll", turns=1, time=0.48},
 {name="Обратное сальто", axis="pitch", turns=-1, time=0.48},
 {name="Двойное сальто", axis="pitch", turns=2, time=0.70},
 {name="Винт", axis="yaw", turns=1, time=0.50},
 {name="Каскад", axis="mixed", turns=1, time=0.65},
}
Rules.Marks = {{0,1},{500,1.5},{1000,2},{2500,3},{5000,5},{10000,8}}
Rules.DailyGoals = {runs=3, meters=1500, tricks=4}
Rules.DailyPrizes = {runs=160, meters=220, tricks=140}
function Rules.DistanceFactor(meters)
 local value=1
 for _,mark in ipairs(Rules.Marks) do
  if meters<mark[1] then break end
  value=mark[2]
 end
 return value
end
Rules.TrainingOrder={"Income","Acrobat","Range","Impulse"}
Rules.Training={
 Income={name="Монетный талисман",base=380,description="+10% к базовой награде",limit=10},
 Acrobat={name="Школа сальто",base=220,description="+12% к очкам трюков",limit=6},
 Range={name="Дальний рейс",base=480,description="+8% после 500 м",limit=6},
 Impulse={name="Попутный импульс",base=190,description="+5 скорости от доброго моба",limit=8},
}
function Rules.TrainingCost(id,level) return math.floor(Rules.Training[id].base*1.55^level) end
Rules.CakeOrder={"Berry","Citrus","Mint"}
Rules.Cakes={
 Berry={name="Ягодный",price=120,effect="+35% к награде",color=Color3.fromRGB(186,94,131)},
 Citrus={name="Цитрусовый",price=150,effect="+18% скорости старта",color=Color3.fromRGB(191,136,63)},
 Mint={name="Мятный",price=100,effect="+35% к очкам трюков",color=Color3.fromRGB(61,146,124)},
}
function Rules.Factor(meters, tricks, power, pets, cupcake, secrets,training,rebirths)
 training=training or {}
 tricks*=1+0.12*(training.Acrobat or 0)+(cupcake=="Mint" and 0.35 or 0)
 local bonus=math.min(tricks*0.09,0.9)+math.min(power*0.01,0.3)+math.min(pets*0.025,0.25)+(cupcake=="Berry" and 0.35 or 0)+math.min(secrets*0.12,0.36)
 bonus+=0.1*(training.Income or 0)+(meters>=500 and 0.08*(training.Range or 0) or 0)+math.min(0.5,(rebirths or 0)*0.05)
 return math.min(12,Rules.DistanceFactor(meters)*(1+bonus))
end
function Rules.CanTravel(data,id)
 return data.totalDistance>=Rules.WorldDistance[id] or data.legacyWorlds[id]==true
end
function Rules.Daily(data)
 local day=math.floor(os.time()/86400)
 if not data.daily or data.daily.day~=day then data.daily={day=day,runs=0,meters=0,tricks=0,claimed={}} end
 return data.daily
end
Rules.ThemeOrder={"Cottage","Neon","Lab","Gold","Cosmos"}
Rules.Themes={}
for _,v in ipairs({
 {"Cottage","Лесной дом",0,0x715843,0xffcd99,Enum.Material.WoodPlanks},
 {"Neon","Неоновый клуб",850,0x29404e,0x65ffc9,Enum.Material.Slate},
 {"Lab","Лаборатория",1600,0xb8cbd2,0x3ca4bf,Enum.Material.Metal},
 {"Gold","Золотой павильон",4200,0x80542e,0xffdb79,Enum.Material.Marble},
 {"Cosmos","Обсерватория",6200,0x443959,0xc9a3ff,Enum.Material.Slate},
}) do
 Rules.Themes[v[1]]={name=v[2],cost=v[3],wall=Color3.fromHex(string.format("%06x",v[4])),accent=Color3.fromHex(string.format("%06x",v[5])),material=v[6]}
end
return Rules
