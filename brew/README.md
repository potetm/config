Hopefully, all you have to do to get this setup is:
  1. Install [xcode](https://developer.apple.com/xcode/)
  2. Install [xcode command line tools](https://developer.apple.com/downloads/index.action) (search for xcode on the left)
  3. `sudo xcodebuild -license`
  4. Install [`brew`](http://brew.sh/)
  5. Run the following:

```
git clone https://github.com/potetm/tims-brew.git
cd tims-brew
./installer.sh
```

In the event I add or update a config file, simply run

```
./installer.sh
```

to link in the new config files in.  Linked files (e.g. `/etc/profile`) will
update automatically when you update this repository with a `git pull`.

Not sure the force linking is actually a stellar idea, but I'd rather use
the newest versions of those and I never had any problems with (ehm...) MacPorts.

This is by no means exhaustive.  It is thorough enough for me right now.
That is all.  Use at your own risk.
