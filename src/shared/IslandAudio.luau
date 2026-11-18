local SoundService=game:GetService("SoundService")
local Audio={}
local groups={}
for _,id in ipairs({"Music","Effects"}) do
 local group=Instance.new("SoundGroup"); group.Name="Expedition"..id; group.Volume=0.5; group.Parent=SoundService; groups[id]=group
end
local pools={}
local function play(group,clip,pitch,volume)
 if groups[group].Volume==0 then return end
 local key=group..clip
 local pool=pools[key]
 if not pool then pool={}; pools[key]=pool end
 local sound
 for _,s in ipairs(pool) do if not s.IsPlaying then sound=s; break end end
 if not sound then
  if #pool>=4 then return end
  sound=Instance.new("Sound"); sound.SoundId="rbxasset://sounds/"..clip; sound.SoundGroup=groups[group]; sound.Parent=SoundService; table.insert(pool,sound)
 end
 sound.PlaybackSpeed=pitch; sound.Volume=volume; sound:Play()
end
local effects={
 pull={"action_get_up.mp3",0.65,0.45},launch={"action_jump.mp3",0.78,0.7},gas={"action_swim.mp3",0.64,0.7},
 boost={"action_jump.mp3",1.55,0.45},hit={"action_jump_land.mp3",0.72,0.65},combo={"volume_slider.ogg",1.52,0.27},
 result={"volume_slider.ogg",0.95,0.45},chest={"volume_slider.ogg",1.24,0.45},message={"volume_slider.ogg",1.12,0.28},click={"volume_slider.ogg",1.85,0.13},
}
function Audio.Effect(name)
 local e=effects[name]; if e then play("Effects",e[1],e[2]*(name=="gas" and math.random(77,123)/100 or 1),e[3]) end
end
local melodies={
 Harbor={0,7,9,7,4,0,4,7,2,7,11,7,5,2,5,7},
 Jungle={0,0,7,10,7,3,5,7,0,3,7,12,10,7,5,3},
 Snow={12,7,4,2,0,4,7,11,9,7,4,7,2,4,7,2},
 Moon={0,7,14,10,3,10,17,14,5,12,19,14,3,7,10,7},
}
local track="Harbor"; local counter=0
function Audio.Scene(world,run)
 local nextTrack=run and world or "Harbor"
 if track~=nextTrack then track=nextTrack; counter=0 end
end
function Audio.Mix(music,effects)
 groups.Music.Volume=music; groups.Effects.Volume=effects
end
task.spawn(function()
 while true do
  local melody=melodies[track] or melodies.Harbor
  local i=counter%#melody+1
  play("Music","volume_slider.ogg",0.64*2^(melody[i]/12),0.12)
  if i%4==1 then play("Music","volume_slider.ogg",0.32*2^(melody[i]/12),0.10) end
  counter+=1
  task.wait(track=="Moon" and 0.68 or track=="Snow" and 0.52 or track=="Jungle" and 0.34 or 0.60)
 end
end)
return Audio
