using Godot;
using System;

public partial class Enemy : CharacterBody3D
{
	[Export] Node3D playerPieces;
	[Export] public Node3D currentTarget;
	[Export] float initHealth;
	float currentHealth;
	const float Speed = 5.0f;
	const float gravity = 50;
	const float minRandWalkTime = 1.0f;
	const float maxRandWalkTime = 3.0f;

	float moveTimer;
	Vector3 currentDirection;
	Vector3[] directions = {
    new Vector3(1, 0, 0),
    new Vector3(0, 0, 1),
    new Vector3(-1, 0, 0),
    new Vector3(0, 0, -1),
    new Vector3(0.7f, 0, 0.7f),
    new Vector3(0.7f, 0, -0.7f),
    new Vector3(-0.7f, 0, 0.7f),
    new Vector3(-0.7f, 0, -0.7f)
	};

    public override void _Ready()
    {      
		currentHealth = initHealth;
		for (int i = 0; i < playerPieces.GetChildCount(); i++)
		{
			Piece piece = playerPieces.GetChild<Piece>(i);
			CollisionShape3D shape = piece.GetShape();
			if(shape != null)
			{
				shape.GetParent().QueueFree();
				//shape.Reparent(this,true);
			}
		}
		RandomizePieceColors();
	}  
	public override void _Process(double delta)
    {
		if(currentTarget == null)
		{
			return;
		}

		moveTimer = Mathf.Max(0,moveTimer-(float)delta);
		if(moveTimer == 0)
		{
			moveTimer = (GD.Randf() * (maxRandWalkTime-minRandWalkTime)) + minRandWalkTime;
			currentDirection = currentTarget.GlobalPosition - this.GlobalPosition;
				currentDirection = currentDirection.Normalized();
				float newAngle = float.MaxValue;
				float angle;
				int finalIndex = 0;
				for (int i = 0; i < directions.Length; i++)
				{
					angle = currentDirection.AngleTo(directions[i]);
					if (angle < newAngle)
					{
						newAngle = angle;
						finalIndex = i;
					}
				}
				currentDirection = directions[finalIndex];
		}
		if((currentTarget.GlobalPosition - this.GlobalPosition).Length() < 3.5f)
		{
			currentDirection = Vector3.Zero;
			moveTimer = 0;
		}
		else
		{
			Vector3 oldRot = GlobalRotation;
			LookAt(GlobalPosition + currentDirection);
			GlobalRotation = new Vector3(0,Mathf.LerpAngle(oldRot.Y,GlobalRotation.Y,(float)(delta*15)),0);	
		}
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

        if (currentDirection != Vector3.Zero)
		{
			velocity.X = currentDirection.X * Speed;
			velocity.Z = currentDirection.Z * Speed;
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
		uint randA = GD.Randi() % 27;
		uint randB = GD.Randi() % 27;
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

	void ValidateTarget()
	{
		if(currentTarget == null)
		{
			TryNewTarget();
		}
		else
		{

		}
	}

	void TryNewTarget()
	{
		Godot.Collections.Array<Node> players = GetTree().GetNodesInGroup("Players");

		for (int i = 0; i < players.Count; i++)
		{
			
		}
	}

	public void AddDamage(int health)
	{
		(GetChild(2) as AudioStreamPlayer3D).Stream = GD.Load<AudioStream>("res://Sounds/Pain Test.wav");
		(GetChild(2) as AudioStreamPlayer3D).Play();
		currentHealth += health;
		if(currentHealth <= 0)
		{
			Die();
		}
	}

	public void Die()
	{
		QueueFree();
	}
}
