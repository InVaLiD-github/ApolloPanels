ApolloPanels.CreatePanel("example", { -- `example` is the identifier for your panel and must be unique, otherwise you risk overriding another panel.
	enabled = false, -- Should this panel be created?
	range = 250, -- In hammer units, how close do you have to be for the panel to appear?
	scale = 0.01, -- If you want more resolution, crank up the size parameter and lower the scale!
	size = {500, 500},
	model = "models/hunter/plates/plate025x025.mdl", -- The model of the entity the panel is tied to. Will spawn in the top-left corner of the panel.
	closable = false,
	cursor = true, -- ApolloPanels shows a cursor of sorts if this is enabled, feel free to disable it if you don't like it!

	frame = {
		enabled = true, -- Is the frame enabled? (If not, your onCreated function needs to return a panel in the frame's place.)
		title = "Example Panel!", -- Title for the frame, if enabled.
	},

	-- 'frame' will return nil if the frame is disabled.
	-- The 'entity' argument is the physical entity the panel is parented to (of which is created by the script for you), should you want to do anything with it. 
	-- onCreated runs in the CLIENT realm.
	onCreated = function(self, entity, frame)
		-- This function gets ran when the panel is created.
		-- You can make any VGUI Element like you're making a normal panel and it should work fine.

		-- If you want a DHTML element and you're trying to add a hover pseudo class (i.e. `#id:hover`),
		-- You MUST use a . instead (e.x. `#id.hover`). I can't make the script use mouseevents, so the `:hover` pseudo-element doesn't work.
		-- You can see some usage in the example HTML element, where it sets the 'Hello World' text's background to white when you hover over it.

		-- You can use `self` to reference this configuration, as shown below when I set the DHTML's size.
		local html = vgui.Create("DHTML", frame)
		html:SetSize(self.size[1], self.size[2])
		html:SetHTML([[
			<a>Hello world!</a>

			<style>
				a.hover{
					background-color: #fff;
				}
			</style>
		]])

		local button = vgui.Create("DButton", html)
		button:SetSize(self.size[1], 50)
		button:SetPos(0, 100)
		button:SetText("I'm a button!")
		function button.DoClick()
			LocalPlayer():ChatPrint("GET YOUR GRUBBY HANDS OFF ME!")
		end
		
		-- You must have a return statement with the panel everything is parented to if the frame isn't enabled.
		-- It's commented out right now because we have the frame enabled, but I gotta cover my bases.
		//return html
	end,
})

-- This is how you create a new panel. Placing this here will make the panel spawn as soon as the server starts. (this essentially permaprops it)
-- You can use this anywhere in any script to create this panel, as long as you're in the SERVER realm, otherwise the script won't error, but it won't spawn.
-- ApolloPanels.PlacePanel(string identifier, Vector position, Angle angle)
ApolloPanels.PlacePanel("example", Vector(-143.153473, 1092.938110, 80.015991), Angle(0,90,90))
