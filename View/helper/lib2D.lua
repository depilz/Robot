lib2D = {}

--------------------------------------------------------------------------------
-- helper algorithms
--------------------------------------------------------------------------------

local function printTable( t )
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

function lib2D.quicksort(t, comparingValue, start, endi)
  start, endi = start or 1, endi or #t
  --partition w.r.t. first element
  if(endi - start < 1) then return t end
  local pivot = start
  for i = start + 1, endi do
    local c1 = t[i][comparingValue] or t[i]
    local c2 = t[pivot][comparingValue] or t[pivot]
    if c1 <= c2 then
      if i == pivot + 1 then
        t[pivot],t[pivot+1] = t[pivot+1],t[pivot]
      else
        t[pivot],t[pivot+1],t[i] = t[i],t[pivot],t[pivot+1]
      end
      pivot = pivot + 1
    end
  end
  t = lib2D.quicksort(t, comparingValue, start, pivot - 1)
  return lib2D.quicksort(t, comparingValue, pivot + 1, endi)
end

--------------------------------------------------------------------------------
-- 2D methods
--------------------------------------------------------------------------------

function lib2D.sortPointsBySlope(array, origin)
  -- Set a slope value for all the Vertices using the ´p´ point as refence
  for i = 1, #array do
    local dX = (array[i].x - origin.x)
    local dY = -(array[i].y - origin.y)
    array[i].slope = math.tanh(dY/dX)*180/math.pi
    if dX < 0 then array[i].slope = array[i].slope + 180
		elseif dY < 0 then array[i].slope = array[i].slope + 360 end
  end
  -- sort array by Slope value
  lib2D.quicksort(array, "slope")
end

function lib2D.getNearestSegment(segmentList, origin, slopePoint)
  local nearestSegment = segmentList[1]

  local distanceScale = lib2D.getIntersectionScales(segmentList[1].p1, segmentList[1].p2, origin, slopePoint)
  distanceScale = distanceScale.r

  for i = 2, #segmentList do
    local dS = lib2D.getIntersectionScales(segmentList[i].p1, segmentList[i].p2, origin, slopePoint).r
    if dS < distanceScale then
      nearestSegment = segmentList[i]
      distanceScale = dS
    end
  end

  return nearestSegment
end

-- local function relocate(event)
--   local target = event.target
--   local deltaX = event.x - (target.x + target.width*target.anchorX)
--   local deltaY = event.y - (target.y + target.height*target.anchorX)
--
--   if event.phase == "began" then
--     target.targetStartX = target.x
--     target.targetStartY = target.y
--     if (deltaX < 10 and deltaX > -10) and
--       (deltaY < 10 and deltaY > -10) then
--       gameState = "scaling object"
--     else
--       gameState = "moving object"
--     end
--   elseif event.phase == "ended" or event.phase == "cancelled" then
--     gameState = "idle"
--   end
--
--   if gameState == "scaling object" then
--        target.width = target.width + deltaX + 5
--        target.height = target.height + deltaY + 5
--   elseif gameState == "moving object" then
--     event.target.x = target.targetStartX + (event.x - event.xStart)
--     event.target.y = target.targetStartY + (event.y - event.yStart)
--   end
-- end

return lib2D
