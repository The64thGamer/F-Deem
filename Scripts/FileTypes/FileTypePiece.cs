using Godot;
using System;
using System.Collections.Generic;

public partial class FileTypePiece : Resource
{
	public string savePieceName;
	public ulong saveId;
	public Piece.PieceColor savePieceColor;
	public Vector3 savePosition;
	public Vector3 saveRotation;
	public Dictionary<string,string> saveTags;
}
