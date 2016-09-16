#! /bin/bash
#
#############################################################################################################################
# NAME:         valuebond_subtheme_setup.sh
# VERSION:      1.0
# EMAIL:        adityaanurag21@gmail.com
# DESCRIPTION:  This is script if for setting up the sub-theme.
# USAGE:        This script must be started as normal user
#		./valuebond_subtheme_setup.sh
#
##############################################################################################################################
#
# Set the log level for your script. Possible values are:
# 0 - ERROR only
# 1 - 0 + WARNING
# 2 - 1 + INFO
# 3 - Everything
declare -i MYDEBUGLEVEL=0

# Script ROOT Path
ROOT_PATH=/var/www/html/
SCRIPT_PATH=$ROOT_PATH/scripts/SUBTHEME_SETUP
PROJECT_PATH=$ROOT_PATH/d8
# EXIT CODES
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ABBORT=111
EXIT_NO_FILE_OR_DIR=40
EXIT_FIND_ERROR=41
EXIT_XARGS_ERROR=42
EXIT_RM_ERROR=43
EXIT_INPUT_ERROR=44
EXIT_NOT_ALLOWED=45
ERROR_WGET=47
EXIT_PID_EXIST=46

# My name
MY_SCRIPT_NAME=$(basename $0)
#Mail Recipient
EMAIL="adityaanurag21@gmail.com"
ERROR_MAIL="adityaanurag21@gmail.com"
# PID file
PIDFILE=$SCRIPT_PATH/pid/$MY_SCRIPT_NAME.pid
# Date
DATE=`date +%Y-%m-%d`
# LOG File Name and Path
LOGFILE=$SCRIPT_PATH/log/${MY_SCRIPT_NAME}_${DATE}.log
# Wget Programme
WGET_PROG=/usr/bin/wget

# Global Functions
# Check/create logfile
function create_logfile {
        if [ ! -f $LOGFILE ]; then
                echo "WARNING - Could not find logfile $LOGFILE"
                echo "INFO - Creating logfile $LOGFILE..."
                touch $LOGFILE
                if [ $? != "0" ]; then
                        echo "ERROR - Could not create logfile $LOGFILE"
                        exit 1
                else
                        echo "INFO - Found logfile $LOGFILE..."
                fi
        fi
}

# This function just prints out one line at the beginning
function print_start {

	echo "INFO - ########## $MY_SCRIPT_NAME started ##########" >> $LOGFILE

}



# This function just prints out one line at the end
function print_end {

	echo "INFO - ########## $MY_SCRIPT_NAME stopped ##########" >> $LOGFILE
	goexit $EXIT_SUCCESS

}

# Function goexit
function goexit() {
  MYEXITSTATUS="$1"
  if [ "$MYEXITSTATUS" = "0" ]; then
    echo "INFO - Program $MY_SCRIPT_NAME terminates with status $MYEXITSTATUS." >> $LOGFILE
    else
      echo "ERROR - Program $MY_SCRIPT_NAME terminates with status $MYEXITSTATUS." >> $LOGFILE
  fi
 # exit "$MYEXITSTATUS"
}

# PID FILE

# This function checks/creates .pid file
function create_pidfile {

	if [ -f $PIDFILE ];then
		PIDTMP=$(cat $PIDFILE)
		echo "ERROR - $MY_SCRIPT_NAME is running already with PID $PIDTMP" >> $LOGFILE
		echo "$MY_SCRIPT_NAME could not be started. $PIDFILE already present with PID $PIDTMP!" |mail -s "SCRIPT-WARNING: $HOSTNAME $MY_SCRIPT_NAME" $ERROR_MAIL
		goexit $EXIT_PID_EXIST
	else
		echo $$ > $PIDFILE
		echo "INFO - $PIDFILE created with PID $$" >> $LOGFILE
	fi
}


