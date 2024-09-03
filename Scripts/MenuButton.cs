using Godot;
using System;

[Tool]
public partial class MenuButton : Node
{
	[Export] string text = "TEST!";
	string oldText;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
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
