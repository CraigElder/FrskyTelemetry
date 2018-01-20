--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for Taranis X9D+
--
-- Copyright (C) 2018. Alessandro Apostoli
--   https://github.com/yaapu
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY, without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses>.
-- 
-- Passthrough protocol reference:
--   https://cdn.rawgit.com/ArduPilot/ardupilot_wiki/33cd0c2c/images/FrSky_Passthrough_protocol.xlsx
--
-- Borrowed some code from the LI-xx BATTCHECK v3.30 script
--  http://frskytaranis.forumactif.org/t2800-lua-download-un-testeur-de-batterie-sur-la-radio


local cellfull, cellempty = 4.2, 3.00       
local cell = {0, 0, 0, 0, 0 ,0}                                                  
local cellsumfull, cellsumempty, cellsumtype, cellsum = 0, 0, 0, 0               

local i, cellmin, cellresult = 0, cellfull, 0, 0                                  
local thrOut = 0
local voltage = 0

--[[
	MAV_TYPE_GENERIC=0, /* Generic micro air vehicle. | */
	MAV_TYPE_FIXED_WING=1, /* Fixed wing aircraft. | */
	MAV_TYPE_QUADROTOR=2, /* Quadrotor | */
	MAV_TYPE_COAXIAL=3, /* Coaxial helicopter | */
	MAV_TYPE_HELICOPTER=4, /* Normal helicopter with tail rotor. | */
	MAV_TYPE_ANTENNA_TRACKER=5, /* Ground installation | */
	MAV_TYPE_GCS=6, /* Operator control unit / ground control station | */
	MAV_TYPE_AIRSHIP=7, /* Airship, controlled | */
	MAV_TYPE_FREE_BALLOON=8, /* Free balloon, uncontrolled | */
	MAV_TYPE_ROCKET=9, /* Rocket | */
	MAV_TYPE_GROUND_ROVER=10, /* Ground rover | */
	MAV_TYPE_SURFACE_BOAT=11, /* Surface vessel, boat, ship | */
	MAV_TYPE_SUBMARINE=12, /* Submarine | */
	MAV_TYPE_HEXAROTOR=13, /* Hexarotor | */
	MAV_TYPE_OCTOROTOR=14, /* Octorotor | */
	MAV_TYPE_TRICOPTER=15, /* Tricopter | */
	MAV_TYPE_FLAPPING_WING=16, /* Flapping wing | */
	MAV_TYPE_KITE=17, /* Kite | */
	MAV_TYPE_ONBOARD_CONTROLLER=18, /* Onboard companion controller | */
	MAV_TYPE_VTOL_DUOROTOR=19, /* Two-rotor VTOL using control surfaces in vertical operation in addition. Tailsitter. | */
	MAV_TYPE_VTOL_QUADROTOR=20, /* Quad-rotor VTOL using a V-shaped quad config in vertical operation. Tailsitter. | */
	MAV_TYPE_VTOL_TILTROTOR=21, /* Tiltrotor VTOL | */
	MAV_TYPE_VTOL_RESERVED2=22, /* VTOL reserved 2 | */
	MAV_TYPE_VTOL_RESERVED3=23, /* VTOL reserved 3 | */
	MAV_TYPE_VTOL_RESERVED4=24, /* VTOL reserved 4 | */
	MAV_TYPE_VTOL_RESERVED5=25, /* VTOL reserved 5 | */
	MAV_TYPE_GIMBAL=26, /* Onboard gimbal | */
	MAV_TYPE_ADSB=27, /* Onboard ADSB peripheral | */
	MAV_TYPE_PARAFOIL=28, /* Steerable, nonrigid airfoil | */
	MAV_TYPE_DODECAROTOR=29, /* Dodecarotor | */
]]--

local frameTypes = {}
	frameTypes[0] = "copter"
	frameTypes[1] = "plane"
	frameTypes[2] = "copter"
	frameTypes[3] = "copter"
	frameTypes[4] = "copter"
	frameTypes[5] = ""
	frameTypes[6] = ""
	frameTypes[7] = ""
	frameTypes[8] = ""
	frameTypes[9] = ""
	frameTypes[10] = "rover"
	frameTypes[11] = "boat"
	frameTypes[12] = ""
	frameTypes[13] = "copter"
	frameTypes[14] = "copter"
	frameTypes[15] = "copter"
	frameTypes[16] = "plane"
	frameTypes[17] = ""
	frameTypes[18] = ""
	frameTypes[19] = "plane"
	frameTypes[20] = "plane"
	frameTypes[21] = "plane"
	frameTypes[22] = "plane"
	frameTypes[23] = "plane"
	frameTypes[24] = "plane"
	frameTypes[25] = "plane"
	frameTypes[26] = ""
	frameTypes[27] = ""
	frameTypes[28] = "plane"
	frameTypes[29] = "copter"
	frameTypes[30] = ""

local flightModes = {}
	flightModes["copter"] = {}
	flightModes["plane"] = {}
	flightModes["rover"] = {}	
	-- copter flight modes
	flightModes["copter"][0]=""
	flightModes["copter"][1]="Stabilize"
	flightModes["copter"][2]="Acro"
	flightModes["copter"][3]="AltHold"
	flightModes["copter"][4]="Auto"
	flightModes["copter"][5]="Guided"
	flightModes["copter"][6]="Loiter"
	flightModes["copter"][7]="RTL"
	flightModes["copter"][8]="Circle"
	flightModes["copter"][9]=""
	flightModes["copter"][10]="Land"
	flightModes["copter"][11]=""
	flightModes["copter"][12]="Drift"
	flightModes["copter"][13]=""
	flightModes["copter"][14]="Sport"
	flightModes["copter"][15]="Flip"
	flightModes["copter"][16]="AutoTune"
	flightModes["copter"][17]="PosHold"
	flightModes["copter"][18]="Brake"
	flightModes["copter"][19]="Throw"
	flightModes["copter"][20]="Avoid ADSB"
	flightModes["copter"][21]="Guided NO GPS"
	-- plane flight modes
	flightModes["plane"][0]="Manual"
	flightModes["plane"][1]="Circle"
	flightModes["plane"][2]="Stabilize"
	flightModes["plane"][3]="Training"
	flightModes["plane"][4]="Acro"
	flightModes["plane"][5]="FlyByWireA"
	flightModes["plane"][6]="FlyByWireB"
	flightModes["plane"][7]="Cruise"
	flightModes["plane"][8]="Autotune"
	flightModes["plane"][9]=""
	flightModes["plane"][10]="Auto"
	flightModes["plane"][11]="RTL"
	flightModes["plane"][12]="Loiter"
	flightModes["plane"][13]=""
	flightModes["plane"][14]="Avoid ADSB"
	flightModes["plane"][15]="Guided"
	flightModes["plane"][16]="Initializing"
	flightModes["plane"][17]="QStabilize"
	flightModes["plane"][18]="QHover"
	flightModes["plane"][19]="QLoiter"
	flightModes["plane"][20]="Qland"
	flightModes["plane"][21]="QRTL"
	-- rover flight modes
	flightModes["rover"][0]="Manual"
	flightModes["rover"][1]="Acro"
	flightModes["rover"][2]=""
	flightModes["rover"][3]="Steering"
	flightModes["rover"][4]="Hold"
	flightModes["rover"][5]=""
	flightModes["rover"][6]=""
	flightModes["rover"][7]=""
	flightModes["rover"][8]=""
	flightModes["rover"][9]=""
	flightModes["rover"][10]="Auto"
	flightModes["rover"][11]="RTL"
	flightModes["rover"][12]="SmartRTL"
	flightModes["rover"][13]=""
	flightModes["rover"][14]=""
	flightModes["rover"][15]="Guided"
	flightModes["rover"][16]="Initializing"
	flightModes["rover"][17]=""
	flightModes["rover"][18]=""
	flightModes["rover"][19]=""
	flightModes["rover"][20]=""
	flightModes["rover"][21]=""

