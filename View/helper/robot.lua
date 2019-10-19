M = {}
--------------------------------------------------------------------------------
-- Robot Methods
--------------------------------------------------------------------------------
local Robot = {}

function Robot:setRoute(route)
  self._route = route
end

function Robot:idle()
  self.enterFrame = function() return true end
end

function Robot:distanceTo(object)
  local minX = math.min((self.x-self.width*self.anchorX)+self.width*0  - (object.x-object.width*object.anchorX)+object.width*0,
                        (self.x-self.width*self.anchorX)+self.width*0  - (object.x-object.width*object.anchorX)+object.width*1,
                        (self.x-self.width*self.anchorX)+self.width*1  - (object.x-object.width*object.anchorX)+object.width*0,
                        (self.x-self.width*self.anchorX)+self.width*1  - (object.x-object.width*object.anchorX)+object.width*1)

  local minY = math.min((self.y-self.height*self.anchorY)+self.height*0  - (object.y-object.height*object.anchorY)+object.height*0,
                        (self.y-self.height*self.anchorY)+self.height*0  - (object.y-object.height*object.anchorY)+object.height*1,
                        (self.y-self.height*self.anchorY)+self.height*1  - (object.y-object.height*object.anchorY)+object.height*0,
                        (self.y-self.height*self.anchorY)+self.height*1  - (object.y-object.height*object.anchorY)+object.height*1)

  return math.sqrt(minX*minX + minY*minY)
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
    target.targetStartX = nil
    target.targetStartY = nil

    Runtime:dispatchEvent{ name = "transition ended" }
  end

  return true
end

function Robot:advance()
  if not self._route then
    self._route = self._map:requestPath(self, self.destiny)
  end

  self.enterFrame = self.advance

  local dX = self._route.value.x-self.x
  local dY = self._route.value.y-self.y

  -- if the robot needs less than one step to complete the path segment
  -- then, the robot moves to the next segment
  if math.sqrt(dX^2+dY^2) < self._speed then
    self:idle()

    self._route = self._route.next

    if self._route then
      local dX = self._route.value.x-self.x
      local dY = self._route.value.y-self.y

      if dY ~= 0 or dX ~= 0 then
        self._m = dY / dX
        self._k = math.sqrt(1/(1+self._m^2))*(dX/math.abs(dX))

        local rotation = math.tanh(self._m)*180/math.pi
        if dX < 0 then rotation = rotation + 180 end
        if rotation - self.rotation > 180 then rotation = rotation - 360 end

        transition.to( self, {
          time = math.abs(4*(rotation-self.rotation)/self._maxSpeed),
          rotation = rotation,
          onComplete = function() self:advance() end
        })
      end
    end
  else
    if not self._k then
      self._m = dY / dX
      self._k = math.sqrt(1/(1+self._m^2))*(dX/math.abs(dX))
    end
    self.x = self.x + self._k*self._speed
    self.y = self.y + self._m*self._k*self._speed
    -- self._map:updateVisibilityOf(self)
  end
end

function Robot:pause()
  Runtime:removeEventListener("enterFrame", self)
end

function Robot:resume()
  Runtime:addEventListener("enterFrame", self)
end

--------------------------------------------------------------------------------
-- Robot Factory
--------------------------------------------------------------------------------

function M.new(params)
  local params = params or {}

  -- Robot Params
  params.parent  = params.parent or display.newGroup()
  params.x       = params.x or 0
  params.y       = params.y or 0
  params.size    = params.size or 30
  params.onTap   = params.onTap or function() return true end
  params.onTouch = params.onTouch or function() return true end

  -- Robot creation
  local robot = display.newRect( params.parent, params.x, params.y, params.size, params.size )
  robot._speed    = params.speed or 60/60 -- pixels / FPS
  robot._maxSpeed = params.speed or 60/60
  robot._map      = params.map
  robot.destiny   = params.destiny

  robot:setFillColor(1)

  robot:addEventListener("tap", params.onTap)
  robot:addEventListener("touch", relocate)

  for key,value in pairs(Robot) do
      robot[key] = value
  end

  robot:idle()
  Runtime:addEventListener("enterFrame", robot)

  local function addDangerousObject(event)
    local function fixObject()
      local angle = math.abs(math.tanh(event.target.y-robot.y / event.target.x-robot.x)*180/math.pi - robot.rotation)
      if event.target.x-robot.x < 0 then angle = angle + 180 end
      if angle < 30 then
        local distance = robot:distanceTo(event.target)
        if robot._maxSpeed > (distance-80)/40 then
          robot._speed = (distance-80)/40
        end
        if robot._speed < 0 then robot._speed = 0 end
      elseif angle < 90 then
        local distance = robot:distanceTo(event.target)
        if robot._maxSpeed > robot._maxSpeed*(angle/90) + ((distance-80)/40)*((90-angle)/90) then
          robot._speed = robot._maxSpeed*(angle/90) + ((distance-80)/40)*((90-angle)/90)
        end
        if robot._speed < 0 then robot._speed = 0 end
      else
        robot._speed = robot._maxSpeed
      end
    end

    local function objectIsSafe(event)
      if event.target == object then
        robot._speed = robot._maxSpeed
        Runtime:removeEventListener("enterFrame", fixObject)
        Runtime:removeEventListener("objectIsSafe", objectIsSafe)
      end
    end

    Runtime:addEventListener("enterFrame", fixObject)
    Runtime:addEventListener("objectIsSafe", objectIsSafe)
  end

  Runtime:addEventListener("moving object", addDangerousObject)

  Runtime:addEventListener("transition ended", function(event)
    Runtime:dispatchEvent{name = "objectIsSafe", target = event.target}
    robot._route = robot._map:requestPath(robot, robot.destiny)
  end)

  return robot
end

return M
