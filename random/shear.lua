-- suck 2 iron from chest make shear drop down

for i=1,16 do
  if turtle.getItemDetail(i) then
    turtle.select(i)
    turtle.dropUp()
  end
end
turtle.select(1)

while true do
  turtle.select(1)
  if turtle.suck(2) then
    turtle.transferTo(6,1)
    turtle.craft()
    while not turtle.dropDown() do
      sleep()
    end
  else -- PANIC
    for i=1,16 do
      if turtle.getItemDetail(i) then
        turtle.select(i)
        turtle.dropUp()
      end
    end
    turtle.select(1)
  end
end