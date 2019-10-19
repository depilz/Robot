local screen = require("View.helper.screen")
local composer = require("composer")

-- Global application setup
display.setStatusBar( display.HiddenStatusBar )
composer.recycleOnSceneChange = true
composer.setVariable("loaded", false)
_G.languaje = "Spanish"

local stage = display.getCurrentStage()
stage:insert( composer.stage )

-- Key handler
-- Called when a key event has been received
local function onKeyEvent( event )
    if ( event.keyName == "back" ) then
        native.showAlert( "Game", "Do you want to exit game?" , {"yes","no"}, function(event)
            if event.action == "clicked" and event.index == 1 then
                os.exit()
            end
        end )
        return true
    end
    return false
end

-- Add the key event listener
Runtime:addEventListener( "key", onKeyEvent )

local isGameLoaded = false

local loadingGroup = display.newGroup()

local background = display.newRect(display.screenOriginX, display.screenOriginY, display.contentWidth - 2*display.screenOriginX, display.contentHeight)
background:setFillColor(.1,.2,.4)
background.anchorX = 0
background.anchorY = 0
loadingGroup:insert(background)

loadingGroup:addEventListener("touch",function() return true end)
loadingGroup:addEventListener("touch",function() return true end)

Runtime:addEventListener("gameLoaded", function()
  transition.to(loadingGroup,{
      time = 100,
      alpha = 0,
      onComplete = function()
        loadingGroup:removeSelf()
      end})
end)

timer.performWithDelay(0,function()
    composer.gotoScene("View.game")
end)
