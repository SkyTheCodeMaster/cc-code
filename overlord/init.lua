local modules = {}
for _,file in pairs(fs.list("modules")) do
  local f = fs.open(fs.combine("modules",file),"r")
  local contents = f.readAll()
  f.close()
  table.insert(modules,function() load(contents,"="..file,"t",_ENV)() end)
end

---@diagnostic disable-next-line: deprecated
parallel.waitForAll(table.unpack(modules))