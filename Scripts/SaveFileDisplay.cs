using Godot;
using System;

public partial class SaveFileDisplay : Control
{
	[Export] PackedScene fileNode;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		VisibilityChanged += SetSaveFiles;
	}

	void SetSaveFiles()
	{
		foreach(Node n in GetChildren())
		{
			n.QueueFree();
		}

		FileSaver saver = GetNode<FileSaver>("/root/FileSaver");

		string[] checkDirs = DirAccess.GetDirectoriesAt("user://");
		bool folderCheck = false;
		foreach(string path in checkDirs)
		{
			if(path == FileSaver.savePathFolderName)
			{
				folderCheck = true;
			}
		}
		if(!folderCheck)
		{
			DirAccess newDir = DirAccess.Open("user://");
			newDir.MakeDir(FileSaver.savePathFolderName);
		}

		string[] dirs = DirAccess.GetDirectoriesAt(FileSaver.savePath);
		foreach(string path in dirs)
		{
			Node currentNode = fileNode.Instantiate();
			AddChild(currentNode);
			SaveFileManipulator sfm = currentNode as SaveFileManipulator;
			sfm.SetSaveFolder(path);
			Godot.Collections.Dictionary<string, Variant> data = saver.AcquireSaveData(path);
			bool check = true;
			string desc = "";
			if(data != null)
			{
				Variant value;
				if(data.TryGetValue("World Name", out value))
				{
					sfm.SetTitle(value.ToString());
				}
				else
				{
					check = false;
					desc += " <Corrupted World Name>";
				}

				if(data.TryGetValue("World Created Time UTC", out value))
				{
					desc += "Created " + value.ToString();
				}
				else
				{
					check = false;
					desc += " <Corrupted Creation Time>";
				}

				if(data.TryGetValue("World Author", out value))
				{
					desc += " by " + value.ToString();
				}
				else
				{
					check = false;
					desc += " <Corrupted Author>";
				}

				if(data.TryGetValue("World Seed", out value))
				{
					desc += "\nSeed: " + value.ToString();
				}
				else
				{
					check = false;
					desc += " <Corrupted Seed>";
				}
			}
			else
			{
				check = false;
				desc += "<Save Data Null>";
			}

			if(!check)
			{
				sfm.SetTitle(Tr("ERROR_CORRUPTED_WORLD"));
			}

			sfm.SetDescription(desc);

		}
	}
}
