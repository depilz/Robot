M = {}

local screen = require("View.helper.screen")

local lib2D = require("View.helper.lib2D")

local SoundPlayer = require("Scripts.soundPlayer")
SoundPlayer.loadSound("Clicks")


local robot
local Polygon = require("View.helper.Polygon")
local destinyMark

-- Data sctructures
local Graph = require("View.helper.Graph")
local binaryTree = require("View.helper.balanced-binary-tree")

--------------------------------------------------------------------------------
-- Screen Value
--------------------------------------------------------------------------------

local _AW = display.actualContentWidth
local _AH = display.actualContentHeight

local screenW = display.contentWidth
local screenH = display.contentHeight
local halfW = screenW*0.5
local halfH = screenH*0.5
local screenOriginX = display.screenOriginX
local screenOriginY = display.screenOriginY
local screenEdgeX = display.viewableContentWidth + -1* display.screenOriginX
local screenEdgeY = display.viewableContentHeight + -1* display.screenOriginY


--------------------------------------------------------------------------------
-- Map elements
--------------------------------------------------------------------------------
Map = {}

local function drawVertices(V, params)
  local params  = params or {}
  params.color  = params.color or {6,.3,.3}
  params.radius = params.radius or 5

  local index = params.index or 0
  index = index + 1

  local circle = display.newCircle( V[index].x, V[index].y, params.radius )
  circle:setFillColor(params.color[1], params.color[2], params.color[3])
  if index < #V then
    -- timer.performWithDelay(1000, function()
      drawVertices(V, {onComplete = params.onComplete, index = index})
    -- end)
  elseif params.onComplete then params.onComplete() end
end

--------------------------------------------------------------------------------
-- visibilityGraph methods
--------------------------------------------------------------------------------
local visibleVertices

function Map:repaintGraph()
  local visibilityGraph = self._visibilityGraph

  if self._edgesGroup then
    self._edgesGroup:removeSelf()
  end
  self._edgesGroup = display.newGroup()
  self.parent:insert(self._edgesGroup)

  for _,node in ipairs(visibilityGraph.nodes) do
    for _,edge in ipairs(node.adjacencyList) do
      local neighbor = edge.node
      edge.line = display.newLine(self._edgesGroup, node.value.x, node.value.y, neighbor.value.x, neighbor.value.y )
      edge.line:setStrokeColor(.3, 1, .3)
    end
  end
end

function Map:addObstacleEdges(obstacle)
  local v1
  local v2 = obstacle.vertices[#obstacle.vertices]

  for i = 1, #obstacle.vertices do
    v1 = v2
    v2 = obstacle.vertices[i]
    self._visibilityGraph:link(v1, v2, math.sqrt((v1.x-v2.x)^2, (v1.y-v2.y)^2))
  end
end

local function getVisibleVertices(p, candidates, obstacles, visibilityGraph)
	-- lib2D.sortPointsBySlope(candidates, p)
  visibleVertices = {} -- lista con los vértices visibles

  for _, vertex in ipairs(candidates) do
    local visible = true

    local i = 1
    while visible and i <= #obstacles do
      visible = not obstacles[i]:intersects(p, vertex)
      i = i + 1
    end

    if visible then
      table.insert( visibleVertices, vertex )
      visibilityGraph:link(p, vertex, math.sqrt((p.x-vertex.x)^2 + (p.y-vertex.y)^2))
    end
  end

	return visibleVertices
end

function Map:updateVisibilityOf(object)
  self._visibilityGraph:removeEdgesOf(object)

  getVisibleVertices(object, self._vertices, self._obstacles, self._visibilityGraph)

  self:repaintGraph()
end

function Map:update()
  local visibilityGraph = self._visibilityGraph
  local obstacles = self._obstacles

  visibilityGraph:removeEdges()

  for _, obstacle in ipairs(obstacles) do
    self:addObstacleEdges(obstacle)
  end

  local G = {}
  for i = #self._vertices, 1, -1 do
    local vertex = self._vertices[i]
    table.remove(self._vertices, i)
    table.insert(G, vertex)

    getVisibleVertices(vertex, self._vertices, obstacles, self._visibilityGraph)
	end
  self._vertices = G

  self:repaintGraph()
end

function Map:addObstacle(obstacle)
  for _,vertex in ipairs(obstacle.vertices) do
    table.insert( self._vertices, vertex )
    self._visibilityGraph:add(vertex)
  end

  self:update()
end

--------------------------------------------------------------------------------
-- Map methods
--------------------------------------------------------------------------------

local function backgroundTouched(event)
  SoundPlayer.playSound("Clicks")

  local obstacles = event.target._obstacles --> Map obstacles

  if #obstacles == 0 or obstacles[#obstacles].isPolygon then

    -------- Create a new Polygon ---------
    obstacles[#obstacles+1] = display.newGroup()
    obstacles[#obstacles].anchorX, obstacles[#obstacles].anchorY = 0, 0

    obstacles[#obstacles].vertices = {{x = event.x, y = event.y}}

  else
    local currentObst = obstacles[#obstacles]
    local vertices    = currentObst.vertices

    -- P1_Pn --> distance from p1 to the last polygon vertex
		local P1_Pn = math.sqrt((event.x - vertices[1].x)^2 + (event.y - vertices[1].y)^2)

    if P1_Pn < 10 then

      -------- enclose Polygon ---------
      obstacles[#obstacles]:removeSelf()
      obstacles[#obstacles] = Polygon.new({
        parent = sceneGroup,
        vertices = vertices
      })
      event.target:addObstacle(obstacles[#obstacles])

    else
      -------- add a new Vertex ---------
      vertices[#vertices+1] = {x = event.x, y = event.y}
      display.newLine(currentObst, event.x, event.y, vertices[#vertices-1].x,  vertices[#vertices-1].y)

    end
  end
end

function Map:requestPath(object, destiny)
  -- Object: Who is requesting the path --> {x, y, size}
  -- destiny: Where the object is try to go --> {x, y}

  self._visibilityGraph:add(object)
  self._visibilityGraph:add(destiny)
  table.insert( self._vertices, object )
  table.insert( self._vertices, destiny )

  self:update()

  return self._visibilityGraph:tracePath(object, destiny)
end

function M.new(params)
  local params = params or {}

  -- Set Params
  params.parent = params.parent
  params.x      = params.x      or screenOriginX
  params.y      = params.y      or screenOriginY
  params.width  = params.width  or screenW - 2*screenOriginX
  params.height = params.height or screenH - 2*screenOriginY

  local mapGroup = display.newGroup()
  if params.parent then
    params.parent:insert(mapGroup)
  end
  local map = display.newRect(mapGroup, params.x, params.y, params.width, params.height)

  map._visibilityGraph = Graph
  map._visibilityGraph:init()
  map._obstacles = {}
  map._vertices = {}

  if params.backgroundColor then
    map:setFillColor(params.backgroundColor[1], params.backgroundColor[2], params.backgroundColor[3])
  end

  for key,value in pairs(Map) do
      map[key] = value
  end

  map:addEventListener("tap", backgroundTouched)
  Runtime:addEventListener("transition ended", function(event)
    map:update()
  end)

  return map
end

return M
