M = {}

--------------------------------------------------------------------------------
-- Polygon Methods
--------------------------------------------------------------------------------
local Polygon = {}

function Polygon:contains(p)
    local minX = self.vertices[1].x
    local maxX = self.vertices[1].x
    local minY = self.vertices[1].y
    local maxY = self.vertices[1].y

    for i = 1, #self.vertices do
        local q = self.vertices[i]
        minX = math.min( q.x, minX )
        maxX = math.max( q.x, maxX )
        minY = math.min( q.y, minY )
        maxY = math.max( q.y, maxY )
    end

    if p.x < minX or p.x > maxX or p.y < minY or p.y > maxY then
        return false
    end

    local inside = false
    for i = 1, #self.vertices do
      local j = i + 1
      if j > #self.vertices then j = 1 end
        if ((self.vertices[i].y > p.y ) ~= ( self.vertices[j].y > p.y ) and
             p.x < ( self.vertices[j].x - self.vertices[i].x ) * ( p.y - self.vertices[i].y ) / ( self.vertices[j].y - self.vertices[i].y ) + self.vertices[i].x )
        then
            inside = not inside
        end
    end

    return inside
end

local function getIntersectionScales(p1, p2, q1, q2)
  local dXP = p2.x-p1.x
	local dYP = p2.y-p1.y
	local dXQ = q2.x-q1.x
	local dYQ = q2.y-q1.y

	local de = (dXP*dYQ) - (dYP*dXQ)

	if math.abs(de) < 1.0E-10 then return {s = 999999, r = 999999} end -- line is in parallel

	local ax_cx = p1.x - q1.x
	local ay_cy = p1.y - q1.y
	local r = ((ay_cy) * (dXQ) - (ax_cx) * (dYQ)) / de
	local s = ((ay_cy) * (dXP) - (ax_cx) * (dYP)) / de

	return {s = s, r = r}
end

local function intersects(p1, p2, q1, q2)
  local intersection = getIntersectionScales(p1, p2, q1, q2)

  return (intersection.s < 1 and intersection.s > 0 and intersection.r < 1 and intersection.r > 0) --indicate there is intersection
end

local function relocate(event)
  local target = event.target
  local deltaX = event.x - (target.x + target.width*target.anchorX)
  local deltaY = event.y - (target.y + target.height*target.anchorX)

  if event.phase == "began" then
    target:toFront()
    target.targetStartX = target.x
    target.targetStartY = target.y

    Runtime:dispatchEvent{ name = "moving object" , target = target}

  elseif event.phase == "moved" then
    -- Move object to cursor point
    event.target.x = target.targetStartX + (event.x - event.xStart)
    event.target.y = target.targetStartY + (event.y - event.yStart)

  elseif event.phase == "ended" or event.phase == "cancelled" then
    for _,v in ipairs(target.vertices) do
      v.x = v.x + (event.x - event.xStart)
      v.y = v.y + (event.y - event.yStart)
    end

    target.targetStartX = nil
    target.targetStartY = nil

    Runtime:dispatchEvent{ name = "transition ended" }
  end

  return true
end

function Polygon:intersects(p1, p2)
  for i = 1, #self.vertices-1 do
    if intersects(p1, p2, self.vertices[i], self.vertices[i+1]) then
      return true
    end
  end
  if intersects(p1, p2, self.vertices[#self.vertices], self.vertices[1]) then
    return true
  end
  return self:contains({ x = (p1.x + p2.x)/2, y = (p1.y + p2.y)/2 })
end

--------------------------------------------------------------------------------
-- Polygon Factory
--------------------------------------------------------------------------------

function M.new(params)
  local params = params or {}

  -- Polygon Params
  params.parent  = params.parent or display.newGroup()
  params.onTap   = params.onTap or function() return true end
  params.onTouch = params.onTouch or function() return true end

  local groupX, groupY = 999, 999

  for _,v in ipairs(params.vertices) do
    groupX = math.min(v.x, groupX)
    groupY = math.min(v.y, groupY)
  end

  local vertices = {}
  for _,v in ipairs(params.vertices) do
    vertices[#vertices + 1] = v.x
    vertices[#vertices + 1] = v.y
  end

  local polygon = display.newPolygon(params.parent, groupX, groupY, vertices)
  polygon.anchorX, polygon.anchorY = 0, 0
  polygon:setFillColor(.7,0,0)
  polygon.vertices = params.vertices
  polygon.isPolygon = true

  polygon:addEventListener("tap", params.onTap)
  polygon:addEventListener("touch", relocate)
  polygon.isHitTestable = true

  for key,value in pairs(Polygon) do
      polygon[key] = value
  end

  Runtime:addEventListener("enterFrame", polygon)

  return polygon
end

return M
