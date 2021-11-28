-- suck 2 iron from chest make shear drop down

while true do
  turtle.select(1)
  turtle.suck(2)
  turtle.transferTo(5,1)
  turtle.craft()
  while not turtle.dropDown() do
    sleep()
  end
end