# BinaryImagesInspector
At runtime, provides an array of strings representing binary image infos that are then used with the atos command to symbolicate stack traces.

e.g.:
```
atos -arch arm64 -o [YOUR-DSYM-ID].dSYM/Contents/Resources/DWARF/[YOUR APP] -l 0x0000000000000000 0x0000000000000000
```

### Usage:

```
BinaryImagesInspector.getBinaryImagesInfo()
```

Example:
```
import BinaryImagesInspector
import os.log

let binInfos = BinaryImagesInspector.getBinaryImagesInfo()
let logStr = binInfos.joined(separator: "\n")
os_log("%{public}@", logStr)
```

### Output:
Example on iOS:
```
YourApp 0x00000001adb1e000 - arm64e - E9B05479-3D07-390C-BD36-73EEDB2B1F75
CoreGraphics 0x00000001a92dd000 - arm64e - 2F7F6EE8-635C-332A-BAC3-EFDA4894C7E2
CoreImage 0x00000001afc00000 - arm64e - CF56BCB1-9EE3-392D-8922-C8894C9F94C7


