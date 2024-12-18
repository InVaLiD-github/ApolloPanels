if !CLIENT then return end

if ApolloPanels == nil then
	ApolloPanels = {}
	ApolloPanels.PanelConfigs = {}
end

ApolloPanels.PlacedPanels = {}
ApolloPanels.PanelConfigsText = {}
ApolloPanels.HoveredPanel = nil
ApolloPanels.HoveredPanelFrame = nil
ApolloPanels.PreviousHover = nil
ApolloPanels.X = nil
ApolloPanels.Y = nil
ApolloPanels.LastUse = 0

local scale = 0
local maxrange = 0
local inputWindows = {}

ApolloPanels = ApolloPanels or {}

-- The config files have these functions so the server can register the panel, however we don't need them.
-- The options are either do this, or force people to add `if SERVER then ...` statements in the config, and I'm not about to do that lol
function ApolloPanels.PlacePanel() end

function ApolloPanels.GetCursorWithinBounds(identifier, x, y)
	if x == nil or y == nil then return false end
	local sizeX = ApolloPanels.PanelConfigs[identifier]['size'][1]
	local sizeY = ApolloPanels.PanelConfigs[identifier]['size'][2]

	-- X
	if x < 0 then return false end
	if x > sizeX then return false end

	-- Y
	if y < 0 then return false end
	if y > sizeY then return false end

	return true
end

function ApolloPanels.VW(num) return (ScrW()/100)*num end
function ApolloPanels.VH(num) return (ScrH()/100)*num end

function ApolloPanels.GetCursorPos(origin, normal, angle, scale)
    local trace = LocalPlayer():GetEyeTrace()

    local intersection = util.IntersectRayWithPlane(trace.StartPos, LocalPlayer():GetAimVector(), origin, normal)
    if intersection == nil then return nil end

    local localPos = WorldToLocal(intersection, LocalPlayer():GetAngles(), origin, angle)
    return localPos[1] / scale, -localPos[2] / scale
end

function ApolloPanels.UpdateHoverStatus(frame)
	if ApolloPanels.HoveredPanel != frame then

		if ApolloPanels.HoveredPanel != nil then
			ApolloPanels.PreviousHover = ApolloPanels.HoveredPanel
		end

		ApolloPanels.HoveredPanel = frame
	end	
end

function ApolloPanels.WithinBB(mouseX, mouseY, targetX, targetY, targetWidth, targetHeight)
	if mouseX > targetX and mouseX < (targetX + targetWidth) then
		-- X position is within the bounds, do the same calculation for Y
		if mouseY > targetY and mouseY < (targetY + targetHeight) then
			return true
		end
	end

	return false
end

function ApolloPanels.IterateAllChildren(panel, mouseX, mouseY)
	local lastHoveredChild = nil

	for _, child in ipairs(panel:GetChildren()) do
		-- Get the position and size of the child
		local childX, childY = child:GetPos()
		local childWidth, childHeight = child:GetSize()

		-- Check if the mouse is within the bounding box of the child
		if ApolloPanels.WithinBB(mouseX, mouseY, childX, childY, childWidth, childHeight) then
			-- Enable mouse input for the child if it's not already enabled
			if not child:IsMouseInputEnabled() then child:SetMouseInputEnabled(true) end

			-- Request focus if the child is a DHTML or HTML panel
			if child:GetName() == "DHTML" or child:GetName() == "HTML" then
				child:RequestFocus()
			end

			-- Set this child as the currently hovered child
			lastHoveredChild = child
		end

		-- Recursively check any children of this child
		local descendantHovered = ApolloPanels.IterateAllChildren(child, mouseX, mouseY)
		if descendantHovered then
			lastHoveredChild = descendantHovered
		end
	end

	-- Return the last child or descendant that was hovered, or nil if none were
	return lastHoveredChild
end

