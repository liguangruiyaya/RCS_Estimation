RCS Radar Simulator for Matlab
========

**About this project**

This work is part of my bachelor thesis at the [Communications Engineering Lab](http://www.cel.kit.edu/) of the Karlsruhe Institute of Technology.

The goal of this project is to develop a MATLAB simulation for a stepped frequency continuous wave (SFCW) radar to estimate the radar cross section (RCS) of given objects. Swerling models should be taken into account.

**Alpha Version**

The source code is still in development, so most of the functionality is still missing.

**Hints**

To start the simulation, execute `RCS_Estimation` in Matlab. Most parameters can be set in the parameters section of the source code (line `14`).

The following assumptions where taken:

- The distance of the objects is large in relation to the distance it will move during the measurement (R = const.)
- The target is static (for now v = 0)