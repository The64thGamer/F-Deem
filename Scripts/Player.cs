using Godot;
using System;

public partial class Player : CharacterBody3D
{
	[Export] Node3D playerPieces;
	const float Speed = 10.0f;
	public float gravity = 50;


	Camera3D currentCamera;
    public override void _Ready()
    {      
		currentCamera = GetViewport().GetCamera3D();
		for (int i = 0; i < playerPieces.GetChildCount(); i++)
		{
			Piece piece = playerPieces.GetChild<Piece>(i);
			CollisionShape3D shape = piece.GetShape();
			if(shape != null)
			{
				shape.GetParent().QueueFree();
				shape.Reparent(this,true);
			}
		}
		RandomizePieceColors();
	}
	public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;

		if (!IsOnFloor())
			velocity.Y -= gravity * (float)delta;

		if(Input.IsActionJustPressed("Use"))
		{
			RandomizePieceColors();
		}
		if(velocity.Length() > 0)
		{
			Rotation = new Vector3(0,Mathf.LerpAngle(Rotation.Y,currentCamera.GlobalRotation.Y,(float)delta*velocity.Length()),0);
		}

		Vector2 inputDir = Input.GetVector("Left", "Right", "Up", "Down");
		Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
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

	void RandomizePieceColors()
	{
		uint randA = GD.Randi() % 26;
		uint randB = GD.Randi() % 26;
		for (int i = 0; i < playerPieces.GetChildCount(); i++)
		{
			Piece piece = playerPieces.GetChild<Piece>(i);
			if(i % 2 == 0)
			{
				piece.pieceColor = (Piece.PieceColor)randA;
			}
			else
			{
				piece.pieceColor = (Piece.PieceColor)randB;
			}
		}
	}
}