function ApolloPanels.IsPanelVisible(entity, panelWidth, panelHeight)
	local origin = entity:GetPos()
	local normal = entity:GetAngles():Up()
	local trace = LocalPlayer():GetEyeTrace()

    local intersection = util.IntersectRayWithPlane(trace.StartPos, LocalPlayer():GetAimVector(), origin, normal)
    if intersection == nil then return false end

    local hitPos = trace.HitPos
    local plyPos = LocalPlayer():GetPos()

    if hitPos:Distance(plyPos) > intersection:Distance(plyPos) then
    	return true
    else
    	return false
    end
end

function ApolloPanels.GetHoveredPanel(entity, frame, mouseX, mouseY)
	local frameX, frameY = frame:GetPos()
	local frameWidth, frameHeight = frame:GetSize()
	
	if !ApolloPanels.IsPanelVisible(entity, frameWidth, frameHeight) then return end

	local insideFrame = ApolloPanels.WithinBB(mouseX, mouseY, frameX, frameY, frameWidth, frameHeight)
	local hoveredChild = nil

	if insideFrame then
		-- Check if any child or descendant panel is hovered
		hoveredChild = ApolloPanels.IterateAllChildren(frame, mouseX, mouseY)
		if hoveredChild then
			ApolloPanels.UpdateHoverStatus(hoveredChild)
			ApolloPanels.HoveredPanelFrame = frame
			return hoveredChild
		end
	end

	-- If no children are found, and the mouse is inside the frame, hover the frame itself
	if insideFrame and not hoveredChild then
		ApolloPanels.UpdateHoverStatus(frame)
		ApolloPanels.HoveredPanelFrame = frame
		return frame
	end

	-- If no panel is hovered, clear the current hover status
	if ApolloPanels.HoveredPanel then
		ApolloPanels.PreviousHover = ApolloPanels.HoveredPanel
		ApolloPanels.HoveredPanel = nil
		ApolloPanels.HoveredPanelFrame = nil
	end
end


function ApolloPanels.Create3D2D(entity, frame, scale)
	local cursorEnabled = ApolloPanels.PanelConfigs[entity.Identifier].cursor

	hook.Add("PostDrawOpaqueRenderables", "ApolloPanels."..entity:EntIndex(), function()
		if entity == nil or !IsValid(entity) then
			frame:Remove()
			return
		end

		if frame == nil or !ispanel(frame) then return end
		if entity.Identifier == nil then return end
		
		if ApolloPanels.PanelConfigs[entity.Identifier]['range'] != 0 and LocalPlayer():GetPos():Distance(entity:GetPos()) > ApolloPanels.PanelConfigs[entity.Identifier]['range'] then 
			if frame:IsVisible() then 
				if ApolloPanels.PanelConfigs[entity.Identifier]['onHide'] != nil then
					ApolloPanels.PanelConfigs[entity.Identifier]['onHide'](frame, entity)
				end
				frame:SetVisible(false)
			end

			return 
		else
			if ApolloPanels.PanelConfigs[entity.Identifier]['onAppear'] != nil then
				ApolloPanels.PanelConfigs[entity.Identifier]['onAppear'](frame, entity)
			end

			if !frame:IsVisible() then frame:SetVisible(true) end

			cam.Start3D2D(entity:GetPos(), entity:GetAngles(), scale)
				local x, y = ApolloPanels.GetCursorPos(entity:GetPos(), entity:GetAngles():Up(), entity:GetAngles(), scale)

				frame:SetMouseInputEnabled(true)

				frame.Origin = origin
				frame.Scale = scale
				frame.Angle = angle
				frame.Normal = normal
				
				frame:SetPaintedManually(true)
				frame:PaintManual()

				if ApolloPanels.GetCursorWithinBounds(entity.Identifier, x, y) then
					local hover = ApolloPanels.GetHoveredPanel(entity, frame, x, y)
					if cursorEnabled then
						draw.DrawText("X", "DermaLarge", x, y-13, Color(255,255,255,255), TEXT_ALIGN_CENTER)
						if hover != nil then
							draw.DrawText("O", "DermaLarge", x, y-13, Color(255,255,255,255), TEXT_ALIGN_CENTER)
						end
					end

					if hover != nil then
						ApolloPanels.X = x
						ApolloPanels.Y = y
					end
				else
					if ApolloPanels.HoveredPanelFrame == frame then
						ApolloPanels.PreviousHover = ApolloPanels.HoveredPanel
						ApolloPanels.HoveredPanel = nil
						ApolloPanels.HoveredPanelFrame = nil
					end
				end


				if ApolloPanels.HoveredPanel != nil and IsValid(ApolloPanels.HoveredPanel) and ispanel(ApolloPanels.HoveredPanel) then
					ApolloPanels.MoveHTMLCursor(frame, x, y)
				end

			cam.End3D2D()
		end

	end)