local soundFileBasePath = "/SOUNDS/yaapu0/en"
local soundFiles = {}
	-- battery
	soundFiles["bat5"] = "bat5.wav"
	soundFiles["bat10"] = "bat10.wav"
	soundFiles["bat15"] = "bat15.wav"
	soundFiles["bat20"] = "bat20.wav"
	soundFiles["bat25"] = "bat25.wav"
	soundFiles["bat30"] = "bat30.wav"
	soundFiles["bat40"] = "bat40.wav"
	soundFiles["bat50"] = "bat50.wav"
	soundFiles["bat60"] = "bat60.wav"	
	soundFiles["bat70"] = "bat70.wav"
	soundFiles["bat80"] = "bat80.wav"
	soundFiles["bat90"] = "bat90.wav"	
	-- gps
	soundFiles["gpsfix"] = "gpsfix.wav"
	soundFiles["gpsnofix"] = "gpsnofix.wav"
	-- failsafe
	soundFiles["lowbat"] = "lowbat.wav"
	soundFiles["ekf"] = "ekf.wav"
	-- events
	soundFiles["yaapu"] = "yaapu.wav"
	soundFiles["landing"] = "landing.wav"
	soundFiles["armed"] = "armed.wav"
	soundFiles["disarmed"] = "disarmed.wav"

local soundFilesByFrameTypeAndFlightMode = {}
	soundFilesByFrameTypeAndFlightMode["copter"] = {}
	soundFilesByFrameTypeAndFlightMode["plane"] = {}
	soundFilesByFrameTypeAndFlightMode["rover"] = {}
	-- Copter
	soundFilesByFrameTypeAndFlightMode["copter"][0]=""
	soundFilesByFrameTypeAndFlightMode["copter"][1]="stabilize.wav"	
	soundFilesByFrameTypeAndFlightMode["copter"][2]="acro.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][3]="althold.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][4]="auto.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][5]="guided.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][6]="loiter.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][7]="rtl.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][8]="circle.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][9]=""
	soundFilesByFrameTypeAndFlightMode["copter"][10]="land.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][11]=""
	soundFilesByFrameTypeAndFlightMode["copter"][12]="drift.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][13]=""
	soundFilesByFrameTypeAndFlightMode["copter"][14]="sport.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][15]="flip.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][16]="loiter.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][17]="poshold.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][18]="brake"
	soundFilesByFrameTypeAndFlightMode["copter"][19]="throw.wav"
	soundFilesByFrameTypeAndFlightMode["copter"][20]="avoidadbs"
	soundFilesByFrameTypeAndFlightMode["copter"][21]="guidednogps"
	-- Plane
	soundFilesByFrameTypeAndFlightMode["plane"][0]="manual.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][1]="circle.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][2]="stabilize.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][3]="training.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][4]="acro.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][5]="flybywirea.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][6]="flybywireb.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][7]="cruise.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][8]="autotune.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][9]=""
	soundFilesByFrameTypeAndFlightMode["plane"][10]="auto.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][11]="rtl.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][12]="loiter.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][13]=""
	soundFilesByFrameTypeAndFlightMode["plane"][14]="avoidadbs"
	soundFilesByFrameTypeAndFlightMode["plane"][15]="guided.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][16]="initializing.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][17]="qstabilize.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][18]="qhover.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][19]="qloiter.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][20]="qland.wav"
	soundFilesByFrameTypeAndFlightMode["plane"][21]="qrtl.wav"
	-- Rover
	soundFilesByFrameTypeAndFlightMode["rover"][0]="manual_r.wav"
	soundFilesByFrameTypeAndFlightMode["rover"][1]="acro_r.wav"
	soundFilesByFrameTypeAndFlightMode["rover"][2]=""
	soundFilesByFrameTypeAndFlightMode["rover"][3]="steering_r.wav"
	soundFilesByFrameTypeAndFlightMode["rover"][4]="hold_r.wav"
	soundFilesByFrameTypeAndFlightMode["rover"][5]=""
	soundFilesByFrameTypeAndFlightMode["rover"][6]=""
	soundFilesByFrameTypeAndFlightMode["rover"][7]=""
	soundFilesByFrameTypeAndFlightMode["rover"][8]=""
	soundFilesByFrameTypeAndFlightMode["rover"][9]=""
	soundFilesByFrameTypeAndFlightMode["rover"][10]="auto_r.wav"
	soundFilesByFrameTypeAndFlightMode["rover"][11]="rtl_r.wav"
	soundFilesByFrameTypeAndFlightMode["rover"][12]="smartrtl_r.wav"
	soundFilesByFrameTypeAndFlightMode["rover"][13]=""
	soundFilesByFrameTypeAndFlightMode["rover"][14]=""
	soundFilesByFrameTypeAndFlightMode["rover"][15]="guided_r.wav"
	soundFilesByFrameTypeAndFlightMode["rover"][16]="initializing.wav"
	soundFilesByFrameTypeAndFlightMode["rover"][17]=""
	soundFilesByFrameTypeAndFlightMode["rover"][18]=""
	soundFilesByFrameTypeAndFlightMode["rover"][19]=""
	soundFilesByFrameTypeAndFlightMode["rover"][20]=""
	soundFilesByFrameTypeAndFlightMode["rover"][21]=""


