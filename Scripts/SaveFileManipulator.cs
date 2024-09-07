using Godot;
using System;

public partial class SaveFileManipulator : Node
{
	string saveFolder;
	
	public void SetTitle(string name)
	{
		(FindChild("Title",true) as Label).Text = name;
	}

	public void SetDescription(string desc)
	{
		(FindChild("Description",true) as Label).Text = desc;;
	}

	public void StartWorld()
	{
		if(GetNode<FileSaver>("/root/FileSaver").LoadNewSaveFile(saveFolder))
		{
			GetTree().ChangeSceneToFile("res://Scenes/World.tscn");
		}
	}


	public void SetSaveFolder(string folder)
	{
		saveFolder = folder;
	}
}
