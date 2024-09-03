using Godot;
using System;

public partial class Gun : Node3D
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
			(GetChild(0) as AudioStreamPlayer3D).Play();
			PhysicsDirectSpaceState3D spaceState = GetWorld3D().DirectSpaceState;
			PhysicsRayQueryParameters3D query = PhysicsRayQueryParameters3D.Create(GlobalPosition, GlobalPosition - (GlobalBasis.Z*1000));
			query.CollisionMask = 0b00000000_00000000_00000000_00000111;
			Godot.Collections.Dictionary result = spaceState.IntersectRay(query);
			if (result.Count > 0)
			{
				Node resultNode = (Node)result["collider"];
				if(resultNode != null)
				{
					GD.Print(resultNode.Name);
					(GetChild(0) as AudioStreamPlayer3D).Stream = GD.Load<AudioStream>("res://Sounds/Explode.wav");
					(GetChild(0) as AudioStreamPlayer3D).Play();

					Enemy spawn = GD.Load<PackedScene>("res://Prefabs/Enemy.tscn").Instantiate() as Enemy;
					GetTree().Root.AddChild(spawn);
					spawn.currentTarget = this;
					spawn.GlobalPosition = (Vector3)result["position"];
				}
			}
		}
	}
}
