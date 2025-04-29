#!/bin/bash

# Script to set up the ticketstatus repository and required tools
#
echo "This script will help you set up the ticketstatus repository and required tools on mac."
echo "If not already installed, it will install Homebrew, bash, jq, fzf, and gh (GitHub CLI)."
read -p "Do you want to continue? (y/n): " continue_choice
if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
    echo "Aborting setup. No changes have been made."
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew if not installed
if ! command_exists brew; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Homebrew installed. Please restart the terminal if you encounter any issues."
fi

# Install required tools
for tool in bash jq fzf gh; do
    echo "Installing $tool via Homebrew..."
    brew install $tool
done

# Check if the GitHub email is set
github_email=$(git config user.email)
if [ -z "$github_email" ]; then
    echo "[Error] No GitHub email found in Git configuration. Please set it using the following command:"
    echo "git config --global user.email \"your_email@example.com\""
    exit 1
else
    echo "[Success] GitHub email is set to: $github_email"
fi

# Ask the user for the clone destination
echo "Where would you like to clone the repository? (Leave blank to use the current directory)"
read -p "Destination path: " destination_path

# Default to current directory if no path is provided
if [ -z "$destination_path" ]; then
    destination_path="$(pwd)"
fi

# Confirm the destination path with the user
echo "You have chosen to clone the repository to: $destination_path"
read -p "Is this correct? (y/n): " confirm_choice
if [[ "$confirm_choice" != "y" && "$confirm_choice" != "Y" ]]; then
    echo "Aborting clone operation. Please run the script again to specify a new path."
    exit 1
fi

# Clone the specific GitHub repository
echo "Cloning repository github.com:vvhg1/ticketstatus.git to $destination_path..."
read -p "Do you want to clone the repository using SSH? (y/n): " ssh_choice
if [[ "$ssh_choice" == "y" || "$ssh_choice" == "Y" ]]; then
    git clone git@github.com:vvhg1/ticketstatus.git "$destination_path/ticketstatus"
    if [ $? -eq 0 ]; then
        echo "Repository cloned successfully to $destination_path/ticketstatus."
    else
        echo "Failed to clone the repository. Please check your SSH configuration and access rights."
        exit 1
    fi
elif [[ "$ssh_choice" == "n" || "$ssh_choice" == "N" ]]; then
    git clone https://github.com/vvhg1/ticketstatus.git "$destination_path/ticketstatus"
    if [ $? -eq 0 ]; then
        echo "Repository cloned successfully to $destination_path/ticketstatus."
    else
        echo "Failed to clone the repository. Please check your HTTPS configuration and access rights."
        exit 1
    fi
else
    echo "Invalid choice. Please try again."
    exit 1
fi

# Ask the user if he wants an alias to execute the script
echo "It is recommended to create an alias for the ticketstatus script."
read -p "Do you want to add an alias to your .zshrc or .zsh_aliases? (y/n): " alias_choice
if [[ "$alias_choice" == "y" || "$alias_choice" == "Y" ]]; then
    # check if we are apple silicon or intel
    if [ "$(uname -m)" == "arm64" ]; then
        # Apple Silicon
        bash_path="/opt/homebrew/bin/bash"
    else
        # Intel
        bash_path="/usr/local/bin/bash"
    fi
    # check if the .zsh_aliases file exists
    if [ -f ~/.zsh_aliases ]; then
        echo "Creating alias "tik" in .zsh_aliases..."
        echo "alias tik=\"$bash_path -c 'export JIRA_API_TOKEN=\$JIRA_API_TOKEN; source $destination_path/ticketstatus/ticketcrossroad.sh; ticketcrossroad'\"" >>~/.zsh_aliases
    elif [ -f ~/.zshrc ]; then
        echo "Creating alias "tik" in .zshrc..."
        echo "alias tik=\"$bash_path -c 'export JIRA_API_TOKEN=\$JIRA_API_TOKEN; source $destination_path/ticketstatus/ticketcrossroad.sh; ticketcrossroad'\"" >>~/.zshrc
    else
        echo "No .zshrc or .zsh_aliases file found. Creating .zshrc..."
        touch ~/.zshrc
        echo "Creating alias "tik" in .zshrc..."
        echo "alias tik=\"$bash_path -c 'export JIRA_API_TOKEN=\$JIRA_API_TOKEN; source $destination_path/ticketstatus/ticketcrossroad.sh; ticketcrossroad'\"" >>~/.zshrc
    fi
    echo "Alias created. You can now run the script using 'tik'."
fi

# Instructions for creating a GitHub personal access token
cat <<EOF

[GitHub Personal Access Token Setup]
To authenticate GitHub CLI (gh) with a personal access token:
1. Visit https://github.com/settings/tokens to create a new token.
2. Choose 'Tokens(classic)' and click 'Generate new token'.
3. Select the necessary scopes: 'admin:public_key', 'notifications', 'project', 'read:enterprise', 'read:org', 'repo', 'user', 'write:discussion'.
4. Click 'Generate Token' and copy the token.
5. Store the token securely (e.g., use a password manager).

To log in with the token using gh:
   gh auth login --with-token < <(echo YOUR_PERSONAL_ACCESS_TOKEN)

EOF

# Instructions for creating a Jira API token
cat <<EOF

[Jira API Token Setup]
To authenticate with Jira's API:
1. Visit https://id.atlassian.com/manage-profile/security/api-tokens.
2. Click 'Create API Token'.
3. Give the token a label, then click 'Create'.
4. Copy the token and store it securely (e.g., use a password manager).

This script expects this token in the JIRA_API_TOKEN environment variable, if it is not set, it can be fetched from pass (https://formulae.brew.sh/formula/pass) under the name 'jiraapi'.

For zsh users, it is more convenient to use an environment variable. As ticketstatus is executed in a subshell, pass would ALWAYS ask for the password. The environment variable, if set, is automatically forwarded to the subshell by the alias this script creates. If you chose to add the alias, you need to forward it yourself.


EOF

echo "[Setup Complete] All required tools have been installed, and setup instructions have been provided. You can now use the ticketstatus script."
