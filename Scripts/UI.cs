using Godot;
using System;

public partial class UI : Control
{

	const int closeAllSubMenusIndex = -1;
	const int optionsMenuChildIndex = 1;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		OpenMenu();
		
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		if(Input.IsActionJustPressed("Pause"))
		{
			if(Visible)
			{
				CloseMenu();
			}
			else
			{
				OpenMenu();
			}
		}
	}

	public void OpenOptionsMenu()
	{
		CloseSubMenus(optionsMenuChildIndex);
	}

	public void ToggleOptionsMenu()
	{
		if((GetChild(optionsMenuChildIndex) as Control).Visible)
		{
			CloseSubMenus(closeAllSubMenusIndex);
		}
		else
		{
			CloseSubMenus(optionsMenuChildIndex);
		}
	}

	public void CloseMenu()
	{
		Visible = false;
		CloseSubMenus(closeAllSubMenusIndex);
	}
	public void OpenMenu()
	{
		Visible = true;
		Input.MouseMode = Input.MouseModeEnum.Visible;
	}

	void CloseSubMenus(int exception) //0 index exception
	{
		for (int i = 1; i < GetChildCount(); i++)
		{
			(GetChild(i) as Control).Visible = false;
		}

		if(exception < 1 || exception >= GetChildCount())
		{
			return;
		}

		(GetChild(exception) as Control).Visible = true;
	}
}
