# Adobe CEP Extension Symlink Manager

A command-line tool to manage symbolic links between Adobe CEP extensions in a custom directory and the standard Adobe CEP extensions directory.

![Adobe CEP Extensions](https://img.shields.io/badge/Adobe-CEP%20Extensions-blue)
![Windows](https://img.shields.io/badge/OS-Windows-blue)

## 🚀 Features

- Create symbolic links for all folders in a custom directory to the Adobe CEP extensions directory
- Remove symbolic links for specific folders
- Check the status of links and extensions
- Full path information display for all directories
- Administrator rights verification
- Safe handling of existing files and directories

## ⚙️ Requirements

- Windows operating system
- Administrator rights (required for creating symbolic links)
- Adobe Creative Cloud applications installed

## 📋 Setup

1. Download the `adobe-cep-extension-symlink-manager.cmd` file
2. **Important**: Edit the script to set your custom paths:
   - Open the file in a text editor
   - Find and modify these lines at the beginning of the script:
     ```batch
     :: Define directories
     set "ADOBE_DIR=%APPDATA%\Adobe\CEP\extensions"
     set "CUSTOM_DIR=C:\path\to\your\custom\extensions"
     ```
   - Replace `C:\path\to\your\custom\extensions` with your desired custom extensions directory path

## 🔧 Usage

1. Right-click on the script file and select "Run as administrator" (important!)
2. Choose from the menu options:
   - **Create links for each folder**: Creates symbolic links in the Adobe directory for each folder in your custom directory
   - **Check status**: Displays information about all directories and symbolic links
   - **Remove links to custom folders**: Safely removes symbolic links while preserving actual content
   - **Exit**: Closes the application

## 📝 Why Use This Tool?

This tool is particularly useful for developers who:
- Want to store their Adobe CEP extensions in a custom location (e.g., on a different drive)
- Need to manage multiple extensions across different projects
- Want to backup their extensions outside the standard Adobe directory
- Need to quickly enable/disable specific extensions

## ⚠️ Important Notes

- The script requires administrator privileges to create symbolic links
- The Adobe CEP extensions directory is typically located at `%APPDATA%\Adobe\CEP\extensions`
- Removing links does not delete the actual content in your custom directory
- Always ensure Adobe applications are closed before making changes

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/yourusername/adobe-cep-extension-symlink-manager/issues).

## 📄 License

This project is [MIT](LICENSE) licensed.

## 🙏 Acknowledgments

- Adobe CEP documentation
- Windows command-line symbolic link capabilities 