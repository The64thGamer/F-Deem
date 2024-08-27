using Godot;
using System;

[Tool]
public partial class Piece : Node
{
	[Export] public PieceColor pieceColor;
	PieceColor oldColor = PieceColor.none;
	public enum PieceColor
	{
		white,
		gray,
		plated_gray,
		black,
		red,
		orange,
		plated_orange,
		soaked_orange,
		tinged_yellow,
		yellow,
		plated_yellow,
		tinged_green,
		green,
		soaked_green,
		tinged_blue,
		blue,
		purple,
		pink,
		soaked_pink,
		trans_rights_white,
		trans_rights_red,
		trans_rights_yellow,
		trans_rights_green,
		trans_rights_blue,
		trans_rights_pink,
		trans_rights_black,
		none,
	}
	const string materialPaths = "res://Materials/";
	const int lodBias = 2;
    public override void _Ready()
    {      
		oldColor = PieceColor.none;
	}
	public override void _Process(double delta)
	{		    
		if(pieceColor != oldColor)
		{
			UpdateColor();
		}
	}

	public CollisionShape3D GetShape()
	{
		if(GetChildCount() <= 1)
		{
			GD.Print(Name + " doesn't have any collision children");
			return null;
		}
		return GetChild<StaticBody3D>(1).GetChild<CollisionShape3D>(0);
	}

	void UpdateColor()
	{
		if(pieceColor == PieceColor.none)
		{
			pieceColor = PieceColor.trans_rights_pink;
		}
		oldColor = pieceColor;
		MeshInstance3D child = GetChild<MeshInstance3D>(0);
		child.MaterialOverride = GD.Load<Material>(materialPaths + pieceColor.ToString()+".tres");
		child.LodBias = lodBias;
	}
}
