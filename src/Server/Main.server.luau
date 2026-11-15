--!strict
local DataManager = require(script.Parent.DataManager)
local LaneService = require(script.Parent.LaneService)
local RebirthService = require(script.Parent.RebirthService)
local RoundService = require(script.Parent.RoundService)

DataManager.start()
RoundService.start()
LaneService.start()
RebirthService.start()
