
# F-Deem!

> [!NOTE]
> Software is still in the extremely early development stages!

A combination video game and 3D printable construction toy. As you collect items and resources in-game, you'll be able to send them away to be 3D printed physically, though you don't need a printer to play and enjoy the game.

# Pieces
All of the game's 3D assets are made to be 3D print compatible. In the ```/Models/``` folder, the raw asset files for the pieces can be found in ```Oh Funny Horse Parts.blend```. Two subfolders also contain the STL files for printing, and GLB files used for display in-game. A mirror of the STL files are also [available on Printables](https://www.printables.com/model/983180-oh-funny-horse-construction-bricks) for download.

# Compiling
The software uses Godot 4.3 C# to run. The project folder also may need to be set as "F-Deem" to properly compile.

The NuGet package "MemoryPack" will also need to be installed. If you have VSCode just paste this into the terminal.
```dotnet add package MemoryPack --version 1.21.1```

![image](Development/TestSetRender3.png)
