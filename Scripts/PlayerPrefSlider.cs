using Godot;
using System;
using System.Linq;

[Tool]
public partial class PlayerPrefSlider : Control
{
	[ExportCategory("Slider")]
	[Export] float minValue;
	[Export] float maxValue;
	[Export] float unsavedValue;
	[Export] float step;
	[ExportCategory("Labels")]
	[Export] string startLabel;
	[Export] Godot.Collections.Array<string> middleLabels;
	[Export] string endLabel;
	[ExportCategory("PlayerPrefs")]
	[Export] PPSliderActions action;
	public enum PPSliderActions
	{
		volumeSound,
		volumeMusic,
		lods,
	}

	Slider slider;
	Label label;
	Label valueLabel;


	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		label = GetChild(0) as Label;
		valueLabel = GetChild(2) as Label;
		slider = GetChild(1) as Slider;
		slider.ValueChanged += (e) => UpdateValue(e);
		slider.Step = step;
		slider.MinValue = minValue;
		slider.MaxValue = maxValue;
		if(ES.Load(action.ToString(),float.MinValue) != float.MinValue)
		{
			slider.Value = ES.Load(action.ToString(),float.MinValue);
		}
		else
		{
			slider.Value = unsavedValue;
		}
	}

	void UpdateValue(double value)
	{
		ES.Save(action.ToString(),(float)value);
		GD.Print(action.ToString() + " set to " + value);

		if(step == 1)
		{
			valueLabel.Text = value.ToString();
		}
		else
		{
			valueLabel.Text = value.ToString("0.###");
		}

		if(value == minValue)
		{
			label.Text = startLabel;
		}
		else if(value == maxValue)
		{
			label.Text = endLabel;
		}
		else
		{
			label.Text = middleLabels[(int)((value-minValue)/(maxValue-minValue)*middleLabels.Count)];
		}
		
		switch (action)
		{
			case PPSliderActions.lods:
				GetViewport().MeshLodThreshold = (float)slider.Value;
				ProjectSettings.SetSetting("rendering/mesh_lod/lod_change/threshold_pixels",slider.Value);
				break;
			case PPSliderActions.volumeSound:
				AudioServer.SetBusVolumeDb(2,Mathf.LinearToDb((float)slider.Value));
				break;
			case PPSliderActions.volumeMusic:
				AudioServer.SetBusVolumeDb(1,Mathf.LinearToDb((float)slider.Value));
				break;
			default:
			GD.PrintErr("You forgot to implement this action!!! (" + action.ToString() + ")");
			break;
		}
	}
}