local gpsStatuses = {}
  gpsStatuses[0]="NoGPS"
  gpsStatuses[1]="NoLock"
  gpsStatuses[2]="2DFIX"
  gpsStatuses[3]="3DFix"

local mavSeverity = {}
  mavSeverity[0]="EMR"
  mavSeverity[1]="ALR"
  mavSeverity[2]="CRT"
  mavSeverity[3]="ERR"
  mavSeverity[4]="WRN"
  mavSeverity[5]="NOT"
  mavSeverity[6]="INF"
  mavSeverity[7]="DBG"

  -- STATUS
local flightMode = 0
local simpleMode = 0
local landComplete = 0
local statusArmed = 0
local batteryFailsafe = 0
local lastBatteryFailsafe = 0
local ekfFailsafe = 0
local lastEkfFailsafe = 0
-- GPS
local numSats = 0
local gpsStatus = 0
local gpsHdopC = 100
local gpsAlt = 0
-- BATT
local battVolt = 0
local battCurrent = 0
local battMah = 0
-- BATT2
local battVolt2 = 0
local battCurrent2 = 0
local battMah2 = 0
-- HOME
local homeDist = 0
local homeAlt = 0
local homeAngle = -1
-- MESSAGES
local messageBuffer = "" 
local messageHistory = {}
local severity = 0
local messageIdx = 1
local messageDuplicate = 1
local lastMessage = ""
local lastMessageValue = 0
local lastMessageTime = 0
-- VELANDYAW
local vSpeed = 0
local hSpeed = 0
local yaw = 0
-- ROLLPITCH
local roll = 0
local pitch = 0
-- TELEMETRY
local SENSOR_ID,FRAME_ID,DATA_ID,VALUE
local mult = 0
local c1,c2,c3,c4
-- PARAMS
local paramId,paramValue
local frameType = 2
local battFailsafeVoltage = 0
local battFailsafeCapacity = 0
local battCapacity = 0
--
local minX = 0
local maxX = 76
local minY = 9
local maxY = 55
--
local noTelemetryData = 1

local function playSound(soundFile)
	playFile(soundFileBasePath .. "/" .. soundFiles[soundFile])
end

local function playSoundByFrameTypeAndFlightMode(frameType,flightMode)
	playFile(soundFileBasePath .. "/" .. soundFilesByFrameTypeAndFlightMode[frameTypes[frameType]][flightMode])
end

local function getValueOrDefault(value)
	local tmp = getValue(value)
	if tmp == nil then
		return 0
	end
	return tmp
end

local function pushMessage(severity, msg)
	if ( severity < 4) then
		playTone(400,300,0)
	else
		playTone(600,300,0)
	end
	local mm = msg
	if msg == lastMessage then
		messageDuplicate = messageDuplicate + 1
		if messageDuplicate > 1 then
			if string.len(mm) > 33 then
				mm = string.sub(mm,1,33)
				messageHistory[messageIdx - 1] = string.format("[%02d:%s] %-33s (x%d)", messageIdx - 1, mavSeverity[severity], mm, messageDuplicate)
			else
				messageHistory[messageIdx - 1] = string.format("[%02d:%s] %s (x%d)", messageIdx - 1, mavSeverity[severity], msg, messageDuplicate)
			end
		end
	else
		messageHistory[messageIdx] = string.format("[%02d:%s] %s", messageIdx, mavSeverity[severity], msg)
		messageIdx = messageIdx + 1
		lastMessage = msg
		messageDuplicate = 1
	end
	lastMessageTime = getTime() -- valore in secondi 
end

local function logTelemetryToFile(S_ID,F_ID,D_ID,VA)
	local lc1 = 0
	local lc2 = 0
	local lc3 = 0
	local lc4 = 0
	if (S_ID) then
		lc1 = S_ID
	end
	if (F_ID) then
		lc2 = F_ID
	end
	if (D_ID) then
		lc3 = D_ID
	end
	if (VA) then
		lc4 = VA
	end
	local logFile = io.open("yaapu.log","a")
	io.write(logFile,string.format("%d,%#04x,%#04x,%#04x,%#04x", getTime(), lc1, lc2, lc3, lc4),"\r\n")    
	io.close(logFile)
end

local seconds = 0
local lastTimerStart = 0
--
local function startTimer()
	lastTimerStart = getTime()/100
end

local function stopTimer()
	seconds = seconds + getTime()/100 - lastTimerStart
	lastTimerStart = 0
end

local function symTimer()
	thrOut = getValue("thr")
	if (thrOut > -500 ) then
		landComplete = 1
	else
		landComplete = 0
	end
end

local function symGPS()
	thrOut = getValue("thr")
	if (thrOut > 0 ) then
		numSats = 9
		gpsStatus = 3
		gpsHdopC = 11
		ekfFailsafe = 0
		batteryFailsafe = 0
		noTelemetryData = 0
		statusArmed = 1
	elseif thrOut > -500  then
		numSats = 6
		gpsStatus = 3
		gpsHdopC = 17
		ekfFailsafe = 1
		batteryFailsafe = 1
		noTelemetryData = 0
		statusArmed = 0
	else
		numSats = 0
		gpsStatus = 0
		gpsHdopC = 100
		ekfFailsafe = 0
		batteryFailsafe = 0
		noTelemetryData = 1
		statusArmed = 0
	end
end

local function symFrameType()
	local ch11 = getValue("ch11")
	if (ch11 < -300) then
		frameType = 2
	elseif ch11 < 300 then
		frameType = 1
	else
		frameType = 10
	end
end

local function symBatt()
	thrOut = getValue("thr")
	if (thrOut > 0 ) then
		LIPObatt = 1350 + ((thrOut)*0.01 * 30)
		LIPOcelm = LIPObatt/4
		battCurrent = 100 +  ((thrOut)*0.01 * 30)
		battVolt = LIPObatt*0.1
		battCapacity = 5200
		battMah = math.abs(1000*(thrOut/200))
		flightMode = math.floor(20 * math.abs(thrOut)*0.001)
	end
end

