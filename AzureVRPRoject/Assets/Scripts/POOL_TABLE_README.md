# Pool Table Setup Instructions

## Overview
I've created a complete VR pool table system for your Unity project with the following components:

## Scripts Created
1. **PoolTable.cs** - Main pool table controller
2. **PoolBall.cs** - Individual ball physics and behavior
3. **PoolPocket.cs** - Pocket collision and game logic
4. **PoolCushion.cs** - Realistic cushion physics
5. **PoolCueStick.cs** - VR cue stick with aiming and shooting
6. **PoolTableSetup.cs** - Helper script for easy setup

## Setup Instructions

### Method 1: Automatic Setup
1. Create an empty GameObject in your scene
2. Add the `PoolTableSetup` component to it
3. The pool table will be created automatically when you play the scene
4. Or right-click on the component and select "Create Pool Table"

### Method 2: Manual Setup
1. Create an empty GameObject and name it "PoolTable"
2. Add the `PoolTable` component to it
3. Position it where you want the table in your VR environment
4. The table will build itself with all components when the scene starts

## Features

### VR Integration
- Uses XR Interaction Toolkit for VR interactions
- Balls can be grabbed and moved by hand
- Cue stick has realistic aiming with visual line renderer
- Haptic feedback for powerful shots (if controller supports it)

### Realistic Physics
- Proper ball physics with mass, friction, and bounce
- Cushion physics with energy loss and realistic bounces
- Ball-to-ball collisions with sound effects
- Rolling friction and momentum conservation

### Game Logic
- Standard 8-ball pool setup (15 object balls + cue ball)
- 6 pockets (4 corner, 2 side)
- Ball pocketing detection and handling
- Scratch (cue ball in pocket) handling with respawn
- Automatic ball rack reset

### Audio System
- Ball collision sounds
- Cushion impact sounds
- Ball rolling sounds (velocity-based volume)
- Pocket sounds when balls are sunk

### Visual Features
- Realistic table materials (green felt, wood rails)
- Standard pool ball colors (stripes and solids)
- Aiming line that changes color based on shot power
- Chalk dust effect when shooting

## Customization Options

### Table Dimensions (in PoolTable.cs)
- `tableWidth` - Default: 2.54m (9-foot table)
- `tableLength` - Default: 1.27m (9-foot table)  
- `tableHeight` - Default: 0.8m
- `ballRadius` - Default: 0.028575m (regulation size)

### Physics Materials
You can assign custom PhysicMaterials in the inspector:
- `ballPhysicsMaterial` - For ball bouncing and friction
- `tablePhysicsMaterial` - For table surface
- `cushionPhysicsMaterial` - For rail cushions

### Audio Clips
Assign audio clips in the inspector:
- `ballHitSound` - Ball collision sound
- `pocketSound` - Ball sinking sound  
- `rollSound` - Ball rolling sound (in PoolBall.cs)
- `cueHitSound` - Cue stick impact sound
- `cushionHitSound` - Cushion bounce sound

## Usage Instructions

### Playing Pool in VR
1. **Grab the Cue Stick**: Use your VR controllers to grab the cue stick
2. **Aim**: Point the cue at the cue ball (white ball)
   - A white aiming line will appear showing trajectory
   - Line turns red as you pull back for more power
3. **Shoot**: Pull the cue back and push forward to shoot
   - More pullback = more power
   - Release the cue stick trigger to shoot
4. **Manual Ball Control**: You can grab and move balls by hand if needed
5. **Reset**: The table will auto-reset when the 8-ball is pocketed

### Cue Stick Controls
- **Grab**: Trigger button to grab cue stick
- **Aim**: Point cue tip near cue ball to activate aiming
- **Power**: Pull cue stick back to build power (red line = max power)
- **Shoot**: Push forward while holding trigger, then release

### Game Rules (Implemented)
- Cue ball scratch: Ball respawns behind head string
- 8-ball pocketed: Game resets automatically
- Object balls: Disappear when pocketed (or move to side rail)
- Physics: Realistic ball interactions and cushion bounces

## Troubleshooting

### If balls aren't moving correctly:
- Check that Rigidbody components are properly configured
- Ensure Physics Materials are assigned
- Verify table is at Y=0 or adjust ball spawn height

### If VR interactions aren't working:
- Make sure XR Interaction Toolkit is installed and configured
- Verify XR Rig is set up correctly in your scene
- Check that controllers have XR Ray Interactor components

### If sounds aren't playing:
- Assign AudioClip files to the respective sound fields
- Check that AudioSource components are enabled
- Verify audio volume levels in the scripts

## Performance Tips
- Balls automatically stop moving when velocity drops below threshold
- Use LOD (Level of Detail) for ball textures if needed
- Consider object pooling for ball trails or particle effects
- Limit physics update rate if running on lower-end VR headsets

## Extension Ideas
- Add score tracking and UI
- Implement different game modes (9-ball, straight pool)
- Add ball trails or glow effects
- Create tournament bracket system
- Add spectator camera views
- Implement online multiplayer

The pool table is now ready to use in your VR environment! Just add the PoolTableSetup script to an empty GameObject and you're ready to play pool in VR.
