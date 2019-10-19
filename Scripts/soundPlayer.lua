local SoundPlayer = {}
local device = require("Scripts.device")

-- Configuration ---------------------------------------------------------------

-- Stinger configuration
local fadeOutDelay = 100
local fadeOutTime = 200
local fadeInDelay = 600
local fadeInTime = 200

-- -----------------------------------------------------------------------------

local soundTable = {}
local eventSoundTable = {}
audio.reserveChannels( 1 )
function SoundPlayer.loadSound(sound, long, ext)
    if not ext then ext = ".mp3" end
    if device.isAndroid and not device.isSimulator and not long then
        if not eventSoundTable[sound] then
            eventSoundTable[sound] = media.newEventSound("Sounds/"..sound..ext)
        end
    else
        if not soundTable[sound] then
            soundTable[sound] = audio.loadSound("Sounds/"..sound..ext)
        end
    end
end

function SoundPlayer.updateSettings()
  audio.setVolume( 1, { channel=1 } )
end

function SoundPlayer.playSound(sound, options)
    if device.isAndroid and not device.isSimulator then
        if not eventSoundTable[sound] then
            eventSoundTable[sound] = media.newEventSound("Sounds/"..sound..".mp3")
        end
        media.playEventSound(eventSoundTable[sound])
    else
       if not soundTable[sound] then
           soundTable[sound] = audio.loadSound("Sounds/"..sound..".mp3")
       end
       audio.play(soundTable[sound])
    end
end

function SoundPlayer.longSound(sound)
	if not soundTable[sound] then
		SoundPlayer.loadSound(sound,true)
	end
	return audio.play(soundTable[sound])
end

function SoundPlayer.playMusic(sound, stinger)
    SoundPlayer.updateSettings()
    if sound ~= nil then
        if not soundTable[sound] then
             SoundPlayer.loadSound(sound, true)
        end
    end
    if stinger then
        audio.play(soundTable[stinger])
          timer.performWithDelay(fadeOutDelay,function()
              audio.fade{channel=1, time=fadeOutTime, volume=0}
          end)
          if sound ~= nil then
              timer.performWithDelay(fadeInDelay,function()
                  audio.stop(1)
                  audio.play(soundTable[sound],{channel = 1, loops=-1 })
                  audio.fade{channel=1, time=fadeInTime, volume=1}
              end)
          end
    else
        audio.stop(1)
    	return audio.play(soundTable[sound],{
            channel = 1,
            loops=-1
        })
    end

    return 1
end

function SoundPlayer.stop(channel)
	audio.stop(channel)
end

function SoundPlayer.fade(handler)
    audio.fadeOut{channel=handler}
    timer.performWithDelay(1000,function()
        SoundPlayer.setVolume(1, handler)
    end)
end

function SoundPlayer.setVolume(v,channel)
    audio.setVolume(v,{channel=channel})
end

return SoundPlayer