# This function removes the .pid file
function remove_pidfile {
	if [ -f $PIDFILE ];then
		rm $PIDFILE
		if [ $? != "0" ];then
			echo "ERROR - Could not remove $PIDFILE" >> $LOGFILE
			echo "$MY_SCRIPT_NAME did not finsh propperly. $PIDFILE could not be removed!" |mail -s "SCRIPT-WARNING: $HOSTNAME $MY_SCRIPT_NAME" $ERROR_MAIL
		else
			echo "INFO - $PIDFILE removed" >> $LOGFILE
		fi
	else
		echo "WARN - $PIDFILE does not exsist, could not be removed" >> $LOGFILE
	fi
}

# This function checks for the source configuration files
function check_boot_source_conf {
BOOTSTRAPCONF=$SCRIPT_PATH/conf/BOOTSTRAP_VERSION.conf
if [ -f $BOOTSTRAPCONF ]; then
    echo "INFO - Boot Starp Configuration file found" >> $LOGFILE
    source $BOOTSTRAPCONF
    echo "INFO - Configuration loaded successfully" >> $LOGFILE
else
    echo "ERROR - Boot Starp configuration file not found. Please check" >> $LOGFILE
    echo -e "$MY_SCRIPT_NAME did not finsh properly.\nConfiguration file $BOOTSTRAPCONF not found.\nPlease login and Check" | mail -s "SCRIPT-WARNING: $HOSTNAME $MY_SCRIPT_NAME" $ERROR_MAIL
    goexit $EXIT_NO_FILE_OR_DIR
fi
}

# This function checks the presence of the mandatory path
function check_path {
	
	declare -a TO_CHECK=('THEME_ROOT' 'BOOTSTRAP_ROOT' 'STARTERKIT_ROOT')
	declare -a DES_THEME_ROOT=($PROJECT_PATH/themes)
	declare -a DES_BOOTSTRAP_ROOT=($DES_THEME_ROOT/bootstrap)
	declare -a DES_STARTERKIT_ROOT=($DES_BOOTSTRAP_ROOT/starterkits)
	for paths in "${TO_CHECK[@]}"
	do
		PATH_TMP=DES_$paths[@]
		cd ${!PATH_TMP} 2> /dev/null
		if [ $? == "0" ]; then
			echo "INFO - The Path ${!PATH_TMP} exist in the Server. Proceed to check further" >> $LOGFILE
		elif [ ${!PATH_TMP} == "$DES_THEME_ROOT/bootstrap" ]; then
			echo "INFO - The bootstrap directory not exist. Will download now and extract the base file" >> $LOGFILE
			check_boot_source_conf
			cd $PROJECT_PATH/themes;$WGET_PROG https://ftp.drupal.org/files/projects/$BOOTSTRAP_VERSION 2> /dev/null
			if [ $? == "0" ]; then
				echo "INFO - Bootstrap File Downloaded successfully in `pwd`" >> $LOGFILE
				echo "INFO - Will Extract now the $BOOTSTRAP_VERSION" >> $LOGFILE
				tar -xvf $BOOTSTRAP_VERSION &>/dev/null
					if [ $? == "0" ]; then
						rm $PROJECT_PATH/themes/$BOOTSTRAP_VERSION
						echo "INFO - Bootstarp extracted successfully. Will Proceed further now." >> $LOGFILE
					else
						echo "ERROR - Bootstrap failed to extract.  Please check manually." >> $LOGFILE
						echo "$MY_SCRIPT_NAME did not finsh propperly.Bootstrap not extracted properly.!" |mail -s "SCRIPT-WARNING: $HOSTNAME $MY_SCRIPT_NAME" $ERROR_MAIL
					fi
			else
				echo "ERROR - Error in Downloading Bootstrap. Please check manually" >> $LOGFILE
				echo "$MY_SCRIPT_NAME did not finsh propperly.Bootstrap not downloaded properly.!" |mail -s "SCRIPT-WARNING: $HOSTNAME $MY_SCRIPT_NAME" $ERROR_MAIL
				goexit $ERROR_WGET
			fi
		else
			echo "ERROR - The Path ${!PATH_TMP} not found in the server. Plese login and check" >> $LOGFILE
			echo "$MY_SCRIPT_NAME did not finsh propperly.${!PATH_TMP} could not found!" |mail -s "SCRIPT-WARNING: $HOSTNAME $MY_SCRIPT_NAME" $ERROR_MAIL
			goexit $EXIT_FIND_ERROR
		fi
	done
	
	

}
function check_starterkitdir_conf {
STARTERKITCONF=$SCRIPT_PATH/conf/STARTERKIT.conf
if [ -f $STARTERKITCONF ]; then
    echo "INFO - Starterkit Directory Configuration file found" >> $LOGFILE
    source $STARTERKITCONF
    echo "INFO - Configuration loaded successfully" >> $LOGFILE
else
    echo "ERROR - Starterkit Directory configuration file not found. Please check" >> $LOGFILE
    echo -e "$MY_SCRIPT_NAME did not finsh properly.\nConfiguration file $STARTERKITCONF not found.\nPlease login and Check" | mail -s "SCRIPT-WARNING: $HOSTNAME $MY_SCRIPT_NAME" $ERROR_MAIL
    goexit $EXIT_NO_FILE_OR_DIR
fi
}

