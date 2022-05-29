# Custom Tractor blade

This repository holds files that patches Tractor's blade Python code files.

The blade Python files are located in:

```
C:\Program Files\Pixar\Tractor-2.4\lib\python2.7\Lib\site-packages\tractor\apps\blade
```

## Scripts

To update the code of the blades we have the following scripts:

### `update_tractor_blade.ps1`

Copies all the patched files in the `blade` folder to the windows location defined above.
Then it restarts the service if any of those files were changed

### `open_blade_port.ps1`

Set the Blade service to auto restart and start it.
Add a firewall rule to open the `9005` port needed to communicate with the Tractor engine.

## Files

### `blade/TractorSiteStatusFilter.py`

> Execute custom code on every log line

- Added the ability to stop the process on errors that didn't return any error code (`!= 0`)

  ```python
  exceptions = [
    "CRASHED in RaiseException",
    "Building Embree Voxel Tree failed",
    "V-Ray: Exception in CORE",
    "Failed batch render",
    "V-Ray encountered fatal error",
    "Error opening these alembic files",
  ]

  # ...

  if any([(exception in textline) for exception in self.exceptions]):
    return (self.TR_LOG_FATAL_CODE, -1234, textline)
  ```

- Added support for Blender progress style

  Use `self.TR_LOG_ALSO_EMIT + self.TR_LOG_PROGRESS` in the flags to emit it

  ```
  Fra:1 Mem:29.11M (Peak 29.39M) | Time:00:52.88 | Remaining:01:23.14 | Mem:7.77M, Peak:7.90M | Scene, View Layer | Rendered 46/128 Tiles
  ```

  ```python
  RE_BLENDER_PROGRESS = re.compile("Rendered ([0-9]+\/[0-9]+) Tiles")

  def extract_blender_progress(line):
      result = RE_BLENDER_PROGRESS.search(line)

      if result:
          ratio = result.group(1)
          rendered, total = ratio.split("/")
          return 100 * float(rendered) / float(total)

      return None
  ```

### `blade/TrBladeMain.py`

> Blade parameters and main function

- Changed progress emit interval to `0.1s` for faster feedback

  ```python
  optparser.add_option("--progresslimit", dest="progresslimit",
    type="float", default=0.1, metavar="SECS",
    help="max frequency of percent-done updates, in seconds")
  ```

### `blade/TrBladeRunner.py`

> Blade main event loop handling processes and kill...

- See who requested a kill on a particular task (storing in an array like command ids to kill):

  ```python
  self.cidsToBeSweptReqBy = []
  # ...

  # Line 1080
  def checkPids(self, now):
    for c in self.activeCmds:
      cmd_tuple = (c.jid, "%d.%d" % (c.cid, c.rev))

      if c.process and cmd_tuple in self.cidsToBeSwept:
        msg = "Received kill from Tractor engine (requested by %s) (spooled by %s) pid=%d" % (reqby, c.logref, c.pid)
        self.logger.info( msg )
        c.SaveOutput( msg )
  ```

### `blade/TrCmdTracker.py`

> Responsible for handling the command itself

### `blade/TrSubprocess.py`

> Handle the command process

- Ability to properly kill a process running in a Rez environment.

  See: https://github.com/AcademySoftwareFoundation/rez/discussions/1250

  On Windows it kills the whole process tree instead of just the Rez process.

  ```python
  # line 581
  def send_signal(self, sig):
    if subprocess.mswindows:
      subprocess.call(['taskkill', '/F', '/T', '/PID', str(self.pid)])
  ```

### `blade/TrSysState.py`

> Responsible for the blade information and system

- Change the resolution order of GPU on Windows

  It executes `wmic path win32_VideoController get name` which returns the following:

  ```
  Name
  NVIDIA GeForce GTX 1060 6GB
  Intel(R) HD Graphics 630
  ```

  Previously it was taking the last GPU on the list

  Now if it takes an `NVIDIA` it has the priority over other cards:

  ```python
  def resolveGPU_Windows(self, argv, exclusions):
    # ...

    n = 0
    id = None
    for x in r.strip().split(b"\n"):
        x = x.strip()
        if x != b"Name":
            n += 1

            if id is None or not b"NVIDIA" in id:
                id = x
  ```
