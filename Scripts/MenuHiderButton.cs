using Godot;
using System;

public partial class MenuHiderButton : Button
{
	UI ui;
	[Export] buttonSetting setting;
	enum buttonSetting
	{
		none,
		toggleOptionsMenu,
		toggleWorldListMenu,
		toggleTerminal,
	}
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		ui = GetNode<UI>("/root/UI");

		switch(setting)
		{
			case buttonSetting.toggleOptionsMenu:
				Pressed += () => ui.ToggleOptionsMenu();
				break;
			case buttonSetting.toggleWorldListMenu:
				Pressed += () => ui.ToggleWorldListMenu();
				break;
			case buttonSetting.toggleTerminal:
				Pressed += () => ui.ToggleTerminal();
				break;
			default:
			break;
		}
	}
}
