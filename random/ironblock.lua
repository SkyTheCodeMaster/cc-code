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
  if turtle.suckUp(9) then
    turtle.transferTo(2,1)
    turtle.transferTo(3,1)
    turtle.transferTo(5,1)
    turtle.transferTo(6,1)
    turtle.transferTo(7,1)
    turtle.transferTo(9,1)
    turtle.transferTo(10,1)
    turtle.transferTo(11,1)
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