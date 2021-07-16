# snack
`snack` is a submodule for local_manifests-based LineageOS development trees. `snack` automates the process of repopicking and patching dev trees.

## Installation
In a `local_manifests`-based LineageOS dev tree manifest repo (i.e. [Switchroot Android's](https://gitlab.com/switchroot/android/manifest/-/tree/lineage-17.1-icosa_sr)), run 
```
git submodule add https://github.com/makinbacon21/snack.git
```
To update,
```
git submodule sync snack
```

## Folder Structure
```
$ANDROID_BUILD_TOP/.repo/local_manifests/
|- patches
|  |- [name].patch
|  |- ...
|- default.xml [not used by this script]
|- README.md [unnecessary]
|- patchlist
|- picklist
|- snack.sh
```

## List Format
Note that both `patchlist` and `picklist` MUST end with a newline or the last item in the list will not be read

Picks:
```
xxxxxx      # repopick by numeric id
"<topic>"   # repopick by topic string
```
Patches:
```
"<patch name>","path/to/directory"
```

## Usage
Prior to running `lunch_[product]-userdebug', run 
```
.repo/local_manifests/snack/snack.sh -y
```
Args:
```
-y          | Auto accept sync prompt
-n          | Auto reject sync prompt
-h/--help   | Display this message
-c/--check  | Sanity checker
--no-pull   | Do not pull latest manifest
```

## Credits
Pablo Zaidenvoren \<pablo@zaiden.com.ar\> for work on [the original repopic-and-patch script](https://github.com/PabloZaiden/switchroot-android-build/blob/master/build-scripts/repopic-and-patch.sh)

The Great Wizard Azkali \<a.ffcc7@gmail.com\> for help with testing and setup