# This function will check for the Mandatory presence of Directories
function check_directory {
echo "INFO - Checking now the Starterkit Diretory Configuration files" >> $LOGFILE
check_starterkitdir_conf
STARTERKIT_PATH=$PROJECT_PATH/themes/bootstrap/starterkits
for f in $CDN $LESS $SASS
do
	ls -ld $STARTERKIT_PATH/$f &>/dev/null
	if [ $? == "0" ]; then
		echo "INFO - Directory $f exist in Path $STARTERKIT_PATH" >> $LOGFILE
	else
		echo "ERROR - Missing Directory $f in Path $STARTERKIT_PATH" >> $LOGFILE
		echo -e "$MY_SCRIPT_NAME did not finsh properly.\nDirectory $f not found in $STARTERKIT_PATH.\nPlease login and Check" | mail -s "SCRIPT-WARNING: $HOSTNAME $MY_SCRIPT_NAME" $ERROR_MAIL
		goexit $EXIT_NO_FILE_OR_DIR
	fi
done
}

# This function will copy the User input directory name to bootstrap directory
function copy_project {
echo "Please Enetr the Directory Name which you want to copied to themes Directory, Availables are (cdn , less , sass)"
read DIR_NAME
ls -ld $STARTERKIT_PATH/$DIR_NAME &>/dev/null
if [ $? == "0" ]; then
        echo "INFO - Entered Directory Name $DIR_NAME Exist" >> $LOGFILE
         if [ -d $PROJECT_PATH/themes/$DIR_NAME ]; then
          echo "INFO - Entered Directory  $DIR_NAME already Exist in themes directory" >> $LOGFILE
	  return
         else
         echo "INFO - Entered Directory $DIR_NAME will be copy to themes directory:Please Wait....... " >> $LOGFILE 
      fi 
else
        echo "INFO - Entered Directory Name $DIR_NAME not Exist" >> $LOGFILE
        echo "Entered Directory Name $DIR_NAME not Exist ! Please privide a available directory name" >> $LOGFILE
	copy_project
fi
#Copy the user input directory to themes directory
cp -rf $STARTERKIT_PATH/$DIR_NAME $PROJECT_PATH/themes/
if [ $? == "0" ]; then
 echo "INFO - Copy command sucessful:$DIR_NAME directory copied to themes directory" >> $LOGFILE
 else 
 echo "INFO - Copy Action of $DIR_NAME failed!!!!!" >> $LOGFILE 
fi
}

