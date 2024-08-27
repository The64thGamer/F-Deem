using Godot;
using System;

public partial class Player : CharacterBody3D
{
	const float Speed = 5.0f;
	const float JumpVelocity = 10.0f;
	public float gravity = 50;


	Camera3D currentCamera;
    public override void _Ready()
    {      
		currentCamera = GetViewport().GetCamera3D();
	}
	public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;

		if (!IsOnFloor())
			velocity.Y -= gravity * (float)delta;

		Vector2 inputDir = Input.GetVector("Left", "Right", "Up", "Down");
		Vector3 relativeDir = new Vector3(inputDir.X, 0.0f, inputDir.Y).Rotated(Vector3.Up, currentCamera.GlobalRotation.Y);
		Vector3 direction = (Transform.Basis * new Vector3(relativeDir.X, 0, relativeDir.Z)).Normalized();
		if (direction != Vector3.Zero)
		{
			velocity.X = direction.X * Speed;
			velocity.Z = direction.Z * Speed;
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed);
		}

		Velocity = velocity;
		MoveAndSlide();
	}
}
