import dropbox

# Provide your access token here
access_token = "sl.Bt0k-AKuT0bwOfA_SxbZ_zqU9TQDWsZYdEJb_OnL7fma52Gb7cQhySdjHwv0-xAhYlPe6NeGeDcqOafmIPjwIlkX6kFfGFDdyg30E4X5MIlCE9OqYve9uDNxAzdMCqYbXGHxu9bkO3T7"

# Create a Dropbox object and pass the access token
dbx = dropbox.Dropbox(access_token)


def list_files_and_folders(path, indent=""):
    result = dbx.files_list_folder(path)
    for entry in result.entries:
        if isinstance(entry, dropbox.files.FolderMetadata):
            print(indent + "📁 " + entry.name)
            list_files_and_folders(entry.path_display, indent + "    ")
        else:
            print(indent + "📄 " + entry.name)

# Call the function to list files and folders starting from the root
list_files_and_folders("")