end

function ApolloPanels.MoveHTMLCursor(frame, x, y)
	if x == nil or y == nil or frame == nil then return end
	if frame:GetName() != "DHTML" and frame:GetName() != "HTML" then return end

	-- Call JavaScript to set the cursor position within the HTML page and trigger hover events
	frame:QueueJavascript(string.format([[
		// Keep track of the last hovered elements
		if (typeof lastHovered !== 'undefined' && lastHovered !== null) {
		    lastHovered.forEach(el => el.classList.remove("hover"));
		}

		var element = document.elementFromPoint(%d, %d);
		if (element) {
		    let parents = []; // Store the current element and its parents
		    let currentElement = element;

		    // Traverse up to each parent element, stopping at the body
		    while (currentElement && currentElement.tagName !== "BODY") {
		        currentElement.classList.add("hover");
		        parents.push(currentElement); // Add to the list of hovered elements
		        currentElement = currentElement.parentElement;
		    }

		    // Update lastHovered to all elements with the hover class
		    lastHovered = parents;
		} else {
		    // Clear lastHovered if there's no element at the new position
		    lastHovered = null;
		}

	]], x, y))
end

function ApolloPanels.HTMLClick(frame, x, y)
	if x == nil or y == nil or frame == nil then return end

	frame:RequestFocus()
	-- Call JavaScript to perform a click event at the calculated HTML position
	frame:QueueJavascript(string.format("var element = document.elementFromPoint(%d, %d); if (element) { element.click(); }", x, y))
end

local useKey = input.GetKeyCode(input.LookupBinding("+use"))
hook.Add("Think", "ApolloPanels.Think", function()
	if ApolloPanels.HoveredPanel == nil then return end

	if input.IsKeyDown(useKey) then
		if CurTime() >= ApolloPanels.LastUse + 0.5 then
			if ApolloPanels.HoveredPanel:GetName() != "DHTML" and ApolloPanels.HoveredPanel:GetName() != "HTML" then
				pcall(function()
			        ApolloPanels.HoveredPanel:DoClick()
			    end)
			else
				ApolloPanels.HTMLClick(ApolloPanels.HoveredPanel, ApolloPanels.X, ApolloPanels.Y)
			end

			ApolloPanels.LastUse = CurTime()
		end
	end
end)

function ApolloPanels.CreatePanel(identifier, tbl)
	ApolloPanels.PanelConfigs[identifier] = tbl
end

function ApolloPanels.GetPanel(identifier)
	return ApolloPanels.PanelConfigs[identifier]
end

net.Receive("apollopanels_send", function()
	ApolloPanels.PanelConfigsText = net.ReadTable()

	for _,lua in pairs(ApolloPanels.PanelConfigsText) do
		RunString(lua)
	end

	for _,panel in pairs(ApolloPanels.PlacedPanels) do
		if panel == nil or !IsValid(panel) then return end

		local identifier = panel:GetNWString("apollopanel_type", nil)
		if identifier == nil then return end

		panel:SetPanelType(identifier) 
	end
end)

gameevent.Listen( "player_activate" )
hook.Add( "player_activate", "ApolloPanels.PlayerActivated", function( data )
	timer.Simple(1, function()
		net.Start("apollopanels_spawned")
		net.SendToServer()
	end)
end)