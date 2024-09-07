using Godot;
using System;

public partial class ResetTabContainerOnHide : TabContainer
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		VisibilityChanged += () => ResetTabs();
	}
	
	void ResetTabs()
	{
		CurrentTab = 0;
	}
	
}