-- simulates attitude by using channel 1 for roll, channel 2 for pitch and channel 4 for yaw
local function symAttitude()
	local rollCh = 0
	local pitchCh = 0
	local yawCh = 0
	-- roll [-1024,1024] ==> [-180,180]
	rollCh = getValue("ch1") * 0.175
	-- pitch [1024,-1024] ==> [-90,90]
	pitchCh = getValue("ch2") * 0.0878
	-- yaw [-1024,1024] ==> [0,360]
	yawCh = getValue("ch10")
	if ( yawCh >= 0) then
		yawCh = yawCh * 0.175
	else
		yawCh = 360 + (yawCh * 0.175)
	end
	roll = rollCh/3
	pitch = pitchCh/2
	yaw = yawCh
end

local function symHome()
	local yawCh = 0
	local S2Ch = 0
	-- home angle in deg [0-360]
	S2Ch = getValue("ch12")
	yawCh = getValue("ch4")
	homeAlt = yawCh
	vSpeed = yawCh * 0.1
	if ( yawCh >= 0) then
		yawCh = yawCh * 0.175
	else
		yawCh = 360 + (yawCh * 0.175)
	end
	if ( S2Ch >= 0) then
		S2Ch = S2Ch * 0.175
	else
		S2Ch = 360 + (S2Ch * 0.175)
	end
	if (thrOut > 0 ) then
		homeAngle = S2Ch
	else
		homeAngle = -1
	end		
	yaw = yawCh
end

local function processTelemetry()
  SENSOR_ID,FRAME_ID,DATA_ID,VALUE = sportTelemetryPop()
	--
	--FRAME_ID = 0x10
	--DATA_ID = 0x5002
	--VALUE = 0xf4006b8
	--
	--FRAME_ID = 0x10
	--DATA_ID = 0x5004
	--VALUE = 0x168000
	--
	if ( FRAME_ID == 0x10) then
-- >> DEBUG 
--		logTelemetryToFile(SENSOR_ID,FRAME_ID,DATA_ID,VALUE)
-- << DEBUG
		noTelemetryData = 0
		if ( DATA_ID == 0x5006) then -- ROLLPITCH 
			-- roll [0,1800] ==> [-180,180]
			roll = (bit32.extract(VALUE,0,11) - 900) * 0.2 
			-- pitch [0,900] ==> [-90,90]
			pitch = (bit32.extract(VALUE,11,10) - 450) * 0.2
		elseif ( DATA_ID == 0x5005) then -- VELANDYAW 
			vSpeed = bit32.extract(VALUE,1,7) * (10^bit32.extract(VALUE,0,1))
			if (bit32.extract(VALUE,8,1) == 1) then
				vSpeed = -vSpeed
			end
			hSpeed = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
			yaw = bit32.extract(VALUE,17,11) * 0.2
		elseif ( DATA_ID == 0x5001) then -- AP STATUS 
			flightMode = bit32.extract(VALUE,0,5)
			simpleMode = bit32.extract(VALUE,5,2)
			landComplete = bit32.extract(VALUE,7,1)
			statusArmed = bit32.extract(VALUE,8,1)
			batteryFailsafe = bit32.extract(VALUE,9,1)
			ekfFailsafe = bit32.extract(VALUE,10,2)
		elseif ( DATA_ID == 0x5002) then -- GPS STATUS 
			numSats = bit32.extract(VALUE,0,4)
			gpsStatus = bit32.extract(VALUE,4,2)
			gpsHdopC = bit32.extract(VALUE,7,7) * (10^bit32.extract(VALUE,6,1)) -- dm
			gpsAlt = bit32.extract(VALUE,24,7) * (10^bit32.extract(VALUE,22,2)) -- dm
			if (bit32.extract(VALUE,31,1) == 1) then
				gpsAlt = gpsAlt * -1
			end
		elseif ( DATA_ID == 0x5003) then -- BATT 
			battVolt = bit32.extract(VALUE,0,9)
			battCurrent = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
			battMah = bit32.extract(VALUE,17,15)
		elseif ( DATA_ID == 0x5008) then -- BATT2 
			battVolt2 = bit32.extract(VALUE,0,9)
			battCurrent2 = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
			battMah2 = bit32.extract(VALUE,17,15)
		elseif ( DATA_ID == 0x5004) then -- HOME 
			homeDist = bit32.extract(VALUE,2,10) * (10^bit32.extract(VALUE,0,2))
			homeAlt = bit32.extract(VALUE,14,10) * (10^bit32.extract(VALUE,12,2)) * 0.1
			if (bit32.extract(VALUE,24,1) == 1) then
				homeAlt = homeAlt * -1
			end
			homeAngle = bit32.extract(VALUE, 25,  7) * 3
		elseif ( DATA_ID == 0x5000) then -- MESSAGES 
			if (VALUE ~= lastMessageValue) then
				lastMessageValue = VALUE
				c1 = bit32.extract(VALUE,0,7)
				c2 = bit32.extract(VALUE,8,7)
				c3 = bit32.extract(VALUE,16,7)
				c4 = bit32.extract(VALUE,24,7)
				messageBuffer = messageBuffer .. string.char(c4)
				messageBuffer = messageBuffer .. string.char(c3)
				messageBuffer = messageBuffer .. string.char(c2)
				messageBuffer = messageBuffer .. string.char(c1)
				if (c1 == 0 or c2 == 0 or c3 == 0 or c4 == 0) then
					severity = (bit32.extract(VALUE,15,1) * 4) + (bit32.extract(VALUE,23,1) * 2) + (bit32.extract(VALUE,30,1) * 1)
					pushMessage( severity, messageBuffer)
					messageBuffer = ""
				end
			end
		elseif ( DATA_ID == 0x5007) then -- PARAMS
			paramId = bit32.extract(VALUE,24,4)
			paramValue = bit32.extract(VALUE,0,24)
			if paramId == 1 then
				frameType = paramValue
			elseif paramId == 2 then
				battFailsafeVoltage = paramValue
			elseif paramId == 3 then
				battFailsafeCapacity = paramValue
			elseif paramId == 4 then
				battCapacity = paramValue
			end
		end
	end
end

local function telemetryEnabled()
	if getValue("RxBt") == 0 then
		noTelemetryData = 1
	end
	return noTelemetryData == 0
	--return true
end

local battSource = "na"

