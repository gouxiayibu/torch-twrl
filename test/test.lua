local base = torch.TestSuite()
local api = torch.TestSuite()
local performance = torch.TestSuite()
local tilecoding = torch.TestSuite()

local tester = torch.Tester()
local gymClient = require '../src/gym-http-api/binding-lua/gym_http_client'

local perf = require 'rl.perf'({windowSize = 10})
local emptyTable = perf.reset()

local verbose = false
local render = false
local video_callable = 2

local runTest = require '../src/gym-http-api/binding-lua/test_api'({
   gymClient = gymClient, 
   verbose = verbose,
   render = render,
   video_callable = video_callable
})

-- Load all 
local util = require 'rl.util'()

function base.torchTensor()
   local a = {2, torch.Tensor{1, 2, 2}}
   local b = {2, torch.Tensor{1, 2, 2.001}}
   tester:eq(a, b, 0.01, "a and b should be approximately equal")
end

function api.testCartPole()
	local success = runTest('CartPole-v0')
   tester:eq(success, true, "testCartPole shouldn't give an error")
end

function api.testPendulum()
   local success = runTest('Pendulum-v0')
   tester:eq(success, true, "testPendulum shouldn't give an error")
end

function api.testFrozenLake()
   local success = runTest('FrozenLake-v0')
   tester:eq(success, true, "testCartPole shouldn't give an error")
end

function api.testAtari()
   local success = runTest('BattleZone-v0')
   tester:eq(success, true, "testAtari shouldn't give an error if you have Atari configured")
end

function api.testMujoco()
   local success = runTest('InvertedPendulum-v1')
   tester:eq(success, true, "testMujoco shouldn't give an error if you have MuJoCo configured")
end

function tilecoding.tilecodeConsistent()
	local numTilings = 8
   local numTiles = 32
	local memorySize = numTiles * numTiles
	local stateScalingFactor = {1, 1}
	local tc = require 'rl.agent.model.tilecoding'(({
		numTilings = numTilings, 
		memorySize = memorySize, 
		scaleFactor = stateScalingFactor
	}))
	local state = {3.6, 7.21}
   local tiles = tc.tiles(memorySize, numTilings, state)
   local fTiles = tc.feature(state)
   tester:eq(tiles, fTiles, "tiles and featuredTiles should be equal")
end

function tilecoding.tilecodePredictable()
   local numTilings = 8
   local numTiles = 32
   local memorySize = numTiles * numTiles
   local stateScalingFactor = {1, 1}
   local tc = require 'rl.agent.model.tilecoding'(({
      numTilings = numTilings, 
      memorySize = memorySize, 
      scaleFactor = stateScalingFactor
   }))
   local state = {3.6, 7.21}
   local tiles = tc.tiles(memorySize, numTilings, state)
   local predictTables = {820, 119, 115, 465, 458, 260, 512, 505}
   tester:eq(tiles, predictTables, "tiles and predictTables should be equal")
end

function performance.reset()
   local emptyTable = perf.reset()
   tester:eq(emptyTable, {}, "performance: reset failed")
end

function performance.addRewardTerminal()
   local traj, trajs = perf.addReward(1, 1, true)
   tester:eq(traj, {}, "performance: add reward terminal failed")
end

function performance.addRewardNonTerminal()
   local traj, trajs = perf.addReward(1, 1, false)
   tester:eq(traj, {1}, "performance: add reward non-terminal failed")
end

function performance.getSummary()
   local summary = perf.getSummary()
   tester:eq(summary.windowSize, 10, "performance: get summary failed")
end

tester:add(base)
-- tester:add(api)
tester:add(performance)
tester:add(tilecoding)
tester:run()