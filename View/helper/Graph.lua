M = {}

function M:init()
  self.nodes = {}
end

function M:add(value)
  self.nodes[#self.nodes+1] = {
    value = value,
    adjacencyList = {}
  }
end

local function getNode(self, value)
  local node
  for _,nd in ipairs(self.nodes) do
      if nd.value == value then
        node = nd
        break
      end
  end
  return node
end

function M:removeEdgesOf(value)
  for _, edge in ipairs(getNode(self, value).adjacencyList) do
    if edge.line then
      edge.line:removeSelf()
      edge.line = nil
    end
    edge = nil
  end
end

function M:link(value1, value2, weight)
  local weight = weight or 1
  local node1
  local node2

  for _,v in ipairs(self.nodes) do
      if v.value == value1 then
        node1 = v
      elseif v.value == value2 then
        node2 = v
      end
      if node1 and node2 then break end
  end

  if node1 and node2 then
    node1.adjacencyList[#node1.adjacencyList+1] = {node = node2, weight = weight}
    node2.adjacencyList[#node2.adjacencyList+1] = {node = node1, weight = weight}
    return { node1.adjacencyList[#node1.adjacencyList], node2.adjacencyList[#node2.adjacencyList] }
  end

  return nil
end

function M:removeEdges()
  for _,node in ipairs(self.nodes) do
    node.adjacencyList = {}
  end
end

function M:tracePath(start, endPoint, id)
  local id = id or system.getTimer()
  local node = start
  local endPoint = endPoint

  if not start.adjacencyList then
    node = getNode(self, start)
  end
  if not endPoint.adjacencyList then
    endPoint = getNode(self, endPoint)
  end

  node.path = {
    value = node.value,
    id = id,
    distance = 9999999
  }

  for _, edge in ipairs(node.adjacencyList) do
    local neighbor = edge.node
    local weight = edge.weight
    if neighbor == endPoint then
      node.path.distance = weight
      node.path.next = {
        value = endPoint.value,
        id = id,
        distance = 0
      }
      break
    else
      if not neighbor.path or neighbor.path.id ~= id then
        self:tracePath(neighbor, endPoint, id)
      end

      if node.path.distance > weight + neighbor.path.distance then
        node.path.distance = weight + neighbor.path.distance
        node.path.next = neighbor.path
      end
    end
  end

  return node.path
end

return M
