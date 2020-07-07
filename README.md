![](https://github.com/senselogic/BIT/blob/master/LOGO/bit.png)

# Bit

Git large file manager.

### Size unit suffixes

```
b : byte
k : kilobyte
m : megabyte
g : gigabyte
```

### File exclusion syntax

```sh
# comment
/PATH/TO/
!/PATH/TO/
/PATH/TO/file_filter
!/PATH/TO/file_filter
PATH/TO/
!PATH/TO/
PATH/TO/file_filter
!PATH/TO/file_filter
file_filter
!file_filter
```

### File filter syntax

```
? : any character
* : any characters
```
## Limitations

* Maximum one asterisk character per file filter.

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html) (using the MinGW setup option on Windows).

Build the executable with the following command line :

```bash
dmd -m64 bit.d
```

## Command line

```bash
bit [options]
```

### Options

```
--split <size> : find non-excluded files larger than `size` in the current folder,
                 split them inside the `.bit/` folder and update the `.gitignore` file
--join : rebuild large files from the fragments stored inside the `.bit/` folder
```

### Examples

```bash
bit --split 50m
```

Finds non-excluded files larger than 50 megabytes in the current folder,
splits them inside the `.bit/` folder and updates the `.gitignore` file.

```bash
bit --join
```

Rebuilds large files from the fragments stored inside the `.bit/` folder.

## Version

1.0

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