local function calcBattery()
	local battA2 = 0
	local cellCount = 3;
	--
	cellmin = cellfull
	cellResult = getValue("Cels")                          

	if type(cellResult) == "table" then                     
		battSource="vs"
		cellsum = 0                                         
		for i = 1, #cell do cell[i] = 0 end                 
			cellsumtype = #cellResult                           
		for i, v in pairs(cellResult) do                    
			cellsum = cellsum + v                             
			cell[i] = v                                       
			if cellmin > v then                               
				cellmin = v
			end
		end -- end for
	else
		-- cels is not defined let's check if A2 is defined
		cellmin = 0
		battA2 = getValue("A2")
		--
		if battA2 > 0 then
			battSource="a2"
				if battA2 > 21 then
					cellCount = 6
				elseif battA2 > 17 then
					cellCount = 5
				elseif battA2 > 13 then
					cellCount = 4
				else
					cellCount = 3
				end
			--
			cellmin = battA2/cellCount
			cellsum = battA2
		else
			-- A2 is not defined, last chance is battVolt
			if battVolt > 0 then
				battSource="fc"
				cellsum = battVolt*0.1
				if cellsum > 21 then
					cellCount = 6
				elseif cellsum > 17 then
					cellCount = 5
				elseif cellsum > 13 then
					cellCount = 4
				else
					cellCount = 3
				end
				--
				cellmin = cellsum/cellCount
			end
		end
	end -- end if
	--
	LIPOcelm = cellmin*100
	LIPObatt = cellsum*100
end

local function drawBattery()
	if (battCapacity > 0) then
		LIPOperc = (1 - (battMah/battCapacity))*100
	else
		LIPOperc = 0
	end
	-- display battery voltage
	lcd.drawNumber(maxX + 3, 10, LIPObatt, DBLSIZE+PREC2)   
	
	local xx = lcd.getLastRightPos()
	lcd.drawText(xx, 10, "V", 0)
	lcd.drawText(xx, 20, battSource, SMLSIZE)

	-- display lowest cell voltage
	if LIPOcelm < 350 then
		lcd.drawNumber(maxX + 57, 10, LIPOcelm, DBLSIZE+BLINK+PREC2)    
		lcd.drawText(lcd.getLastRightPos(), 10, "Vm", SMLSIZE+BLINK)
	else
		lcd.drawNumber(maxX + 57, 10, LIPOcelm, DBLSIZE+PREC2)      
		lcd.drawText(lcd.getLastRightPos(), 10, "Vm", SMLSIZE)
	end

	lcd.drawNumber(maxX + 101, 10, battCurrent, DBLSIZE+PREC1)
	lcd.drawText(lcd.getLastRightPos(), 10, "A", SMLSIZE)

	local barOffset = maxX + 24

	lcd.drawText(barOffset - 1, 28, "%", SMLSIZE+RIGHT)
	lcd.drawNumber(lcd.getLastLeftPos(), 28, LIPOperc, RIGHT)       

	-- display capacity bar %
	lcd.drawGauge(barOffset, 28, 55, 7, LIPOperc, 100)

	lcd.drawText(212, 28, "Ah", SMLSIZE+RIGHT)
	lcd.drawNumber(lcd.getLastLeftPos(), 28, battCapacity/100, SMLSIZE+PREC1+RIGHT)  
	lcd.drawText(lcd.getLastLeftPos(), 28, "/", SMLSIZE+RIGHT)
	lcd.drawNumber(lcd.getLastLeftPos(), 28, battMah/100, SMLSIZE+PREC1+RIGHT)  

	lcd.drawPoint(barOffset + 13, 28)
	lcd.drawPoint(barOffset + 13, 34)

	lcd.drawPoint(barOffset + 27, 28)
	lcd.drawPoint(barOffset + 27, 34)        

	lcd.drawPoint(barOffset + 41, 28)
	lcd.drawPoint(barOffset + 41, 34)
end

local function drawFlightMode()
	lcd.drawFilledRectangle(0,0, 212, 9, SOLID)
	lcd.drawRectangle(0, 0, 212, 9, SOLID)

	if (not telemetryEnabled()) then
		lcd.drawFilledRectangle((212-150)/2,18, 150, 30, SOLID)
		lcd.drawText(60, 29, "no telemetry data", INVERS)
		return
	end

	local strMode = flightModes[frameTypes[frameType]][flightMode]
	--
	lcd.drawText(1, 1, strMode, SMLSIZE+INVERS)

	if ( simpleMode == 1) then
		lcd.drawText(lcd.getLastRightPos(), 1, "(S)", SMLSIZE+INVERS)
	end

	if (statusArmed == 1) then
		lcd.drawText(maxX/2 - 12, 47, "ARMED", SMLSIZE+INVERS)
	else
		lcd.drawText(maxX/2 - 18, 47, "DISARMED", SMLSIZE+INVERS+BLINK)
	end
end

local function drawHome()
	local xx = maxX + 76
	local yy = 39
	local ax = xx - 43
	local ay = 42
	local alen = 10
	--
	lcd.drawLine(ax ,ay,ax + alen,ay, SOLID, 0)
	-- left arrow
	lcd.drawLine(ax+1,ay-1,ax + 2,ay-2, SOLID, 0)
	lcd.drawLine(ax+1,ay+1,ax + 2,ay+2, SOLID, 0)
	-- right arrow
	lcd.drawLine(ax + alen - 1,ay-1,ax + alen - 2,ay-2, SOLID, 0)
	lcd.drawLine(ax + alen - 1,ay+1,ax + alen - 2,ay+2, SOLID, 0)

	if homeAngle == -1 then
		lcd.drawText(xx, yy, "m",SMLSIZE+RIGHT+BLINK)
		lcd.drawNumber(lcd.getLastLeftPos(), yy, homeDist, SMLSIZE+RIGHT+BLINK)
		lcd.drawNumber(xx, yy + 8, 0, SMLSIZE+RIGHT+BLINK)
	else
		lcd.drawText(xx, yy, "m",SMLSIZE+RIGHT)
		lcd.drawNumber(lcd.getLastLeftPos(), yy, homeDist, SMLSIZE+RIGHT)
		lcd.drawNumber(xx, yy + 8, homeAngle, SMLSIZE+RIGHT)
	end
	lcd.drawText(ax, yy + 8, "Angle:",SMLSIZE)
end

local function drawMessage()
	lcd.drawFilledRectangle(0,55, 212, 9, SOLID)
	lcd.drawRectangle(0, 55, 212, 9, SOLID)
	local now = getTime()
	if (now - lastMessageTime ) > 300 then
		lcd.drawText(1, 56, messageHistory[messageIdx-1],SMLSIZE+INVERS)
	else
		lcd.drawText(1, 56, messageHistory[messageIdx-1],SMLSIZE+INVERS+BLINK)
	end
end

local function drawAllMessages()
	local idx = 1
	if (messageIdx <= 6) then
		for i = 1, messageIdx - 1 do
			lcd.drawText(1, 1+10*(idx - 1), messageHistory[i],SMLSIZE)
			idx = idx+1
		end
	else
		for i = messageIdx - 6,messageIdx - 1 do
			lcd.drawText(1, 1+10*(idx-1), messageHistory[i],SMLSIZE)
			idx = idx+1
		end
	end
