using Godot;
using System;
using System.IO;
using System.Linq;

public partial class WorldManager : Node
{
	Godot.Collections.Dictionary<Vector2,Node3D> LoadedChunks;
	FileSaver fileSaver;
	const string setPath = "res://Scenes/Sets/";
	public override void _Ready()
	{
		fileSaver = GetNode<FileSaver>("/root/FileSaver");
	}

	public void ResetChunks()
	{
		for (int i = 0; i < LoadedChunks.Keys.Count; i++)
		{
			SaveAndUnloadChunk(LoadedChunks.Keys.ElementAt(i));
		}
	}

	public void GenerateChunk(Vector2 id)
	{
		if(LoadedChunks.ContainsKey(id))
		{
			LoadedChunks.Remove(id);
		}
		Random rnd = new Random();
		int i = rnd.Next() % 5;
		LoadedChunks.Add(id,GD.Load<PackedScene>(setPath+i+".tscn").Instantiate() as Node3D);
	}

	public void SaveAndUnloadChunk(Vector2 id)
	{
		if(!LoadedChunks.ContainsKey(id))
		{
			return;
		}

		Node3D set = LoadedChunks[id];
		Node3D pieces = set.FindChild("Pieces") as Node3D;
		Area3D area = set.FindChild("Area3D") as Area3D;
		if(pieces == null || area == null)
		{
			return;
		}
		CollisionShape3D shape = area.GetChild(0) as CollisionShape3D;
		if(shape == null)
		{
			return;
		}
		BoxShape3D box = shape.Shape as BoxShape3D;
		if(box == null)
		{
			return;
		}

		FileTypeChunk chunk = new FileTypeChunk();
		chunk.setName = set.Name;
		chunk.id = id;
		chunk.extents = box;
		chunk.pieceSaveFiles = new Godot.Collections.Array<FileTypePiece>();
		foreach (Piece item in pieces.GetChildren())
		{
			chunk.pieceSaveFiles.Add(item.GenerateSaveFile());
		}
		fileSaver.SaveChunk(chunk);
	}

	public void LoadChunk(Vector2 id)
	{
		if(!LoadedChunks.ContainsKey(id))
		{
			return;
		}
	}

	public void CloseChunk(Vector2 id)
	{
		if(!LoadedChunks.ContainsKey(id))
		{
			return;
		}
	}

	public void OpenChunk(Vector2 id)
	{
		if(!LoadedChunks.ContainsKey(id))
		{
			return;
		}
	}
}
