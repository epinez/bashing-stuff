#!/bin/bash

#Script to forward email address and drive ownership to person specified. 
#the Drive forwarding will forward all contents, including Shared and Private docs

#clear the screen
clear

#TODO fix this part to pull the current user better.
#TODO - https://scriptingosx.com/2020/02/getting-the-current-user-in-macos-update/

# Get the current user
# LOGGEDIN=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
LOGGEDIN=$(echo $USER)

echo $LOGGEDIN

# Check for gam
APP7="/Users/$LOGGEDIN/bin/gam7/gam"
APP="/Users/$LOGGEDIN/bin/gam/gam"

if test -f "$APP"; then
   printf 'GAM exists.\n\n'
   GAM=$APP
elif test -f "$APP7"; then 
	printf 'GAM exists. \n\n'
	GAM=$APP7
else
echo "Gam is not installed."
	exit
fi

echo $GAM

#archive calendar ID.  As of 2024-04-01, this calendar is the IT_internal calendar, but can be changed easily enough with a different ID
CALENDAR=#CalendarID goes here

read -p 'Enter the name of the affected user: ' ARCHIVE_REMINDER
printf "In 60 days at 10am, the account of $ARCHIVE_REMINDER will need to  be moved to the archive."

#Start/end times for the calendar reminder
REMINDER_START=$(date -v+60d +"%Y-%m-%dT10:00:00-04:00")
REMINDER_END=$(date -v+60d +"%Y-%m-%dT11:00:00-04:00")

#Whose email is being forwarded? Where does it need to go?
read -p 'Enter the email address of the account that needs forwarding: ' OLD_USER
read -p 'Enter the email address of the person receiving: ' NEW_USER

#confirm
printf "$OLD_USER will have their email and Drive forwarded to $NEW_USER.\n\n"
read -p 'Enter y to confirm: ' USER_CHOICE


if [[ "$USER_CHOICE" =~ ^([yY][eE][sS]|[yY])$ ]]
then
	#Unsuspend the user
	echo "Unsuspending $OLD_USER in GWS\n"
	$GAM update user $OLD_USER suspended off
	
	#setting a random password to the account.
	$GAM update user $OLD_USER password random
	
	#add the forwarding address to the account
	echo "Adding $NEW_USER as forwarding addess\n"
	$GAM user $OLD_USER add forwardingaddress $NEW_USER
	
	#forward the email to the new account, keeping email in old mailbox as well
	$GAM user $OLD_USER forward on $NEW_USER keep
	
	#transfer Drive to new user
	echo "Now transferring Drive ownership to $NEW_USER\n"
	$GAM create datatransfer $OLD_USER gdrive $NEW_USER privacy_level shared,private
	
	#Add calendar reminder to the IT_internal calendar
	echo "Adding calendar reminder to move this account to the archive\n"
	$GAM calendar $CALENDAR addevent summary "$ARCHIVE_REMINDER" start $REMINDER_START end $REMINDER_END
	echo "An event titled $ARCHIVE_REMINDER has been added to the IT_Internal calendar"
else
	echo "Oh, sorry. My bad. Your fault."
	exit
fi