end

local function drawGPSStatus()
	local xx = 173
	local yy = 38
	lcd.drawRectangle(xx,yy,50,18,SOLID)

	--
	local strStatus = gpsStatuses[gpsStatus] 
	--
	local flags = BLINK
	if gpsStatus  > 2 then
		lcd.drawFilledRectangle(xx,yy,50,18,SOLID)
		if homeAngle ~= -1 then
			flags = 0
		end
		lcd.drawText(xx+2, yy+2, strStatus, SMLSIZE+INVERS)
		lcd.drawNumber(212, yy+2, numSats, SMLSIZE+INVERS+RIGHT)
		lcd.drawText(xx+2, yy+10, "Hdop ", SMLSIZE+INVERS)
		--
		if gpsHdopC > 100 then
			lcd.drawNumber(212, yy+10, gpsHdopC , SMLSIZE+INVERS+RIGHT+PREC1+flags)
		else
			lcd.drawNumber(212, yy+10, gpsHdopC , SMLSIZE+INVERS+RIGHT+PREC1+flags)
		end
		lcd.drawText(maxX + 30, 40, "AltAsl", SMLSIZE+RIGHT)
		lcd.drawText(maxX + 30, 47, "m", SMLSIZE+RIGHT)
		lcd.drawNumber(lcd.getLastLeftPos(), 47, gpsAlt/10, SMLSIZE+RIGHT)
	else
		lcd.drawText(xx+5, yy+5, strStatus, INVERS+BLINK)
		lcd.drawText(maxX + 30, 40, "AltAsl", SMLSIZE+RIGHT)
		lcd.drawText(maxX + 30, 47, "m", SMLSIZE+RIGHT+BLINK)
		lcd.drawNumber(lcd.getLastLeftPos(), 47, 0, SMLSIZE+RIGHT+BLINK)
	end
end

local function drawGrid()
	lcd.drawLine(maxX, 0, maxX, 63, SOLID, 0)
	lcd.drawRectangle(maxX,38,31,18,SOLID)
end

local timerRunning = 0

local function checkLandingStatus()
	if ( timerRunning == 0 and landComplete == 1 and lastTimerStart == 0) then
		startTimer()
	end
	if (timerRunning == 1 and landComplete == 0 and lastTimerStart ~= 0) then
		stopTimer()
		playSound("landing")
	end
	timerRunning = landComplete
end
local flightTime = 0

local function calcFlightTime()
	local elapsed = 0
	if ( lastTimerStart ~= 0) then
		elapsed = getTime()/100 - lastTimerStart
	end
	flightTime = elapsed + seconds
end

-- draws a line centered at ox,oy with given angle and length W/O CROPPING
local function drawLine(ox,oy,angle,len,style,maxX,maxY)
	local xx = math.cos(math.rad(angle)) * len * 0.5
	local yy = math.sin(math.rad(angle)) * len * 0.5

	local x1 = ox - xx
	local x2 = ox + xx
	local y1 = oy - yy
	local y2 = oy + yy
	--
	lcd.drawLine(x1,y1,x2,y2, style,0)
end

-- draws a line centered at ox,oy with given angle and length WITH CROPPING
local function drawCroppedLine(ox,oy,angle,len,style,maxX,maxY)
	--
	local xx = math.cos(math.rad(angle)) * len * 0.5
	local yy = math.sin(math.rad(angle)) * len * 0.5
	--
	local x1 = ox - xx
	local x2 = ox + xx
	local y1 = oy - yy
	local y2 = oy + yy
	--
	if (x1 >= maxX and x2 >= maxX) then
		return
	end
	if (x1 >= maxX) then
		y1 = y1 - math.tan(math.rad(angle)) * (maxX - x1)
		x1 = maxX - 1
	end
	if (x2 >= maxX) then
		y2 = y2 + math.tan(math.rad(angle)) * (maxX - x2)
		x2 = maxX - 1
	end
	lcd.drawLine(x1,y1,x2,y2, style,0)
end

local function drawFailsafe()
	if ekfFailsafe > 0 then
		if lastEkfFailsafe == 0 then
			playSound("ekf")
		end
		lcd.drawText(maxX/2 - 28, 47, "EKF FAILSAFE", SMLSIZE+INVERS+BLINK)
	end
	if batteryFailsafe > 0 then
		if lastBatteryFailsafe == 0 then
			playSound("lowbat")
		end
		lcd.drawText(maxX/2 - 30, 47, "BATT FAILSAFE", SMLSIZE+INVERS+BLINK)
	end
	lastEkfFailsafe = ekfFailsafe
	lastBatteryFailsafe = batteryFailsafe
end

local function drawPitch()
	local y = 0
	local p = pitch
	-- horizon min max +/- 30°
	if ( pitch > 0) then
		if (pitch > 30) then
			p = 30
		end
	else
		if (pitch < -30) then
			p = -30
		end
	end
	-- y normalized at 32 +/-20  (0.75 = 20/32)
	y = 32 + 0.75*p
	-- horizon, lower half of HUD filled in grey
	--lcd.drawFilledRectangle(minX,y,maxX-minX,maxY-y + 1,GREY_DEFAULT)
	--
	-- center indicators for vSpeed and alt
	local width = 17
	lcd.drawLine(minX,32 - 5,minX + width,32 - 5, SOLID, 0)
	lcd.drawLine(minX,32 + 4,minX + width,32 + 4, SOLID, 0)
	lcd.drawLine(minX + width + 1,32 + 4,minX + width + 5,32, SOLID, 0)
	lcd.drawLine(minX + width + 1,32 - 4,minX + width + 5,32, SOLID, 0)
	lcd.drawPoint(minX + width + 5,32)
	--
	lcd.drawLine(maxX - width - 1,32 - 5,maxX - 1,32 - 5,SOLID,0)
	lcd.drawLine(maxX - width - 1,32 + 4,maxX - 1,32 + 4,SOLID,0)
	lcd.drawLine(maxX - width - 2,32 + 4,maxX - width - 6,32, SOLID, 0)
	lcd.drawLine(maxX - width - 2,32 - 4,maxX - width - 6,32, SOLID, 0)
	lcd.drawPoint(maxX - width - 6,32)
	--
	local xx = maxX - width - 2
	if homeAlt > 0 then
		if homeAlt < 10 then -- 2 digits with decimal
			lcd.drawNumber(maxX,32 - 3,homeAlt * 10,SMLSIZE+PREC1+RIGHT)
		else -- 3 digits
			lcd.drawNumber(maxX,32 - 3,homeAlt,SMLSIZE+RIGHT)
		end
	else
		if homeAlt > -10 then -- 1 digit with sign
			lcd.drawNumber(maxX,32 - 3,homeAlt * 10,SMLSIZE+PREC1+RIGHT)
		else -- 3 digits with sign
			lcd.drawNumber(maxX,32 - 3,homeAlt,SMLSIZE+RIGHT)
		end
	end
	--
	if (vSpeed > 999) then
		lcd.drawNumber(minX + 1,32 - 3,vSpeed*0.1,SMLSIZE)
	elseif (vSpeed < -99) then
		lcd.drawNumber(minX + 1,32 - 3,vSpeed * 0.1,SMLSIZE)
	else
		lcd.drawNumber(minX + 1,32 - 3,vSpeed,SMLSIZE+PREC1)
	end
	-- up pointing center arrow
	local x = math.floor(maxX/2)
	lcd.drawLine(x-10,34 + 5,x ,34 ,SOLID,0)
	lcd.drawLine(x+1 ,34 ,x + 10, 34 + 5,SOLID,0)
