local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local store
if not RunService:IsStudio() then store=game:GetService("DataStoreService"):GetDataStore("LaunchGameV3") end
local Store={}
local tokens={}
local saving={}
local function update(key,transform)
 for attempt=1,3 do
  local ok,result=pcall(function() return store:UpdateAsync("p"..key,transform) end)
  if ok then return true,result end
  warn("Progress update failed",key,attempt,result)
  if attempt<3 then task.wait(attempt) end
 end
 return false,nil
end
function Store.Load(id)
 if not store then return true,nil end
 local token=Http:GenerateGUID(false)
 local ok,record=update(id,function(old)
  if old~=nil and type(old)~="table" then return nil end
  old=old or {}
  if old._lease and old._lease.untilTime>os.time() then return nil end
  old._lease={token=token,untilTime=os.time()+180}
  return old
 end)
 if not ok or not record then return false end
 tokens[id]=token
 record._lease=nil
 return true,record
end
function Store.Save(id,data,release)
 if not store then return true end
 while saving[id] do task.wait(0.1) end
 local token=tokens[id]
 if not token then return true end
 saving[id]=true
 local snapshot=Http:JSONDecode(Http:JSONEncode(data))
 local ok,result=update(id,function(old)
  if not old or not old._lease or old._lease.token~=token then return nil end
  if not release then snapshot._lease={token=token,untilTime=os.time()+180} end
  return snapshot
 end)
 saving[id]=nil
 if release or (ok and not result) then tokens[id]=nil end
 return ok and result~=nil
end
return Store
