About ECInjection
================

This is an evolution of the ECHelper project.

Like ECHelper, it installs a helper application that is launched by launchd and runs with enhanced priveleges. 

In this project though, the helper's purpose is to inject a code bundle into another application.

The project includes some sample injected code which adds a menu to the application that it is injected into.

The Parts
---------

This sample consists of three targets, and also builds one target from a subproject:

- host: this is the application that provides a user interface for the sample, performs the installation of the helper if necessary, and lets you trigger the injection.
- injector: this is the helper application that gets installed into /Library and launched by launchd.
- injected: this is the code bundle that gets injected into whatever application you choose
- mach_inject_bundle_stub.bundle: this is a small bundle that is part of the mach_star code injection project; the injector application uses it to perform the injection

How It Works
------------

The way the project is set up, the host application provides an interface with a couple of buttons and some text.

Whilst running it tries to use IPC to communicate with the injector helper app and the injected code, and reports back on whether or not they seem to be available.

A button in the UI allows us to install the helper if it's not present. This bit requires root permissions so we get a authentication dialog.

Once the helper is installed and running, we can use it to inject code with the other button in the UI.

The host invokes the inject command in the helper, passing it the bundle to inject and the app to target as parameters. 

This is clearly not very secure, but hey - it's an example. At this point the injector also needs to be able to find the mach_inject_bundle_stub.bundle. In theory this could live anywhere. Ideally we'd put it inside the injector helper so it could never lose track of it, but we can't do that because the injector is a plain vanilla executable and not a bundle. 

So for convenience in the demo, we put the stub bundle inside the injected code bundle - since we're passing that to the injector anyway. In a more real-world scenario where the injector ran autonomously rather than being triggered by something external, we might pass the stub bundle to the injector during the installation phase, and have it copy it somewhere inside /Library so that it can always find it later.