# Tetris
Simple Tetris game written using assembly! It ruined my holiday but I still like it.

## Gameplay
<!--- TODO -->

## Installation Guide
1. Compile `HW3.asm`. You can use emu8086 for compiling.
2. Install [DOSBox](https://www.dosbox.com/download.php?main=1) to run program on real CPU (not emulator).
3. Mount directory containing `HW3.exe`.
    ```
    mount D YOUR\SPECIFIC\DIRECTORY
    ```
    Change drive
    ```
    D:
    ```
4. Enjoy Tetris 😄
    ```
    HW3.EXE
    ```
5. (OPTIONAL STEP) To get to your games faster (like Tetris), you can edit the options.bat file at (default) `C:\Program Files (x86)\DOSBox-0.74` 
Anything added to the bottom row will automatically execute every time DOSBox is started. Type the commands you would normally type here to access your games faster. For example, if your game folder is `C:\dos`, then
    ```
    mount c c:\dos
    c:
    dir
    ```
    The above lines will automagically mount your dos folder as C:\ and take you directly into the folder. Then it will show you your list of directories so you can just cd one and play your game!