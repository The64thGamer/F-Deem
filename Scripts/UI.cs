using Godot;
using System;
using Console = media.Laura.SofiaConsole.Console;


public partial class UI : Control
{

	const int closeAllSubMenusIndex = -1;
	const int optionsMenuChildIndex = 1;
	const int worldListMenuChildIndex = 2;

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

	public void ToggleWorldListMenu()
	{
		if((GetChild(worldListMenuChildIndex) as Control).Visible)
		{
			CloseSubMenus(closeAllSubMenusIndex);
		}
		else
		{
			CloseSubMenus(worldListMenuChildIndex);
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

	public void CreateWorld()
	{
		GetNode<FileSaver>("/root/FileSaver").CreateNewSaveFile(
			new Godot.Collections.Dictionary<string, Variant>(){
				{ "World Name", ES.Load("worldName","")},
				{ "World Author", ES.Load("Name","")},
				{ "World Created Time UTC", DateTime.Now.ToUniversalTime().ToString(@"MM\/dd\/yyyy h\:mm tt")},
				{ "World Created Version", Tr("CURRENT_VERSION")},
				{ "World Seed", ES.Load("worldSeed","")},}
			, true
		);
		CloseSubMenus(closeAllSubMenusIndex);
		CloseSubMenus(worldListMenuChildIndex);
	}

	public void ToggleTerminal()
	{
		CloseSubMenus(closeAllSubMenusIndex);
		Console.Instance.SetConsole(!Console.Instance.Open);
	}
}
