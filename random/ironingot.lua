-- suck 2 iron from chest make shear drop down

for i=1,16 do
  if turtle.getItemDetail(i) then
    turtle.select(i)
    turtle.dropDown()
  end
end
turtle.select(1)

while true do
  turtle.select(1)
  if turtle.suckUp(1) then
    turtle.craft()
    while not turtle.drop() do
      sleep()
    end
  else -- PANIC
    for i=1,16 do
      if turtle.getItemDetail(i) then
        turtle.select(i)
        turtle.dropDown()
      end
    end
    turtle.select(1)
  end
end