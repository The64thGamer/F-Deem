using Godot;
using System;

[Tool]
public partial class MenuButton : Node
{
	[Export] string text = "TEST!";
	UI ui;
	[Export] buttonSetting setting;
	enum buttonSetting
	{
		none,
		closePauseMenu,
		openPauseMenu,
		toggleOptionsMenu,
	}
	string oldText;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		Node parent = this;
		while(true)
		{				
			if(parent == null)
			{
				GD.PrintErr("Can't Find Main Menu");
				return;
			}
			if(parent.Name.ToString().ToLower() == "ui")
			{
				break;
			}
			parent = parent.GetParent();
		}
		ui = parent as UI;
		switch(setting)
		{
			case buttonSetting.closePauseMenu:
				(GetChild(2) as Button).Pressed += () => ui.CloseMenu();
			break;
			case buttonSetting.openPauseMenu:
				(GetChild(2) as Button).Pressed += () => ui.OpenMenu();
			break;
			case buttonSetting.toggleOptionsMenu:
				(GetChild(2) as Button).Pressed += () => ui.ToggleOptionsMenu();
				break;
			default:
			break;
		}
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		if(oldText != text)
		{
			oldText = text;
			(GetChild(2) as Button).Text = text;
		}
	}
}
