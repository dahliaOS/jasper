# Mod - A scaffolding tool for Fuchsia mods

Mod is a tool for creating a new Fuchsia mod project scaffold. To use it, first
include the tools/bin directory to your path.

    export PATH=${FUCHSIA_DIR}/topaz/tools/bin:${PATH}

To create a new mod project under the current directory:

    mod create <your_project_name>

This will create a new mod project with the given name in the current directory.
Note that it doesn't automatically add the project into the GN build tree (yet).
You should manually add a new package definition somewhere in your `BUILD.gn`
files order to see the new mod on the target device.

Run `mod help` for more information about the detailed tool usage.
