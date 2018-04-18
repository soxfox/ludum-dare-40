local vector = {}

function vector.add(v1, v2)
  return {x = v1.x + v2.x, y = v1.y + v2.y}
end

function vector.sub(v1, v2)
  return {x = v1.x - v2.x, y = v1.y - v2.y}
end

return vector
