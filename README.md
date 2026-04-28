# Project Hail Minecraft 🌌

Welcome to the **Project Hail Minecraft** repository! This project transforms the End dimension into Planet Adrian and introduces the Astrophage swarm and Petrova Line into Minecraft using custom shaders and textures.

This repository is a **Monorepo** containing two separate components:
1. `AdrianShaderPack/`: The custom GLSL post-processing shaders (handles the atmosphere, volumetric lighting, redshift, and particles).
2. `RockyResourcePack/`: The companion resource pack (includes custom textures, like the Rocky skin).

## Why We Use Symlinks (Developer Setup)
Because Minecraft reads shaders and resource packs from two completely different folders inside its hidden application data, keeping a Git repository inside those folders can cause sync issues and slow down the game. 

Instead, we clone this repository to a safe, normal folder (like your `Documents`), and create **Symlinks** (symbolic links/shortcuts). This tricks Minecraft into thinking the folders are in the game directory, allowing you to edit code here and see it update live in the game without constantly copy-pasting files!

---

## Prerequisites
Before installing, make sure you have:
* **Minecraft Java Edition** installed and run at least once.
* **Iris Shaders** (or OptiFine) installed for your specific version of Minecraft.
* **Git** installed on your machine.

---

## 🚀 Installation Guide

### Step 1: Clone the Repository
Open your terminal (Mac) or Command Prompt/Git Bash (Windows) and clone this repository to a safe location, such as your `Documents` or `Desktop`.

```bash
git clone [https://github.com/NickCoding22/project-hail-minecraft.git](https://github.com/NickCoding22/project-hail-minecraft.git)
cd project-hail-minecraft
```

*(Note: Keep track of the exact file path where you cloned this, as you will need it for the next steps!)*

### Step 2: Create the Symlinks

Follow the instructions below for your specific operating system. You will need to replace `<PATH_TO_REPO>` with the actual path to where you just cloned the folder.

#### 🍎 For Mac Users
Open your **Terminal** and run the following commands. 

**1. Link the Shader Pack:**
```bash
ln -s "<PATH_TO_REPO>/project-hail-minecraft/AdrianShaderPack" "~/Library/Application Support/minecraft/shaderpacks/AdrianShaderPack"
```
**2. Link the Resource Pack:**
```bash
ln -s "<PATH_TO_REPO>/project-hail-minecraft/RockyResourcePack" "~/Library/Application Support/minecraft/resourcepacks/RockyResourcePack"
```

#### 🪟 For Windows Users
You **must** run your Command Prompt as an **Administrator** to create symbolic links. (Press the Windows key, type `cmd`, right-click "Command Prompt", and select "Run as administrator").

**1. Link the Shader Pack:**
```cmd
mklink /D "%appdata%\.minecraft\shaderpacks\AdrianShaderPack" "<PATH_TO_REPO>\project-hail-minecraft\AdrianShaderPack"
```
**2. Link the Resource Pack:**
```cmd
mklink /D "%appdata%\.minecraft\resourcepacks\RockyResourcePack" "<PATH_TO_REPO>\project-hail-minecraft\RockyResourcePack"
```

---

## 🎮 Activating in Game

Once the symlinks are created, launch Minecraft with your Iris/OptiFine profile.

1. **Activate the Resource Pack:**
   * Go to `Options` > `Resource Packs...`
   * Find **RockyResourcePack** in the left column and click the arrow to move it to the right ("Selected") column. Click Done.
2. **Activate the Shader Pack:**
   * Go to `Options` > `Video Settings...` > `Shader Packs...`
   * Select **AdrianShaderPack** from the list.
   * Click **Shader Options** in the bottom right to open the custom *Project Hail Mary Setup* UI, where you can toggle the atmosphere, the Petrova Line, and adjust the Astrophage density sliders!

> **Developer Tip:** If you are actively editing the `.fsh` or `.glsl` files in VS Code, you do not need to restart the game to see your changes. Just press `F3 + R` while in-game to instantly reload the shaders!
```