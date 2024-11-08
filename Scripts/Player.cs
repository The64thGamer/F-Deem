using Godot;
using System;

public partial class Player : CharacterBody3D
{
	[Export] Node3D playerPieces;

	public Vector2 currentChunk;

	const float Speed = 10.0f;
	const float stopSpeed = 7f;
	public float gravity = 50;
	bool battleMode;
	Vector2 currentDirection;

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
				//shape.Reparent(this,true);
			}
		}
		RandomizePieceColors();
	}  
	public override void _Process(double delta)
    {
        if (Input.IsActionJustPressed("Switch Mode"))
        {
            battleMode = !battleMode;

			if(battleMode)
			{
				playerPieces.Visible = false;
			}
			else
			{
				playerPieces.Visible = true;
			}
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

		if(!battleMode)
		{			
			PhysicsDirectSpaceState3D spaceState = currentCamera.GetWorld3D().DirectSpaceState;
			PhysicsRayQueryParameters3D query = PhysicsRayQueryParameters3D.Create(currentCamera.GlobalPosition, currentCamera.GlobalPosition + currentCamera.ProjectRayNormal(GetViewport().GetMousePosition()) * 1000);
			query.CollisionMask = 0b00000000_00000000_00000000_00000001;
			Godot.Collections.Dictionary result = spaceState.IntersectRay(query);
			if (result.Count > 0 && !((Vector3)result["position"]).Equals(GlobalPosition))
			{
				Vector3 oldRot = GlobalRotation;
				LookAt((Vector3)result["position"]);
				GlobalRotation = new Vector3(0,Mathf.LerpAngle(oldRot.Y,GlobalRotation.Y,(float)(delta*5)),0);	
			}
		}
		else
		{		
			Rotation = new Vector3(0,currentCamera.GlobalRotation.Y,0);
		}

        Vector3 direction;
        if (battleMode)
        {
            Vector2 inputDir = Input.GetVector("Left", "Right", "Up", "Down");
            direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
        }
        else
        {
            Vector2 inputDir = Input.GetVector("Left", "Right", "Up", "Down");
            Vector3 relativeDir = new Vector3(inputDir.X, 0.0f, inputDir.Y).Rotated(Vector3.Up, currentCamera.GlobalRotation.Y);
            direction = new Vector3(relativeDir.X, 0, relativeDir.Z).Normalized();
        }

		currentDirection = new Vector2(Mathf.Lerp(currentDirection.X,direction.X,(float)delta*stopSpeed),Mathf.Lerp(currentDirection.Y,direction.Z,(float)delta*stopSpeed));

        if (currentDirection != Vector2.Zero)
		{
			velocity.X = currentDirection.X * Speed;
			velocity.Z = currentDirection.Y * Speed;
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
}
