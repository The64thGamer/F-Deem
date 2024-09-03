using Godot;
using System;

public partial class Gun : Node
{
	bool battleMode;
	float cooldown;
	const float setCooldown = 1;

	public override void _Ready()
	{
	}

	public override void _Process(double delta)
    {
        if (Input.IsActionJustPressed("Switch Mode"))
        {
            battleMode = !battleMode;
		}

		cooldown = Mathf.Max(0,cooldown - (float)delta);

		if(battleMode && Input.IsActionPressed("Action") && cooldown == 0)
        {
			cooldown = setCooldown;

		}
	}
}
