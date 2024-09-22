# Renderme
Lsyncd lua script for remote rendering: the power of this system is that it can pass commands directly in the filename, removing the need for specific systems or configuration on client machines.
Each machine responds to commands when called by its hostname: in the examples, "hostname" means the name of the server machine, e.g. mypowerful, supercomputer, eagle, blah blah.

## Commands
Commands are passed directly in the filename:
If you have a file called 'mysuperjob.blend', you can order the computer 'abracadabra' to render the file by typing the command in the file name, anywhere.
For example
  * mysuperjobabracadabra.start.blend
  * myabracadabra.startsuperjob.blend
  * mysuperabracadabra.startjob.blend
are all valid commands.

The main client commands are:
### hostname.start
start restores the original filename and launches a Blender process.

### hostname.stop
stop restores the original filename and terminates the associated Blender process, giving you the opportunity to stop rendering.

## Prerequisites
  * Lua 5.3 and liblua5.3-dev
  * Lsyncd version 2.3.1. Check using `lsyncd -version`. You need cmake to compile.
  * Blender: can be linked in path ex. `sudo ln -s /home/user/blender-4.2.0-linux-x64/blender /usr/local/bin` or you can setup and alias
  * Some sort of file sync on the selected folder: (lsyncd itself, Syncthing, Dropbox, Google Drive, Microsoft OneDrive, ...)

## Usage
Configure your params
Copy this file in a folder, ex. /etc/lsyncd/
Launch the rendering service ex. `lsyncd /etc/lsyncd/renderme.lua` and `lsyncd /etc/lsyncd/renderstop.lua`
use `lsyncd -nodaemon /etc/lsyncd/renderme.lua` to debug...

&divide;

License: GPLv3 or any later version

Authors: Lsyncd devs and Riccardo Gagliarducci
From the idea in: https://lsyncd.github.io/lsyncd/manual/examples/auto-image-magic/

