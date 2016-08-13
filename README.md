### Combine Etc/Hosts

Manage separate host files, then combine them as one to update */etc/hosts*.

----

Usage: ```sudo ./combine.sh {option}```

**Options:**

> -a -- Add all files from directory path 'lists' *(default option)*
> 
> -p {path} -- Search a different directory path. *(default: lists)*
> 
> -m {pattern} -- Search for files matching a given pattern.
> 
> -f {filename} -- Add specific file only.
> 
> -r, -l -- Reset to standard 'lists/localhost' listing only.
> 
> -h -- This message : )

----

**Lists:**

All list files should go in the default the directory '**lists**', but you can always adjust the path by using the flag '**-p**' for pattern-matching a directory or filenames.

**First-Time Running:**

By default, when the script is first executed, it will create a backup of the system's */etc/hosts* as "**hosts.backup**", and also copy the contents to a newly created list file "**localhost**" in the *lists* directory *(if not exists)*.

**Running as Sudo**

Due to root permissions set on */etc/hosts*, it is required to run the script with sudo so that the file can be updated with the new list content.

#### Preview

[![asciicast](https://asciinema.org/a/82661.png?v=2)](https://asciinema.org/a/82661)
