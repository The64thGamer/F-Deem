using Godot;
using System;

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
		toggleWorldListMenu,
		toggleTerminal,
		createWorld,
	}
	string oldText;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		ui = GetNode<UI>("/root/UI");
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
			case buttonSetting.toggleWorldListMenu:
				(GetChild(2) as Button).Pressed += () => ui.ToggleWorldListMenu();
				break;
			case buttonSetting.createWorld:
				(GetChild(2) as Button).Pressed += () => ui.CreateWorld();
				break;
			case buttonSetting.toggleTerminal:
				(GetChild(2) as Button).Pressed += () => ui.ToggleTerminal();
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
