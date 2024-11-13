-- If you're looking to spawn this entity, see the bottom of the example.lua file in the ap_configs folder :D
-- These aren't really meant to be spawned through the spawn menu but you'll make it work if you got the know-how!

ENT.Base = "base_gmodentity"
ENT.PrintName = "ApolloPanel"
ENT.Author = "ap6"
ENT.Contact = "@apollomakesmusic on Discord"
ENT.Purpose = "Adds world-based UI panels to your game"
ENT.Spawnable = false

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
	    self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" ) -- Sets the model for the Entity.
	    self:PhysicsInit( SOLID_VPHYSICS ) -- Initializes physics for the Entity, making it solid and interactable.
	    self:SetMoveType( MOVETYPE_VPHYSICS ) -- Sets how the Entity moves, using physics.
	end

	function ENT:SetPanelType(identifier)
		if ApolloPanels.PanelConfigs[identifier] == nil then error("Tried to create ApolloPanel with non-existant identifier!") return end

		self:SetNWString("apollopanel_type", identifier)
	end

elseif CLIENT then
	function ENT:Draw()
    	self:DrawModel()
	end

	function ENT:SetPanelType(identifier)
		local entity = self

	    local panel = ApolloPanels.GetPanel(identifier)
		if panel == nil then return end


		local frame = nil
		if panel.frame.enabled then
			frame = vgui.Create("DFrame")
			frame:SetPos(0,0)
			frame:SetSize(panel.size[1], panel.size[2])
			frame:SetTitle(panel.frame.title)
			frame:ShowCloseButton(panel.closable)
		end

		if panel.onCreated != nil then
			local returned = panel.onCreated(panel, entity, frame)
			if returned != nil then frame = returned end
		end

		function frame:OnRemove()
			if entity != nil and IsValid(entity) then
				net.Start("apollopanels_close")
					net.WriteTable({identifier, entity})
				net.SendToServer()
			end

			self:Remove()
		end

		ApolloPanels.Create3D2D(entity, frame, panel.scale)
	end

	function ENT:Initialize()
		self.Created = false

		timer.Create("ApolloPanel_Init_"..self:EntIndex(), 1, 0, function()
			if self.Created == true then timer.Remove("ApolloPanel_Init_"..self:EntIndex()) end

			if self:GetNWString("apollopanel_type") != nil and self:GetNWString("apollopanel_type") != "" then
				self.Identifier = self:GetNWString("apollopanel_type")
				self:SetPanelType(self.Identifier)
				self.Created = true
			end
		end)
	end
end