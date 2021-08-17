# BinaryImagesInspector
At runtime, provides an array of strings representing binary image infos that are then used with the atos command to symbolicate stack traces.

e.g.:
```
atos -arch arm64 -o [YOUR-DSYM-ID].dSYM/Contents/Resources/DWARF/[YOUR APP] -l 0x0000000000000000 0x0000000000000000
```

### Usage:

```
let binaryImages: [String] = BinaryImagesInspector.getBinaryImagesInfo()
print(binaryImages)
```

