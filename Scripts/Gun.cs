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
			(GetChild(0) as AudioStreamPlayer3D).Stream = GD.Load<AudioStream>("res://Sounds/Magic Missle.wav");
			(GetChild(0) as AudioStreamPlayer3D).Play();

			PhysicsDirectSpaceState3D spaceState = GetWorld3D().DirectSpaceState;
			PhysicsRayQueryParameters3D query = PhysicsRayQueryParameters3D.Create(GlobalPosition, Vector3.Zero);
			query.CollisionMask = 0b00000000_00000000_00000000_00000111;
			Godot.Collections.Array<Enemy> enemyHits = new Godot.Collections.Array<Enemy>();

			for (int i = -90; i < 91; i++)
			{
				query.To = (GlobalPosition - (GlobalBasis.Z*500)).Rotated(this.GlobalBasis.X.Normalized(),Mathf.DegToRad(i));
				Godot.Collections.Dictionary result = spaceState.IntersectRay(query);
				if (result.Count > 0 && (Node)result["collider"] != null)
				{
					/*
					Node3D testMarker = GD.Load<PackedScene>("res://Prefabs/TestMarker.tscn").Instantiate() as Node3D;
					GetTree().Root.AddChild(testMarker);
					testMarker.GlobalPosition = (Vector3)result["position"];
					*/

					if((Node)result["collider"] is Enemy)
					{
						enemyHits.Add((Node)result["collider"] as Enemy);
					}
					
				}
			}	

			if(enemyHits.Count == 0)
			{
				query.To = GlobalPosition - (GlobalBasis.Z*500);
				Godot.Collections.Dictionary result = spaceState.IntersectRay(query);
				if (result.Count > 0 && (Node)result["collider"] != null )
				{
					(GetChild(0) as AudioStreamPlayer3D).Stream = GD.Load<AudioStream>("res://Sounds/Explode.wav");
					(GetChild(0) as AudioStreamPlayer3D).Play();
					Enemy spawn = GD.Load<PackedScene>("res://Prefabs/Enemy.tscn").Instantiate() as Enemy;
					GetTree().Root.AddChild(spawn);
					spawn.currentTarget = this;
					spawn.GlobalPosition = (Vector3)result["position"];
				}
			}
			else
			{
				int index = -1;
				float currentLength = float.MaxValue;
				for (int i = 0; i < enemyHits.Count; i++)
				{
					if((enemyHits[i].GlobalPosition - GlobalPosition).Length() < currentLength)
					{
						currentLength = (enemyHits[i].GlobalPosition - GlobalPosition).Length();
						index = i;
					}
				}
				if(index >= 0)
				{
					enemyHits[index].AddDamage(-20);
				}
			}
		}
	}
}
