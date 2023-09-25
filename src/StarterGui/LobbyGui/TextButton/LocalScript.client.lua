local button = script.Parent

local opting = 1 -- true

buttonInMainColor = Color3.fromRGB(126, 255, 20)
buttonInBorderColor = Color3.fromRGB(93, 182, 14)

buttonOutMainColor = Color3.fromRGB(255, 62, 23)
buttonOutBorderColor = Color3.fromRGB(194, 0, 0)

local debounce = false

button.Activated:Connect(function()
	if (not debounce) then
		game.ReplicatedStorage.Events.Settings:FireServer("Opt", {["Opting-Out"] = opting})
		opting = 1 - opting
		
		if (opting == 0) then
			button.BackgroundColor3 = buttonOutMainColor
			button.BorderColor3 = buttonOutBorderColor
			button.Text = "Opting Out"
		else 
			button.BackgroundColor3 = buttonInMainColor
			button.BorderColor3 = buttonInBorderColor
			button.Text = "Opting In"
		end
		debounce = true
		wait(0.3)
		debounce = false
	end
end)
