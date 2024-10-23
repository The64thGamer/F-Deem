using Godot;
using System;
using System.Collections.Generic;

public partial class FileTypeChunk : Resource
{
	public Vector2 id;
	public Godot.Collections.Array<FileTypePiece> pieceSaveFiles;
	public string setName;
	public BoxShape3D extents;
}
