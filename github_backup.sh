#!/bin/bash

# Get command line parameters and set them to variables
user=$1
token=$2
userOrOrg=$3
name=$4
backupPath=$5

if [[ $* == "-help" || $* == "-h" || "$#" -ne 5 ]]; then
	echo -e "\n################################################"
	echo -e "There are 5 parameters. Seperate them by a space."
	echo -e "1. Parameter: Your GitHub user name"
	echo -e "2. Parameter: Your GitHub access token"
	echo -e "3. Parameter: \"org\" for organizational GitHub account, \"user\" for personal GitHub account"
	echo -e "4. Parameter: Name of personal user account or organizational account"
	echo -e "5. Parameter: Where to store the backup locally"
	echo -e "##################################################\n"
	exit 0
fi


# Check if we use an organization or a user and create the appropriate API Url
if [[ $userOrOrg == "user" ]]; then
	baseUrl="https://api.github.com/users/$name"
elif [[ $userOrOrg == "org" ]]; then
	baseUrl="https://api.github.com/orgs/$name"
fi

# Create Url to "repos" API
reposUrl="$baseUrl/repos"

# Get the clone Urls from the JSON API response using awk and egrep as an Array
cloneUrls=($(curl --silent -u $user:$token $reposUrl | awk '/clone_url/ {print $0}' | egrep -o "(http.*\.git)"))

# Iterate over the Array with the clone Urls
for cloneUrl in "${cloneUrls[@]}"
do
	# Get name of GitHub repository
	repoName=$(basename "$cloneUrl")
	
	# Make a temporary directory to which we will clone the repository
	tempDir=$(mktemp -d)

	# Clone the repository silently
	git clone --quiet $cloneUrl "$tempDir/$repoName"

	# Remove old repository directory in backup directory
	rm -r -f "$backupPath/$repoName"

	# Move freshly cloned repository to backup directory
	mv -f "$tempDir/$repoName" $backupPath

	# Remove the temporary directory
	rm -r -f $tempDir
done
