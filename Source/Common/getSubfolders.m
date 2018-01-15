function subfolders = getSubfolders(folder)

files = dir(folder);
is_subdirectory = [files.isdir] & ~strcmp({files.name},'.') & ...
    ~strcmp({files.name}, '..');
subfolders = files(is_subdirectory);