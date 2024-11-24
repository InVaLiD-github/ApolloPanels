ApolloPanels.CreatePanel("finishedLoading", {
	enabled = true, -- Should this panel be created?
	range = 99999, -- In hammer units, how close do you have to be for the panel to appear?
	scale = 0.2,
	size = {900, 200},
	model = "models/hunter/plates/platewdw025x025.mdl", -- The model of the entity the panel is tied to. Will spawn in the top-left corner of the panel.
	closable = false,
	cursor = false,

	frame = {
		enabled = false, -- Is the frame enabled? (If not, your onCreated function needs to return a panel in the frame's place.)
		title = "Example Panel!", -- Title for the frame, if enabled.
	},

	-- 'frame' will return nil if the frame is disabled.
	-- The 'entity' argument is the physical entity the panel is parented to (of which is created by the script for you), should you want to do anything with it. 
	onCreated = function(self, entity)
		local html = vgui.Create("DHTML")
			html:SetSize(900, 200)
			html:SetPos(0,0)
			html:SetHTML([[
			<img src="http://r2.exoticservers.co:3052/nebula/finishedloading.png"></img>

			<style>
				body{
					background-color: #0000; 
					overflow: hidden;
				}

				img {
					width: 858;
					height: 175;
					object-fit: cover;
				} 
			</style>
		]])

		local button = vgui.Create("DButton", html)
		button:SetSize(html:GetSize())
		button:SetText("")
		function button:Paint() end
		function button:DoClick()
			Questionnaire.VGUI()
		end

		return html
	end,
})

ApolloPanels.PlacePanel("finishedLoading", Vector(9693, 14559, -14003), Angle(0,180,90))