# This function will check for the presence of projectconfiguration files
function check_project_conffiles {
PROJECTCONF=$SCRIPT_PATH/conf/PROJECTFILES.conf
if [ -f $PROJECTCONF ]; then
    echo "INFO - Project Configuration file found" >> $LOGFILE
    source $PROJECTCONF
    echo "INFO - Configuration loaded successfully" >> $LOGFILE
else
    echo "ERROR - Project configuration file not found. Please check" >> $LOGFILE
    echo -e "$MY_SCRIPT_NAME did not finsh properly.\nConfiguration file $PROJECTCONF not found.\nPlease login and Check" | mail -s "SCRIPT-WARNING: $HOSTNAME $MY_SCRIPT_NAME" $ERROR_MAIL
    goexit $EXIT_NO_FILE_OR_DIR
fi

for f in $DOTTHEME $DOTLIB $DOTINFO $DOTSETTING $DOTSCHEMA
do
	find $PROJECT_PATH/themes/$DIR_NAME -type f -name "$f" &>/dev/null
	if [ $? == "0" ]; then
		echo "INFO - File $f found in $ROOT_PATH/themes/$DIR_NAME" >> $LOGFILE
	else
		echo "ERROR - File $f not found in $ROOT_PATH/themes/$DIR_NAME. Please login and check" >> $LOGFILE
		echo -e "$MY_SCRIPT_NAME did not finsh properly.\nConfiguration file $f not found.\nPlease login and Check" | mail -s "SCRIPT-WARNING: $HOSTNAME $MY_SCRIPT_NAME" $ERROR_MAIL
		goexit $EXIT_NO_FILE_OR_DIR
	fi
	
done
}

# This function will rename the Project Directory
function rename_project_directory {
echo "Please Enter the new Project Name >>>"
read PROJECT_NAME
echo "Please Enter again the new Project Name >>>"
read PROJECT_NAME_CONF
if [ "$PROJECT_NAME" == "$PROJECT_NAME_CONF" ]; then
	echo "INFO - Renaming the Directory $DIR_NAME to $PROJECT_NAME" >> $LOGFILE
	mv $PROJECT_PATH/themes/$DIR_NAME $PROJECT_PATH/themes/$PROJECT_NAME
	echo "INFO - Renaming the Directory $DIR_NAME to $PROJECT_NAME successful" >> $LOGFILE
	sleep 10
else
	echo "Entered Name doesn't match. Please Enter the correct name !!!!"
	rename_project_directory
fi
}

# This function will rename the Project files
function rename_project_files {
echo "INFO - Renaming now the Project specific Configuration files" >> $LOGFILE
mv $PROJECT_PATH/themes/$PROJECT_NAME/$DOTTHEME $PROJECT_PATH/themes/$PROJECT_NAME/$PROJECT_NAME.theme 1>/dev/null
mv $PROJECT_PATH/themes/$PROJECT_NAME/$DOTLIB $PROJECT_PATH/themes/$PROJECT_NAME/$PROJECT_NAME.libraries.yml 1>/dev/null
mv $PROJECT_PATH/themes/$PROJECT_NAME/$DOTINFO $PROJECT_PATH/themes/$PROJECT_NAME/$PROJECT_NAME.info.yml 1>/dev/null
mv $PROJECT_PATH/themes/$PROJECT_NAME/config/install/$DOTSETTING $PROJECT_PATH/themes/$PROJECT_NAME/config/install/$PROJECT_NAME.settings.yml 1>/dev/null
mv $PROJECT_PATH/themes/$PROJECT_NAME/config/schema/$DOTSCHEMA $PROJECT_PATH/themes/$PROJECT_NAME/config/schema/$PROJECT_NAME.schema.yml 1>/dev/null
echo "INFO - Renaming th Project specific Configuration files successful" >> $LOGFILE
}

# This function is for editing the required project files
function edit_project_files {
FILEPATH=$PROJECT_PATH/themes/$PROJECT_NAME
FILENAME=$FILEPATH/$PROJECT_NAME.info.yml
SEARCHSTRING="THEMETITLE"
SEARCHSTRING2="THEMENAME"
echo "INFO  - Editing the $FILENAME with Project Specific Name" >> $LOGFILE
sed -i "s/$SEARCHSTRING/$PROJECT_NAME/g" $FILENAME
if [ $? == "0" ]; then
	sed -i "s/$SEARCHSTRING2/$PROJECT_NAME/g" $FILENAME
	echo "INFO - File Name $FILENAME Edited successfully" >> $LOGFILE
else
	echo "ERROR - File Name $FILENAME not Edited successfully" >> $LOGFILE
fi
}
############################################################################
################################### Main ###################################
############################################################################
create_logfile
print_start
create_pidfile
check_path
check_directory
copy_project
check_project_conffiles
rename_project_directory
rename_project_files
edit_project_files
remove_pidfile
print_end
