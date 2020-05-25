# Communch 0.1 α

This single-file program processes requests to munge and output data from the
database available here:
https://sql.sh/736-base-donnees-villes-francaises

Which contains various information about all the communes within France and its
overseas territories, last updated in 2014. The database is licensed under the
Creative Commons Attribution-ShareAlike 4.0 International license:
https://creativecommons.org/licenses/by-sa/4.0/

Only the CSV format of this database is supported for now - support for the XML
version will be eventually added. The output is generated in a UTF-8 .csv file.

This project is in alpha state and highly unstable.


## Usage

### Windows
`communch.exe --task name_of_task:param1:param2:param3<...>`

### Linux
`./communch --task name_of_task:param1:param2:param3<...>`

### Task list
- get_in_range : `[all | ...]` : A commune's 5-digit INSEE code, or its degrees coordinates : Scanning range in kilometers


## Roadmap

### 0.1 α
- get_in_range task (no filters yet)

### 0.2 α
- multiple tasks per program run
- filtering with one user-chosen criteria per tasks

### 0.3 α
- usage of any .csv data set instead of only the one bundled with the program
- addition of a .json file to specify the structure of the provided data set
