# overlord
Basically a collection of programs that display information on various monitors about things.
Various things include readouts from [tracker](../advanced-peripherals/tracker.lua), or player positons using a Player Detector.
Each module is designed to be separate and not depend on others, though various library modules might be required.
Each module (in `modules` folder) will be loaded and ran in parallel, with a shared environment.