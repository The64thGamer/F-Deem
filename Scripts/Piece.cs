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

	public override void _Process(double delta)
	{		    
		if(pieceColor != oldColor)
		{
			UpdateColor();
		}
	}

	void UpdateColor()
	{
		if(pieceColor == PieceColor.none)
		{
			pieceColor = PieceColor.trans_rights_pink;
		}
		oldColor = pieceColor;
		MeshInstance3D child = GetChild<MeshInstance3D>(0);
		    GD.Print("My resource was set!");
		child.MaterialOverride = GD.Load<Material>(materialPaths + pieceColor.ToString()+".tres");
		child.LodBias = lodBias;
	}
}
