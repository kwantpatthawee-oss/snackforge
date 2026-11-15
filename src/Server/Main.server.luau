--!strict
local DataManager = require(script.Parent.DataManager)
local LaneService = require(script.Parent.LaneService)
local RoundService = require(script.Parent.RoundService)

DataManager.start()
RoundService.start()
LaneService.start()
