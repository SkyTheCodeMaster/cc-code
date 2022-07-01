local r = require("cc.require")

local modules = {}
for _,file in pairs(fs.list("modules")) do
  local f = fs.open(fs.combine("modules",file),"r")
  local contents = f.readAll()
  f.close()
  local env = {
    shell=shell,
    multishell=multishell,
  }
  env.require,env.package = r.make(env,"/")
  table.insert(modules,function() pcall(load(contents,"="..file,"t",env)) end)
end

parallel.waitForAll(table.unpack(modules))