end

local function drawRoll()
	local r = -roll
	local r2 = 10 --vertical distance between roll horiz segments
	local cx,cy,dx,dy,ccx,ccy,cccx,cccy
	-- no roll ==> segments are vertical, offsets are multiples of r2
	if ( roll == 0) then
		dx=0
		dy=pitch
		cx=0
		cy=r2
		ccx=0
		ccy=2*r2
		cccx=0
		cccy=3*r2
	else
		-- center line offsets
		dx = math.cos(math.rad(90 - r)) * -pitch 
		dy = math.sin(math.rad(90 - r)) * pitch
		-- 1st line offsets
		cx = math.cos(math.rad(90 - r)) * r2
		cy = math.sin(math.rad(90 - r)) * r2
		-- 2nd line offsets
		ccx = math.cos(math.rad(90 - r)) * 2 * r2
		ccy = math.sin(math.rad(90 - r)) * 2 * r2
		-- 3rd line offsets
		cccx = math.cos(math.rad(90 - r)) * 3 * r2
		cccy = math.sin(math.rad(90 - r)) * 3 * r2
	end
	local x = math.floor(maxX/2)
	drawCroppedLine(dx + x - cccx,dy + 32 + cccy,r,5,DOTTED,maxX,maxY)
	drawCroppedLine(dx + x - ccx,dy + 32 + ccy,r,7,DOTTED,maxX,maxY)
	drawCroppedLine(dx + x - cx,dy + 32 + cy,r,10,DOTTED,maxX,maxY)
	drawCroppedLine(dx + x,dy + 32,r,28,SOLID,maxX,maxY)
	drawCroppedLine(dx + x + cx,dy + 32 - cy,r,10,DOTTED,maxX,maxY)
	drawCroppedLine(dx + x + ccx,dy + 32 - ccy,r,7,DOTTED,maxX,maxY)
	drawCroppedLine(dx + x + cccx,dy + 32 - cccy,r,5,DOTTED,maxX,maxY)
end

local function roundTo(val,int)
	return math.floor(val/int) * int
end

local function drawYaw()
	local northX = math.floor(maxX/2) - 2
	local offset = northX - 4
	local yawRounded =  math.floor(yaw)
	local yawWindow = roundTo(yaw,10)
	local maxXHalf = math.floor(maxX/2)
	local yawWindowOn = false
	local flags = SMLSIZE
	if (not(yawWindow == 0 or yawWindow == 90 or yawWindow == 180 or yawWindow == 270 or yawWindow == 360)) then
		yawWindowOn = true
	end
	--
	if (yawRounded == 0 or yawRounded == 360) then
		lcd.drawText(northX - offset, minY+1, "W", SMLSIZE)
		lcd.drawText(northX, minY+1, "N", flags)
		lcd.drawText(northX + offset, minY+1, "E", SMLSIZE)
	elseif (yawRounded == 90) then
		lcd.drawText(northX - offset, minY+1, "N", SMLSIZE)
		lcd.drawText(northX, minY+1, "E", flags)
		lcd.drawText(northX + offset, minY+1, "S", SMLSIZE)
	elseif (yawRounded == 180) then
		lcd.drawText(northX - offset, minY+1, "W", SMLSIZE)
		lcd.drawText(northX, minY+1, "S", flags)
		lcd.drawText(northX + offset, minY+1, "E", SMLSIZE)
	elseif (yawRounded == 270) then
		lcd.drawText(northX - offset, minY+1, "S", SMLSIZE)
		lcd.drawText(northX, minY+1, "W", flags)
		lcd.drawText(northX + offset, minY+1, "N", SMLSIZE)
	elseif ( yaw > 0 and yaw < 90) then
		northX = (maxXHalf - 2) - 0.3*yaw
		lcd.drawText(northX, minY+1, "N", flags)
		lcd.drawText(northX + offset, minY+1, "E", SMLSIZE)
		if (yaw > 75) then
			lcd.drawText(northX + offset + offset, minY+1, "S", SMLSIZE)
		end
	elseif ( yaw > 90 and yaw < 180) then
		northX = (maxXHalf - 2) - 0.3*(yaw - 180)
		lcd.drawText(northX - offset, minY+1, "E", SMLSIZE)
		lcd.drawText(northX, minY+1, "S", flags)
		if (yaw > 170) then
			lcd.drawText(northX + offset, minY+1, "W", SMLSIZE)
		end
	elseif ( yaw > 180 and yaw < 270) then
		northX = (maxXHalf - 2) - 0.3*(yaw - 270)
		lcd.drawText(northX, minY+1, "W", SMLSIZE)
		lcd.drawText(northX - offset, minY+1, "S", flags)
		if (yaw < 190) then
			lcd.drawText(northX - offset - offset, minY+1, "E", SMLSIZE)
		end
	elseif ( yaw > 270 and yaw < 360) then
		northX = (maxXHalf - 2) - 0.3*(yaw - 360)
		lcd.drawText(northX, minY+1, "N", SMLSIZE)
		lcd.drawText(northX - offset, minY+1, "W", flags)
		if (yaw < 290) then
			lcd.drawText(northX - offset - offset, minY+1, "S", SMLSIZE)
		end
		if (yaw > 345) then
			lcd.drawText(northX + offset, minY+1, "E", SMLSIZE)
		end
	end
	lcd.drawLine(minX, minY +7, maxX, minY+7, SOLID, 0)
	--
	local xx = 0
	if ( yaw < 10) then
		xx = 3
	elseif (yaw < 100) then
		xx = 0
	else
		xx = -3
	end
	lcd.drawNumber(minX + offset + xx, minY, yaw, MIDSIZE+INVERS)
