if !SERVER then return end

util.AddNetworkString("apollopanels_place")
util.AddNetworkString("apollopanels_init")
util.AddNetworkString("apollopanels_close")
util.AddNetworkString("apollopanels_file")
util.AddNetworkString("apollopanels_send")
util.AddNetworkString("apollopanels_spawned")

ApolloPanels = {}
ApolloPanels.PanelConfigs = {}
ApolloPanels.PlacedPanels = {}
ApolloPanels.PanelConfigsText = {}

function ApolloPanels.FindPanels()
	local files, folders = file.Find("ap_configs/*", "LUA")

	for _, folder in ipairs(folders) do
	    if folder ~= "." and folder ~= ".." then
	        for __, filename in pairs(file.Find("ap_configs/"..folder.."/*.lua", "LUA")) do
	        	include("ap_configs/"..folder.."/"..filename)
	        	ApolloPanels.PanelConfigsText[folder.."/"..filename] = file.Read("ap_configs/"..folder.."/"..filename, "LUA")
	    	end
	    end
	end

	for _, filename in pairs(file.Find("ap_configs/*.lua", "LUA")) do
	    include("ap_configs/"..filename)
	    ApolloPanels.PanelConfigsText[filename] = file.Read("ap_configs/"..filename, "LUA")
	end
end

function ApolloPanels.CreatePanel(identifier, tbl)
	if tbl.onCreated != nil and isfunction(tbl.onCreated) then
		tbl.onCreated = string.dump(tbl.onCreated)
	end

	ApolloPanels.PanelConfigs[identifier] = tbl
end

function ApolloPanels.GetPanel(identifier)
	return ApolloPanels.PanelConfigs[identifier]
end

function ApolloPanels.PlacePanel(identifier, position, angle)
	local config = ApolloPanels.GetPanel(identifier)
	if config == nil then return end
	if config.enabled != true then return end

	local entity = ents.Create("apollopanel")
		entity:SetPos(position)
		entity:SetAngles(angle)
		entity:SetModel(config.model)
		entity:SetColor(Color(0,0,0,0))
		entity:SetMaterial("Models/effects/vol_light001")
		entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
		entity:SetPanelType(identifier)
	entity:Spawn()

	local tbl = {
		['identifier'] = identifier, 
		['position'] = position, 
		['angle'] = angle,
		['entity'] = entity,
	}

	table.insert(ApolloPanels.PlacedPanels, tbl)
end

net.Receive("apollopanels_spawned", function(len, ply)
	net.Start("apollopanels_send")
		net.WriteTable(ApolloPanels.PanelConfigsText)
	net.Send(ply)
end)

hook.Add("InitPostEntity", "ApolloPanels.InitPostEntity", function()
	ApolloPanels.FindPanels()
end)

hook.Add("PostCleanupMap", "ApolloPanels.PostCleanupMap", function()
	ApolloPanels.FindPanels()
end)

net.Receive("apollopanels_close", function()
	local tbl = net.ReadTable()
	local identifier = tbl[1]
	local entity = tbl[2]

	if !ApolloPanels.PanelConfigs[identifier].closable then return end

	entity:Remove()
end)