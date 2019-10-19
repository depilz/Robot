local composer = require( "composer" )

local scene = composer.newScene()

local screen = require("View.helper.screen")

local Map = require("View.helper.map")
local Robot = require("View.helper.robot")

-- -----------------------------------------------------------------------------
-- Game Screen
-- First screen to show to player
-- -----------------------------------------------------------------------------

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

-----------------------------------
-- Scene
----------------------------------
local sceneGroup

local map
local robot
local destinyMark

------------------------------------
-- Configs
------------------------------------
local robotSpeed = 20/60  -- Pixels / Second

-- -----------------------------------------------------------------------------
-- Scene methods
-- -----------------------------------------------------------------------------
function scene:create( event )
    sceneGroup = self.view

    ------------------------------------------
    -- Scene elements
    ------------------------------------------

    ---------------
    map = Map.new({
      parent = sceneGroup,
      x = display.screenOriginX,
      y = display.screenOriginY,
      width = display.contentWidth - 2*display.screenOriginX,
      height = display.contentHeight,
      backgroundColor = {0,.1,.3}
    })
    map.anchorX, map.anchorY = 0, 0

    ---------------
    destinyMark = display.newImageRect(sceneGroup, "Images/destinyMark.png", 30, 30)
    destinyMark.x, destinyMark.y = 450, halfH
    -- destinyMark:addEventListener("touch", relocate)

    ---------------
    robot = Robot.new({
      parent = sceneGroup,
      speed = 60/60,
      x = 20,
      y = halfH,
      size = 30,
      map = map,
      destiny = destinyMark
    })

    ---------------- Buttons  -------------------

    local playButton = display.newImageRect("Images/play.png", 35, 35)
    playButton.anchorX, playButton.anchorY = .5, .5
    playButton.x, playButton.y = screenOriginX + 35, screenOriginY +25
    playButton:addEventListener("touch", function() return true end)
    playButton:addEventListener("tap", function()
      robot:advance()
      return true
    end)
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    if ( phase == "will" ) then
        composer.setVariable("loaded",true)
    elseif ( phase == "did" ) then
        Runtime:dispatchEvent{name="gameLoaded"}
    end
end

function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        SoundPlayer.fade(self.mapThemeHandler)
        -- Called when the scene is on screen (but is about to go off screen).
        -- Insert code here to "pause" the scene.
        -- Example: stop timers, stop animation, stop audio, etc.
    elseif ( phase == "did" ) then
        -- Called immediately after scene goes off screen.
    end
end

function scene:destroy( event )
    local sceneGroup = self.view
	-- if (randomBoxGroup) then
	-- 	sceneGroup:insert( randomBoxGroup )
	-- end
    Runtime:removeEventListener("enterFrame", updateUI)
    -- Called prior to the removal of scene's view ("sceneGroup").
    -- Insert code here to clean up the scene.
    -- Example: remove display objects, save state, etc.
end


-- -----------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -----------------------------------------------------------------------------

return scene
