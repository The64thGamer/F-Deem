using Godot;
using System;
using System.Linq;
using Console = media.Laura.SofiaConsole.Console;

[Tool]
public partial class PlayerPrefString : Control
{
	[ExportCategory("Line Edit")]
	[Export] string unsavedValue;
	[Export] bool fieldIsRandomSeed;

	[ExportCategory("Labels")]
	[Export] string text;

	[ExportCategory("PlayerPrefs")]
	[Export] string prefName;
	LineEdit lineEdit;
	Label label;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		lineEdit = GetChild(1) as LineEdit;
		label = GetChild(0) as Label;
		lineEdit.TextChanged += (e) => UpdateValue(e);
		lineEdit.PlaceholderText = unsavedValue;
		label.Text = text;

		if(fieldIsRandomSeed)
		{
            Random rnd = new Random();
            lineEdit.Text = rnd.Next().ToString();
		}
		else
		{
			if(ES.Load(prefName,"⚠") != "⚠")
			{
				lineEdit.Text = ES.Load(prefName,"⚠");
			}
			else
			{
				lineEdit.Text = unsavedValue;
			}
		}

		UpdateValue(lineEdit.Text);
	}

	void UpdateValue(string value)
	{
		if(fieldIsRandomSeed)
        {
            ES.Save(prefName,GetDeterministicHashCode(value));
        }
		else
		{
			ES.Save(prefName,value);
		}
		
		Console.Instance.Print(prefName + " set to " + value);
		if(lineEdit.Text != value)
		{
			lineEdit.Text = value;
		}
		label.Text = text;
	}

    string GetDeterministicHashCode(string str)
    {
        int hash1 = (5381 << 16) + 5381;
        int hash2 = hash1;

        for (int i = 0; i < str.Length; i += 2)
        {
            hash1 = ((hash1 << 5) + hash1) ^ str[i];
            if (i == str.Length - 1)
                break;
            hash2 = ((hash2 << 5) + hash2) ^ str[i + 1];
        }

        return (hash1 + (hash2 * 1566083941)).ToString();
    }
}
