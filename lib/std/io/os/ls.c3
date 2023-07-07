module std::io::file::os @if(env::POSIX);

fn PathList! native_ls(Path dir, bool no_dirs, bool no_symlinks, String mask, Allocator* using)
{
	PathList list;
	list.init(.using = using);
	DIRPtr directory = posix::opendir(dir.as_str() ? dir.as_zstr() : (ZString)".");
	defer if (directory) posix::closedir(directory);
	if (!directory) return (path::is_dir(dir) ? IoError.CANNOT_READ_DIR : IoError.FILE_NOT_DIR)?;
	Posix_dirent* entry;
	while ((entry = posix::readdir(directory)))
	{
		String name = ((ZString)&entry.name).as_str();
		if (!name || name == "." || name == "..") continue;
		if (entry.d_type == posix::DT_LNK && no_symlinks) continue;
		if (entry.d_type == posix::DT_DIR && no_dirs) continue;
		Path path = path::new(name.copy(using), using)!!;
		list.append(path);
	}
	return list;
}

module std::io::os @if(env::WIN32);

fn PathList! native_ls(Path dir, bool no_dirs, bool no_symlinks, String mask, Allocator* using)
{
	PathList list;
	list.init(.using = using);
    @stack_mem(1024; Allocator* mem)
    {
	    Char16* result = dir.as_str().concat(`\*`).to_utf16(.using = mem)!!;
	    Win32_WIN32_FIND_DATAW find_data;
        Win32_HANDLE find = win32::findFirstFileW(result, &find_data);
        if (find == win32::INVALID_HANDLE_VALUE) return IoError.CANNOT_READ_DIR?;
        defer win32::findClose(find);
        do
        {
            if (no_dirs && (find_data.dwFileAttributes & win32::FILE_ATTRIBUTE_DIRECTORY)) continue;
            @stack_mem(480; Allocator* mem2)
            {
				String filename = string::from_zutf16(&find_data.cFileName, mem2)!;
                if (filename == ".." || filename == ".") continue;
	            list.append(path::new(filename, using));
            };
        } while (win32::findNextFileW(find, &find_data));
        return list;
    };
}