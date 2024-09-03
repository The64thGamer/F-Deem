using Godot;
using System;

public partial class ButtonHoverEffect : Button
{
	[Export] TextureRect transitionImage;
	[Export] TextureRect bulletImage;
	bool trans;
	const int moveSpeed = 2;
	const int scaleSpeed = 15;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		MouseEntered += () => {trans = true;};
		MouseExited += () => {trans = false; transitionImage.Position = new Vector2(-900,1); bulletImage.Scale = Vector2.One * 0.9f; this.AddThemeFontSizeOverride("font_size",32);};
	}

	public override void _Process(double delta)
	{
		if(trans)
		{
			transitionImage.Position = new Vector2(Mathf.Lerp(transitionImage.Position.X,-7,(float)delta * moveSpeed),1);
			bulletImage.Scale = Vector2.One * Mathf.Lerp(bulletImage.Scale.X,1.1f,(float)delta * scaleSpeed);
			this.AddThemeFontSizeOverride("font_size", 30);
		}
	}
}
