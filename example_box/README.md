# Vagrant oVirt4 Example Box

Vagrant providers each require a custom provider-specific box format.
This folder shows the example contents of a box for the `ovirt4` provider.
To turn this into a box:

```
$ tar cvzf dummy.box ./metadata.json ./Vagrantfile
```

This box works by using Vagrant's built-in Vagrantfile merging to setup
defaults for oVirt. These defaults can easily be overwritten by higher-level
Vagrantfiles (such as project root Vagrantfiles).
