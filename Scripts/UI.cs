using Godot;
using System;

public partial class UI : Control
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		OpenMenu();
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}

	public void CloseMenu()
	{
		Visible = false;
	}
	public void OpenMenu()
	{
		Visible = true;
		Input.MouseMode = Input.MouseModeEnum.Visible;
	}
}
