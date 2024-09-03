using Godot;
using System;
using System.ComponentModel.DataAnnotations;

[Tool]
public partial class InventoryBox : Node
{
	[Export] Texture2D image;
	TextureRect imageBar;
	TextureRect imagePrintHead;
	Control iconHolder;
	TextureRect icon;
	float move;
	Texture2D oldImage;
	const float loadSpeed = 3.5f;
	
	public override void _Ready()
    {  
		imageBar = GetChild(0).GetChild(0) as TextureRect;
		imagePrintHead = imageBar.GetChild(0) as TextureRect;
		iconHolder = GetChild(0).GetChild(1) as Control;
		icon = iconHolder.GetChild(0) as TextureRect;
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		if(move < 1)
		{
			move = Mathf.Min(move + ((float)delta * loadSpeed),1);
			imageBar.Position = new Vector2(0,Mathf.Lerp(-8,-71,move));
			imageBar.Modulate = new Color(1,1,1,1 - ((move * 2f)-1));
			imagePrintHead.Position = new Vector2((((Mathf.Sin(move*25)*0.5f)+0.5f)*50)-25,0);
			iconHolder.Size = new Vector2(75,Mathf.Lerp(0,69f,move));
			iconHolder.Position = new Vector2(0,Mathf.Lerp(69f,0,move));
		}

		if(image != oldImage)
		{
			if(image == null)
			{
				icon.Texture = null;
				oldImage = null;
				return;
			}
			oldImage = image;
			move = 0;
			icon.Texture = image;
		}
	}
}
