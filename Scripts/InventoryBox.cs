using Godot;
using System;
using System.ComponentModel.DataAnnotations;

public partial class InventoryBox : Node
{
	[Export] TextureRect imageBar;
	[Export] TextureRect imagePrintHead;
	[Export] Control iconHolder;
	[Export(PropertyHint.Range, "0,1,0,or_greater,or_less")] float move;
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		imageBar.Position = new Vector2(0,Mathf.Lerp(-11,-71,move));
		imageBar.Modulate = new Color(1,1,1,1 - ((move * 2f)-1));
		imagePrintHead.Position = new Vector2((((Mathf.Sin(move*25)*0.5f)+0.5f)*50)-25,0);
		iconHolder.Size = new Vector2(75,Mathf.Lerp(0,64,move));
		iconHolder.Position = new Vector2(0,Mathf.Lerp(64,0,move));
	}
}