end

local function drawHud()
	drawPitch()
	drawRoll()
	drawYaw()
end

local function drawHomeDirection()
	local ox = 163
	local oy = 46
	local angle = math.floor(yaw - homeAngle)
	if ( math.abs(angle) > 45 and math.abs(angle) < 315) then
		oy = 44
	end 
	local r1 = 10
	local r2 = 5
	local x1 = ox + r1 * math.cos(math.rad(angle - 90)) 
	local y1 = oy + r1 * math.sin(math.rad(angle - 90))
	local x2 = ox + r2 * math.cos(math.rad(angle - 90 + 120)) 
	local y2 = oy + r2 * math.sin(math.rad(angle - 90 + 120))
	local x3 = ox + r2 * math.cos(math.rad(angle - 90 - 120)) 
	local y3 = oy + r2 * math.sin(math.rad(angle - 90 - 120))
	--
	lcd.drawLine(x1,y1,x2,y2,SOLID,1)
	lcd.drawLine(x1,y1,x3,y3,SOLID,1)
	lcd.drawLine(ox,oy,x2,y2,SOLID,1)
	lcd.drawLine(ox,oy,x3,y3,SOLID,1)
end

local function drawFlightTime()
	lcd.drawText(maxX + 1, 1, "T:", SMLSIZE+INVERS)
	lcd.drawTimer(lcd.getLastRightPos()+1, 1, flightTime, SMLSIZE+INVERS)
end

local function drawRSSI()
	local rssi = getRSSI()
	lcd.drawText(212, 1, rssi, SMLSIZE+INVERS+RIGHT)
	lcd.drawText(lcd.getLastLeftPos(), 1, "Rssi:", SMLSIZE+INVERS+RIGHT)
end

local function drawTxVoltage()
	txVId=getFieldInfo("tx-voltage").id
	txV = getValue(txVId)*10  

	lcd.drawText(150, 1, "Tx:", SMLSIZE+INVERS)
	lcd.drawNumber(lcd.getLastRightPos(), 1, txV, SMLSIZE+INVERS+PREC1)
	lcd.drawText(lcd.getLastRightPos(), 1, "v", SMLSIZE+INVERS)
end

local function drawCircle(x0,y0,radius)
    local x = radius-1
    local y = 0
    local dx = 1
    local dy = 1
    local err = dx - bit32.lshift(radius,1)--(radius << 1)

    while (x >= y) do
        lcd.drawPoint(x0 + x, y0 + y);
        lcd.drawPoint(x0 + y, y0 + x);
        lcd.drawPoint(x0 - y, y0 + x);
        lcd.drawPoint(x0 - x, y0 + y);
        lcd.drawPoint(x0 - x, y0 - y);
        lcd.drawPoint(x0 - y, y0 - x);
        lcd.drawPoint(x0 + y, y0 - x);
        lcd.drawPoint(x0 + x, y0 - y);

        if err <= 0 then
            y=y+1
            err = err + dy
            dy = dy + 2
        end
        if err > 0 then
        
            x=x-1
            dx = dx + 2
            err = err + dx - bit32.lshift(radius,1)--(radius << 1);
        end
    end
end


local lastStatusArmed = 0
local lastGpsStatus = 0
local lastFlightMode = 0
local lastBattLevel = 0
local batLevel = 99
local batLevels = {}
	batLevels[12]=0
	batLevels[11]=5
	batLevels[10]=10
	batLevels[9]=15
	batLevels[8]=20
	batLevels[7]=25
	batLevels[6]=30
	batLevels[5]=40
	batLevels[4]=50
	batLevels[3]=60
	batLevels[2]=70
	batLevels[1]=80
	batLevels[0]=90

local function checkSoundEvents()
	if (battCapacity > 0) then
		batLevel = (1 - (battMah/battCapacity))*100
	else
		batLevel = 99
	end

	if batLevel < (batLevels[lastBattLevel] + 1) and lastBattLevel <= 11 then
		playSound("bat"..batLevels[lastBattLevel])
		lastBattLevel = lastBattLevel + 1
	end

	if statusArmed == 1 and lastStatusArmed == 0 then
		lastStatusArmed = statusArmed
		playSound("armed")
	elseif statusArmed == 0 and lastStatusArmed == 1 then
		lastStatusArmed = statusArmed
		playSound("disarmed")
	end
	
	if gpsStatus > 2 and lastGpsStatus <= 2 then
		lastGpsStatus = gpsStatus
		playSound("gpsfix")
	elseif gpsStatus <= 2 and lastGpsStatus > 2 then
		lastGpsStatus = gpsStatus
		playSound("gpsnofix")
	end

	if flightMode ~= lastFlightMode then
		lastFlightMode = flightMode
		playSoundByFrameTypeAndFlightMode(frameType,flightMode)
	end
end
--------------------------------------------------------------------------------
-- loop FUNCTIONS
--------------------------------------------------------------------------------
local showMessages = false
--
local function background()
	processTelemetry()
end
--
local clock = 0
--
local function symMode()
	symAttitude()
	symTimer()
	symHome()
	symGPS()
	symBatt()
	symFrameType()
end
--
local function run(event) 
	processTelemetry()
	if event == EVT_PLUS_FIRST or event == EVT_MINUS_FIRST then
		showMessages = not showMessages
	end
	--
	if (clock % 8 == 0) then
		calcBattery()
		calcFlightTime()
		checkSoundEvents()
		clock = 0
	end
	lcd.clear()
	if showMessages then
		processTelemetry()
		drawAllMessages()
		--drawCircle(100,32,30)
	else
		for r=1,3
		do
			processTelemetry()
			lcd.clear()
			--symMode()
			drawHud()
			drawGrid()
			drawBattery()
			drawGPSStatus()
			checkLandingStatus()
			drawMessage()
			drawHomeDirection()
			drawHome()
			drawFlightMode()
			drawFlightTime()
			drawTxVoltage()
			drawRSSI()
			drawFailsafe()
		end
	end
	clock = clock + 1
end

local function init()
	pushMessage(6,"Yaapu X9D+ telemetry script v1.1")
	playSound("yaapu")
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run,  background=background, init=init}