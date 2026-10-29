#!/bin/zsh
# set -x

##################################### VARIABLES ##########################################

vers="4.00b3"
myPID=$$
myProcName=$( /usr/bin/basename ${0} )
myUser=$( /bin/echo $( /usr/bin/dscl . read /Users/$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }') RealName ) | /usr/bin/awk -F ': ' '{print $2}' )
myUserShortName=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
myHome=$( /usr/bin/dscl . read Users/${myUserShortName} NFSHomeDirectory | /usr/bin/awk '{print $2}' )
myID=$( /usr/bin/id -u ${myUserShortName} )
myLog="${myHome}/Library/Logs/.$(/usr/bin/basename ${myProcName} | /usr/bin/cut -d "." -f 1 ).log" 
myTimeStamp()
{
	/bin/date | /usr/bin/awk  '{ printf "%02s %02s %02s %02s\n", $1,$2,$3,$4 }'
}
myHost=$( /usr/sbin/scutil --get ComputerName )
commandFile="${myHome}/Library/LoginTutorial.log"

##################################### FUNCTIONS ##########################################

function CHECK_FOR_LOGIN()
{
		# Need to wait for the Finder to be up and running before this can go forward...
	IS_LOGGEDIN=$( /usr/bin/pgrep dock )
	while [ -z ${IS_LOGGEDIN} ]; do
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: ${0}: Waiting on Login..." | /usr/bin/tee -a "${myLog}"
		sleep 0.1
		IS_LOGGEDIN=$( /usr/bin/pgrep dock )
	done
	/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: ${0}: User is Logged in. Continuing..." | /usr/bin/tee -a "${myLog}"
}
function CHECK_FOR_RUN()
{
	if [[ -e "${myHome}/Library/.firstLogin" || -e "${myHome}/Library/firstLogin" ]]; then
		/usr/bin/defaults write edu.stonybrook.LoginTutorial FirstLoginComplete -int 1
		/bin/rm -Rf "${myHome}/Library/.firstLogin" "${myHome}/Library/firstLogin" 2>/dev/null
	fi
	
	LoginTutorialHasRun=$( /usr/bin/defaults read edu.stonybrook.LoginTutorial FirstLoginComplete 2>/dev/null )
	if [[ -z ${LoginTutorialHasRun} || ${LoginTutorialHasRun} -eq 0 ]]; then
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: ${0}: LoginTutorial has not run. Continuing..." | /usr/bin/tee -a "${myLog}"
	else
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: ${0}: LoginTutorial has already run. Exiting..." | /usr/bin/tee -a "${myLog}"
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Ending: ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"
		/bin/echo "" | /usr/bin/tee -a "${myLog}"
		exit 0
	fi
}
function DOCK()
{
	if [[ -e "${myHome}/Library/.dockutil" || -e "${myHome}/Library/dockutil" ]]; then
		/usr/bin/defaults write edu.stonybrook.LoginTutorial FirstLoginDockComplete -int 1
		/bin/rm -Rf "${myHome}/Library/.dockutil" "${myHome}/Library/dockutil" 2>/dev/null
	fi
	
	dockutilHasRun=$( /usr/bin/defaults read edu.stonybrook.LoginTutorial FirstLoginDockComplete 2>/dev/null )
	if [[ -z ${dockutilHasRun} || ${dockutilHasRun} -eq 0 ]]; then
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: ${0}: Dock has not been setup yet. Setting now..." | /usr/bin/tee -a "${myLog}"
		/usr/local/bin/SET_DOCK.zsh 2>/dev/null 
		/usr/bin/defaults write edu.stonybrook.LoginTutorial FirstLoginDockComplete -int 1
	else
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Dock has already been setup." | /usr/bin/tee -a "${myLog}"
	fi
}
function WALLPAPER()
{
	if [[ -e "${myHome}/Library/.desktoppr" || -e "${myHome}/Library/desktoppr" ]]; then
		/usr/bin/defaults write edu.stonybrook.LoginTutorial FirstLoginWallpaperComplete -int 1
		/bin/rm -Rf "${myHome}/Library/.desktoppr" "${myHome}/Library/desktoppr" 2>/dev/null
	fi
	
	desktopprHasRun=$( /usr/bin/defaults read edu.stonybrook.LoginTutorial FirstLoginWallpaperComplete 2>/dev/null )
	if [[ -z ${desktopprHasRun} || ${desktopprHasRun} -eq 0 ]]; then
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: ${0}: Wallpaper has not been setup yet. Setting now..." | /usr/bin/tee -a "${myLog}"
		/usr/local/bin/SET_WALLPAPER.zsh 2>/dev/null 
		/usr/bin/defaults write edu.stonybrook.LoginTutorial FirstLoginWallpaperComplete -int 1
	else
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Wallpaper has already been setup." | /usr/bin/tee -a "${myLog}"
	fi
}
function MAIN_DIALOG()
{
	SkippedUsers=()
	if [ ! -e "/Library/Managed Preferences/edu.stonybrook.doit.logintutorialskipusers.plist" ]; then
		SkippedUsers+=( desktopsupport )
	else
		myPlist="/Library/Managed Preferences/edu.stonybrook.doit.logintutorialskipusers.plist"
		unset i
		unset count
		local count=$( /usr/bin/plutil -extract "skipUsers" raw -o - "${myPlist}" )
		(( count-- ))
		for ((i=0; i<=${count}; i++)); do
			local URL="$( /usr/bin/plutil -extract "skipUsers.${i}" raw -o - "${myPlist}" )"
			SkippedUsers+=($( /usr/bin/plutil -extract "skipUsers.${i}" raw -o - "${myPlist}" ))
		done
	fi
	if (( ${SkippedUsers[(Ie)${myUserShortName}]} )); then
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: MAIN_DIALOG: Setting the dock for ${myUserShortName}." | /usr/bin/tee -a "${myLog}"
		DOCK
		sleep 3
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: MAIN_DIALOG: Setting the wallpaper for ${myUserShortName}." | /usr/bin/tee -a "${myLog}"
		WALLPAPER
		sleep 3
		if [ "${myUserShortName}" = "desktopsupport" ]; then
			FINAL_SYSTEM_CHECK=$( /usr/bin/defaults read "/Library/Preferences/edu.stonybrook.doit.finalcomputercheck.plist" hasRun 2>/dev/null )
			if [[ -z ${FINAL_SYSTEM_CHECK} || ${FINAL_SYSTEM_CHECK} -ne 1 ]]; then
				/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: MAIN_DIALOG: Final Systems Check has not run. Running it now..." | /usr/bin/tee -a "${myLog}"
				# /usr/bin/open "jamfselfservice://content?entity=policy&id=1849&action=execute"
				/usr/bin/open "/usr/local/bin/Admin Tools Hub.app"
			fi
		fi
	else
		SD_bannerImage="https://drive.usercontent.google.com/download?id=1kS3AV8BtrLIsqhd2b4EHAvxq16rRlabv"
		SD_icon="/usr/local/bin/sbicon.png"
		
		/usr/local/bin/dialog \
		--commandfile "${commandFile}" \
		--width 55% \
		--height 85% \
		--ontop \
		--blurscreen \
		--position centre \
		--bannerimage "${SD_bannerImage}" \
		--icon "${SD_icon}" \
		--iconsize 200 \
		--messagefont "name=Bitter,size=20" \
		--button1text "Continue" \
		--button1disabled \
		--infobox "### System Information\n\n- {computername}\n- {computermodel}\n- {osname}\n- {osversion}\n\n- {userfullname}" \
		--message "## Hello and Welcome ${myUser}\n\n" \
		--quitkey p \
		--helpmessage "For help with your computer, please contact **Customer Engagement** https://service.stonybrook.edu." \
		&
		DialogPID=$!
		sleep 2
		
		##################### BLOCK 1
		/bin/echo "message: ## Hello and Welcome ${myUser}"  >> "${commandFile}"
		sleep 2
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Your desktop is now being set up. This is a one-time process that may take a few moments.<br><br>In the meantime, please keep the following in mind:"  >> "${commandFile}"
		sleep 7
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Your desktop is now being set up. This is a one-time process that may take a few moments.<br><br>In the meantime, please keep the following in mind:<br><br>- This is a University-owned computer; as such, it is being managed by DoIT."  >> "${commandFile}"
		sleep 4
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Your desktop is now being set up. This is a one-time process that may take a few moments.<br><br>In the meantime, please keep the following in mind:<br><br>- This is a University-owned computer; as such, it is being managed by DoIT.<br><br>- For questions or concerns, reach out at https://help.stonybrook.edu or (631) 632-9800."  >> "${commandFile}"
		sleep 4
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Your desktop is now being set up. This is a one-time process that may take a few moments.<br><br>In the meantime, please keep the following in mind:<br><br>- This is a University-owned computer; as such, it is being managed by DoIT.<br><br>- For questions or concerns, reach out at https://help.stonybrook.edu/ or (631) 632-9800.<br><br>- By logging in and using this computer, you agree to abide by the policies set forth by Stony Brook University."  >> "${commandFile}"
		sleep 6
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Your desktop is now being set up. This is a one-time process that may take a few moments.<br><br>In the meantime, please keep the following in mind:<br><br>- This is a University-owned computer; as such, it is being managed by DoIT.<br><br>- For questions or concerns, reach out at https://help.stonybrook.edu/ or (631) 632-9800.<br><br>- By logging in and using this computer, you agree to abide by the policies set forth by Stony Brook University.<br><br>- In order to familiarize yourself with these policies, please open the link provided in your Dock."  >> "${commandFile}"
		sleep 10
		
		##################### SETUP THE DOCK
		DOCK
		
		##################### BLOCK 2
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>For security reasons, your computer will be patched on an ongoing basis. Non-open applications will be patched silently in the background. Open applications will require an application restart."  >> "${commandFile}"
		sleep 7
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>For security reasons, your computer will be patched on an ongoing basis. Non-open applications will be patched silently in the background. Open applications will require an application restart.<br><br>Before the application restarts, a pop-up notification will remind you of the upcoming patch deadline."  >> "${commandFile}"
		sleep 4
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>For security reasons, your computer will be patched on an ongoing basis. Non-open applications will be patched silently in the background. Open applications will require an application restart.<br><br>Before the application restarts, a pop-up notification will remind you of the upcoming patch deadline.<br><br>When an update to macOS is available, you will be prompted to install it in **System Settings**."  >> "${commandFile}"
		sleep 4.5
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>For security reasons, your computer will be patched on an ongoing basis. Non-open applications will be patched silently in the background. Open applications will require an application restart.<br><br>Before the application restarts, a pop-up notification will remind you of the upcoming patch deadline.<br><br>When an update to macOS is available, you will be prompted to install it in **System Settings**.<br><br>You will be able to snooze the macOS update process so it can be applied at a more convenient time."  >> "${commandFile}"
		sleep 10
		##################### CHANGE HOME DIR PERMISSIONS AND INSTALL LAUNCH AGENTS
		
		myResult=$( /bin/chmod -v -v 700 "${myHome}" )
		if [ ! -z ${myResult} ]; then
			/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: ${myResult}" | /usr/bin/tee -a "${myLog}"
		fi
		
		##################### BLOCK 3
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Consider saving your files to **Google Drive** so they are accessible from any device and safe if this computer breaks, is lost, or is stolen."  >> "${commandFile}"
		sleep 7.3
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Consider saving your files to **Google Drive** so they are accessible from any device and safe if this computer breaks, is lost, or is stolen.<br><br>The Google Drive application is installed and set to start at login to make the process easier."  >> "${commandFile}"
		sleep 4.3
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Consider saving your files to **Google Drive** so they are accessible from any device and safe if this computer breaks, is lost, or is stolen.<br><br>The Google Drive application is installed and set to start at login to make the process easier.<br><br>Additionally, you may use **Microsoft OneDrive**, which is installed and set to start automatically at login."  >> "${commandFile}"
		sleep 4.3
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Consider saving your files to **Google Drive** so they are accessible from any device and safe if this computer breaks, is lost, or is stolen.<br><br>The Google Drive application is installed and set to start at login to make the process easier.<br><br>Additionally, you may use **Microsoft OneDrive**, which is installed and set to start automatically at login.<br><br>To log into Microsoft OneDrive, use your **Stony Brook University Email** / **Password**."  >> "${commandFile}"
		sleep 10
		
		##################### SETUP THE WALLPAPER
		WALLPAPER
		
		##################### BLOCK 4
		
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Your computer is equipped with a program called **Self Service+**; it’s in the Applications folder and in your Dock. In Self Service+, you will find optional applications that can be installed with one click."  >> "${commandFile}"
		sleep 8.8
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Your computer is equipped with a program called **Self Service+**; it’s in the Applications folder and in your Dock. In Self Service+, you will find optional applications that can be installed with one click.<br><br>Should you need an application not in Self Service+, reach out at https://help.stonybrook.edu or (631) 632-9800."  >> "${commandFile}"
		sleep 6
		/bin/echo "message: ## Hello and Welcome ${myUser}<br>Your computer is equipped with a program called **Self Service+**; it’s in the Applications folder and in your Dock. In Self Service+, you will find optional applications that can be installed with one click.<br><br>Should you need an application not in Self Service+, reach out at https://help.stonybrook.edu or (631) 632-9800.<br><br>Bookmarks and other utilities are also located in Self Service+. Please take a minute to learn more about this application."  >> "${commandFile}"
		sleep 5
		
			# Enable the button to exit
		/bin/echo "button1: enable" >> "${commandFile}"
		
		while kill -0 ${DialogPID} 2>/dev/null; do
			/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Dialog PID: ${DialogPID}. Waiting for user to exit." | /usr/bin/tee -a "${myLog}"
			sleep 0.5
		done
				
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: ${myUser} (${myUserShortName}) clicked continue." | /usr/bin/tee -a "${myLog}"
			# Get rid of the temp dialog files.
		myResult=$( /bin/rm -Rfv "${commandFile}" )
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Removing ${myResult}" | /usr/bin/tee -a "${myLog}"
		/usr/bin/open "/Applications/Self Service+.app"
	fi
}

##################################### MAIN ##########################################

	# If the argument -d / --dock is passed then the script will reset the dock.
	# If the argument -w / --wallpaper is passed then the script will reset the wallpaper
	# If the argument -t / --tutorial is passed then the script will run the tutorial without setting up the Dock or the wallpaper.
	# If the argument -v / --version is passed then it will only output the version of this script to the command line.
if [[ "$#" -eq 1 ]]; then
	case $1 in
		-d|--dock)
		/bin/echo "" | /usr/bin/tee -a "${myLog}"
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Starting ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Resetting the Dock." | /usr/bin/tee -a "${myLog}"
		/usr/local/bin/SET_DOCK.zsh 2>/dev/null 
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Ending: ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"
		/bin/echo "" | /usr/bin/tee -a "${myLog}"
		exit 0
		;;
		-w|--wallpaper)
		/bin/echo "" | /usr/bin/tee -a "${myLog}"
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Starting ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Resetting the Wallpaper." | /usr/bin/tee -a "${myLog}"
		/usr/local/bin/SET_WALLPAPER.zsh 2>/dev/null
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Ending: ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"
		/bin/echo "" | /usr/bin/tee -a "${myLog}"
		exit 0
		;;
		-t|--tutorial)
		/bin/echo "" | /usr/bin/tee -a "${myLog}"
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Starting ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Running the Login Tutorial without setting the Dock or wallpaper." | /usr/bin/tee -a "${myLog}"
		MAIN_DIALOG
		/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Ending: ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"
		/bin/echo "" | /usr/bin/tee -a "${myLog}"
		exit 0
		;;
		-v|--version)
		/bin/echo "${vers}"
		exit 0
	esac
fi

/bin/echo "" | /usr/bin/tee -a "${myLog}"
/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Starting ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"

CHECK_FOR_LOGIN
CHECK_FOR_RUN
MAIN_DIALOG

		# Add the completion file so this script will no longer run.
/usr/bin/defaults write edu.stonybrook.LoginTutorial FirstLoginComplete -int 1
	# Opening Self Service.
if [ "${myUserShortName}" != "desktopsupport" ]; then
	/usr/bin/open "/Applications/Self Service+.app"
fi

/bin/echo "$(myTimeStamp) ${myHost} ${myProcName}[${myPID}]: Ending: ${myProcName}. Version: ${vers}." | /usr/bin/tee -a "${myLog}"
/bin/echo "" | /usr/bin/tee -a "${myLog}"

exit 0

