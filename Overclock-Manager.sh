#!/bin/bash

# Entering and verifying sudo password
status=$(passwd --status $USER | awk '{print $2}')
if [ "$status" == "P" ]; then
  password=$(zenity --password --title "Enter sudo password" --text "Please enter your sudo password:")
  if [ -z "$password" ]; then
    zenity --error --text "Password entry cancelled." --title "Overclock Manager"
    exit 1
  fi
  if ! echo "$password" | sudo -S -v &>/dev/null; then
    zenity --error --text "Sudo password is wrong!" --title "Overclock Manager"
    exit 1
  fi
else
  zenity --warning --text "Sudo password is blank! Please set a sudo password." --title "Overclock Manager"
  exit 1
fi

MODEL=$(cat /sys/class/dmi/id/board_name)
BIOS_VERSION=$(cat /sys/class/dmi/id/bios_version)

# Compatibility check
if [ "$MODEL" != "Jupiter" ] && [ "$MODEL" != "Galileo" ]; then
  zenity --error --title "Overclock Manager" --text \
    "Overclock Manager is compatible with Steam Deck only!" --width 350 --height 75
  exit 1
fi

# Blocking automatic BIOS update.
block_bios_updates() {
	echo -e "$password" | sudo -S steamos-readonly disable
	echo -e "$password" | sudo -S systemctl mask jupiter-biosupdate
	echo -e "$password" | sudo -S mkdir -p /foxnet/bios/ &>/dev/null
	echo -e "$password" | sudo -S touch /foxnet/bios/INHIBIT &>/dev/null
	echo -e "$password" | sudo -S mkdir /usr/share/jupiter_bios/bak &>/dev/null
	echo -e "$password" | sudo -S mv /usr/share/jupiter_bios/F* /usr/share/jupiter_bios/bak &>/dev/null
}

# --- Main ---
echo -e "$password" | sudo -S steamos-readonly disable &>/dev/null
while true
do
Choice=$(zenity --width 780 --height 429 --list --radiolist \
	--title "Overclock Manager"\
	--column "Select One" \
	--column "Option" \
	--column="Description"\
	FALSE "Backup BIOS" "Backup the current BIOS."\
	FALSE "SREP Configuration" "Configure unlocked BIOS options using SREP."\
	FALSE "Download BIOS" "Download all BIOS versions for manual flashing."\
	FALSE "Flash BIOS" "Flashing the downloaded BIOS and backup the current BIOS."\
	FALSE "TDP Value" "Change the maximum TDP value in the Steam QAM menu."\
	FALSE "GPU Clock" "Change the maximum locked GPU frequency in the Steam QAM menu."\
	FALSE "Power Tools" "Change the GPU frequency in the Power Tools configuration."\
	FALSE "Smokeless Unlock" "LCD only! Unlock CBS/PBS menu in BIOS versions 110-116."\
	FALSE "Block BIOS Update" "Prevent SteamOS from automatically installing BIOS updates."\
	FALSE "Unblock BIOS Update" "Allow SteamOS to automatically install BIOS updates."\
	TRUE EXIT "Exit this script.")

if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]; then
	rm -f ./BIOS/F*.fd &>/dev/null
	exit

elif [ "$Choice" == "Backup BIOS" ]; then
	clear
	BACKUP_DIR="$HOME/BIOS_BACKUP"
	mkdir -p "$BACKUP_DIR"
	BACKUP_FILENAME="$BACKUP_DIR/jupiter-$BIOS_VERSION-bios-backup-$(date +%Y-%m-%d_%H-%M-%S).bin"
	(echo -e "$password" | sudo -S /usr/share/jupiter_bios_updater/h2offt "$BACKUP_FILENAME" -O) &> /dev/null &
	BACKUP_PID=$!

	while ps -p $BACKUP_PID > /dev/null; do
    	sleep 0.5
	done | zenity --progress \
		--title="Backup in Progress" \
		--text="Creating BIOS backup...\n\nPlease wait, this may take a moment." \
		--pulsate \
		--auto-close \
		--width=400
	wait $BACKUP_PID
	EXIT_CODE=$?

	if [ $EXIT_CODE -eq 0 ] && [ -f "$BACKUP_FILENAME" ]; then
		zenity --info --title "Overclock Manager" --text "BIOS backup successfully completed! \
			\n\nBackup is saved in:\n<b>$BACKUP_DIR</b>" --width 450 --height 100
	else
		zenity --error --title "Overclock Manager" --text "An error occurred during the BIOS backup process. The backup may have failed." --width 400
	fi
	clear

elif [ "$Choice" == "SREP Configuration" ]; then
	clear
	if [[ "$MODEL" = "Galileo" || ( "$MODEL" = "Jupiter" && ( "$BIOS_VERSION" = "F7A0131" || "$BIOS_VERSION" = "F7A0133" ) ) ]]; then
		SREP_Choice=$(zenity --width 660 --height 250 --list --radiolist --multiple --title "Overclock Manager" \
			--column "Select One" --column "Option" --column="Description"\
			FALSE "Standard SREP" "Install SREP with standard configuration."\
			FALSE "Custom SREP" "Install SREP with custom undervolting values."\
			FALSE "Delete SREP" "Delete SREP files from the ESP."\
			TRUE "Main Menu" "Go back to Main Menu.")

			if [ $? -eq 1 ] || [ "$SREP_Choice" == "Main Menu" ]; then
				continue

			elif [ "$SREP_Choice" == "Standard SREP" ]; then
				echo -e "$password" | sudo -S rm -rf /esp/efi/$MODEL-SREP /esp/SREP.log /esp/SREP_Config.cfg
				mkdir ./$MODEL-SREP
				unzip -j -d ./$MODEL-SREP ./extras/SREP.zip
				if [ $? -eq 0 ]; then
					echo -e "$password" | sudo -S mv -f ./$MODEL-SREP/SREP_Config.cfg /esp &>/dev/null
					echo -e "$password" | sudo -S cp -R ./$MODEL-SREP /esp/efi
					rm -rf ./$MODEL-SREP
					zenity --info --title "Overclock Manager" --text "SREP files has been copied to the ESP!" --width 350 --height 75
					clear
				else
					rm -rf ./$MODEL-SREP
					zenity --error --title "Overclock Manager" --text "An error occurred while unpacking SREP files!" \
						--width 350 --height 75
				fi

			elif [ "$SREP_Choice" == "Custom SREP" ]; then
				echo -e "$password" | sudo -S rm -rf /esp/efi/$MODEL-SREP /esp/SREP.log /esp/SREP_Config.cfg
				mkdir ./$MODEL-SREP
				cp ./extras/RUNTIME-PATCHER.efi ./$MODEL-SREP
				echo -e "$password" | sudo -S cp -rf ./$MODEL-SREP /esp/efi
				rm -rf ./$MODEL-SREP
				rm -f ./SREP_Config.cfg
				cp ./extras/SREP_Config_custom.cfg ./SREP_Config.cfg
				zenity --forms \
					--title="Overclock Manager" \
    				--text="Write the undervolting values you want to use instead of the default values." \
    				--separator="," \
    				--add-entry="Value instead of -10 mV" \
    				--add-entry="Value instead of -20 mV" \
    				--add-entry="Value instead of -30 mV" \
    				--add-entry="Value instead of -40 mV" \
    				--add-entry="Value instead of -50 mV" > ./extras/uv.conf
    			if [ $? -eq 1 ]; then
    				continue
    			else
    			process_undervolt() {
        			local undervolt_config_file="./extras/uv.conf"
        			local srep_config_file="./SREP_Config.cfg"
        			if [ ! -f "$undervolt_config_file" ]; then
						zenity --error --title "Overclock Manager" --text "File '$undervolt_config_file' not found."
						return 1
					fi
        			if [ ! -f "$srep_config_file" ]; then
        				zenity --error --title "Overclock Manager" --text "File '$srep_config_file' not found."
        				return 1
    				fi
        			IFS=',' read -r -a undervolt_values < "$undervolt_config_file"
        			if [ "${#undervolt_values[@]}" -ne 5 ]; then
            			zenity --error --title "Overclock Manager" --text "File '$undervolt_config_file' must contain exactly five numbers."
            			return 1
        			fi
        			local sed_cmds=()
        			for i in "${!undervolt_values[@]}"; do
            			local value="${undervolt_values[$i]}"
            			local abs_val="${value#-}"
            			if ! [[ "$abs_val" =~ ^[0-9]{2}$ ]]; then
                			zenity --error --title "Overclock Manager" --text "Value '$abs_val' (from '$value') incorrectly. \
                			\n\nIts modules must be a number between 10 and 99." --width 400 --height 75
                			return 1
            			fi
            			local index=$((i + 1))
            			local digit1="${abs_val:0:1}"
            			local digit2="${abs_val:1:1}"
            			local calc1=$((30 + digit1))
            			local calc2=$((30 + digit2))
            			local placeholder1="#${index}00#0"
            			local replacement1="${calc1}00${calc2}"
            			sed_cmds+=("-e" "s/${placeholder1}/${replacement1}/g")
            			local hex_val=$(printf "%02X" "$abs_val")
            			local placeholder2="#${index}"
            			local replacement2="$hex_val"
            			sed_cmds+=("-e" "s/${placeholder2}/${replacement2}/g")
        			done
        			if sed "${sed_cmds[@]}" -i "$srep_config_file"; then
            			zenity --info --title "Overclock Manager" --text "The custom undervolting configuration using SREP has been successfully applied." --width 350 --height 75
            			clear
        			else
            			zenity --error --title "Overclock Manager" --text "Error when updating a file '$srep_config_file'."
            			return 1
        			fi
        			return 0
    			}
    			process_undervolt
    			echo -e "$password" | sudo -S mv -f ./SREP_Config.cfg /esp &>/dev/null
    			rm -f ./extras/uv.conf
    			fi

			elif [ "$SREP_Choice" == "Delete SREP" ]; then
				# Delete SREP files from ESP
				echo -e "$password" | sudo -S rm -rf /esp/efi/$MODEL-SREP /esp/SREP.log /esp/SREP_Config.cfg
				zenity --info --title "Overclock Manager" --text "SREP files were successfully deleted from ESP!" --width 350 --height 75
			fi
	else
		zenity --error --title "Overclock Manager" --text "BIOS $BIOS_VERSION can\'t be unlocked using SREP. \
			\n\nOnly BIOS versions 131 and 133 on Steam Deck LCD can be unlocked with SREP. Use Smokeless or flash the required BIOS verison." --width 400 --height 75
	fi

elif [ "$Choice" == "Download BIOS" ]; then
	# Checking Internet access
	if ! ping -c 1 8.8.8.8 &>/dev/null || ! ping -c 1 1.1.1.1 &>/dev/null || ! ping -c 1 208.67.222.222 &>/dev/null || ! ping -c 1 9.9.9.9 &>/dev/null || ! ping -c 1 94.140.14.14 &>/dev/null || ! ping -c 1 8.26.56.26 &>/dev/null; then
    	zenity --error --title "Overclock Manager" --text "No Internet connection!\nPlease connect to the Internet and try again."
    	continue
	fi
    # Preparation
	clear
	mkdir -p ./BIOS &>/dev/null
	rm -f ./BIOS/F*.fd &>/dev/null
	declare -a files_to_download
	if [ "$MODEL" = "Jupiter" ]; then
		files_to_download=(
			"https://gitlab.com/evlaV/jupiter-hw-support/-/raw/0660b2a5a9df3bd97751fe79c55859e3b77aec7d/usr/share/jupiter_bios/F7A0110_sign.fd"
			"https://gitlab.com/evlaV/jupiter-hw-support/-/raw/38f7bdc2676421ee11104926609b4cc7a4dbc6a3/usr/share/jupiter_bios/F7A0116_sign.fd"
			"https://gitlab.com/evlaV/jupiter-hw-support/-/raw/eb91bebf4c2e5229db071720250d80286368e4e2/usr/share/jupiter_bios/F7A0131_sign.fd"
			"https://gitlab.com/evlaV/jupiter-hw-support/-/raw/5c14655a762870754f9d8574682b6727cb640904/usr/share/jupiter_bios/F7A0133_sign.fd"
		)
		device_name="Steam Deck LCD"
	elif [ "$MODEL" = "Galileo" ]; then
		files_to_download=(
			"https://gitlab.com/evlaV/jupiter-hw-support/-/raw/6101a30a621a2119e8c5213e872b268973659964/usr/share/jupiter_bios/F7G0112_sign.fd"
			"https://gitlab.com/evlaV/jupiter-hw-support/-/raw/eb91bebf4c2e5229db071720250d80286368e4e2/usr/share/jupiter_bios/F7G0110_sign.fd"
			"https://gitlab.com/evlaV/jupiter-hw-support/-/raw/7ffc22a4dc083c005e26676d276bdbd90dd1de5e/usr/share/jupiter_bios/F7G0109_sign.fd"
			"https://gitlab.com/evlaV/jupiter-hw-support/-/raw/a43e38819ba20f363bdb5bedcf3f15b75bf79323/usr/share/jupiter_bios/F7G0107_sign.fd"
		)
		device_name="Steam Deck OLED"
	fi

	# Downloading
	(
	file_count=${#files_to_download[@]}
	progress_step=$((100 / file_count))
	current_progress=0
	for url in "${files_to_download[@]}"; do
		filename=$(basename "$url")
		echo "# Downloading $filename for $device_name..."
		curl -s -L "$url" -o "./BIOS/$filename"
		current_progress=$((current_progress + progress_step))
		echo "$current_progress"
	done
	) | zenity --progress --title="Downloading BIOS" --text="Starting download..." --percentage=0 --auto-close --width=400

	if [ $? -eq 1 ]; then
		zenity --warning --title="Overclock Manager" --text="Download cancelled by user."
		continue
	fi

	# Checking hashes
	declare -A valid_hashes=(
		["F7A0110_sign.fd"]="098e1422362f4d69b32a3c073ed7cb1a"
		["F7A0116_sign.fd"]="fb57221367ba12913383ad07eeaf52ae"
		["F7A0131_sign.fd"]="86c73d1a294293913f27241ac3ed7fdf"
		["F7A0133_sign.fd"]="e0888c2513790e38e082d77e4d5755be"
		["F7G0107_sign.fd"]="b52ea4ec5069d3f22d6659f136bf9469"
		["F7G0109_sign.fd"]="b2b73afd31e7685132e2c634863e3e33"
		["F7G0110_sign.fd"]="336138b19d27526acd4642ffe53aee34"
		["F7G0112_sign.fd"]="44f0243f662c6d279eb55cdb89089f7f"
	)
	report_text="Download and Verification Report:\n\n"
	error_found=false

	if ! ls ./BIOS/*.fd &>/dev/null; then
		zenity --error --title "Overclock Manager" --text "No BIOS files were downloaded. Please check your connection and try again."
		continue
	fi

	for BIOS_FD in ./BIOS/*.fd; do
		filename=$(basename "$BIOS_FD")
		if [ -z "${valid_hashes[$filename]}" ]; then
			report_text+="$filename: ❌ Unknown file (not in hash list).\n"
			error_found=true
			continue
		fi
		file_hash=$(md5sum "$BIOS_FD" | cut -d " " -f 1)
		if [ "$file_hash" == "${valid_hashes[$filename]}" ]; then
			report_text+="$filename: ✅ MD5 hash OK.\n"
		else
			report_text+="$filename: ❌ MD5 hash MISMATCH!\n"
			error_found=true
			rm "$BIOS_FD"
		fi
	done

	if [ "$error_found" = true ]; then
		zenity --error --title "Verification Failed" --text="$report_text\nSome files failed verification and were deleted. Please try downloading again."
	else
		zenity --info --title "Success" --text="$report_text\nAll files downloaded and verified successfully."
	fi

elif [ "$Choice" == "Flash BIOS" ]; then
	clear
	if ! ls ./BIOS/F7?????_sign.fd &>/dev/null; then
		zenity --error --title "Overclock Manager" --text \
			"BIOS files not found.\n\nPlease perform the 'Download BIOS' operation first." --width 400 --height 75
		continue
	fi

	BIOS_Choice=$(zenity --title "Overclock Manager" --width 400 --height 400 --list \
		--column "BIOS Version" $(ls -l ./BIOS/F7?????_sign.fd | sed 's/^.*\\/\//') )

	if [ $? -eq 1 ]; then
		continue
	fi

	zenity --question --title "Overclock Manager" --text \
	"Do you want to backup the current BIOS before updating to $BIOS_Choice?\n\n(Recommended)" --width 400 --height 75

	BACKUP_REQUESTED=$?

	if [ $BACKUP_REQUESTED -eq 0 ]; then
		(echo -e "$password" | sudo -S /usr/share/jupiter_bios_updater/h2offt "$BACKUP_FILENAME" -O) &> /dev/null &
		BACKUP_PID=$!

		while ps -p $BACKUP_PID > /dev/null; do
    		sleep 0.5
		done | zenity --progress \
			--title="Backup in Progress (Step 1 of 2)" \
			--text="Creating BIOS backup...\n\nPlease wait." \
			--pulsate --auto-close --width=400

		wait $BACKUP_PID
		EXIT_CODE=$?
		if [ $EXIT_CODE -eq 0 ] && [ -f "$BACKUP_FILENAME" ]; then
			zenity --info --title="Step 2: Flashing" --text="Backup successful!\n\nNow proceeding to flash <b>$BIOS_Choice</b>.\n\nThe device will restart automatically. DO NOT turn it off." --width=400
			block_bios_updates
			echo -e "$password" | sudo -S /usr/share/jupiter_bios_updater/h2offt ./BIOS/$BIOS_Choice -all
		else
			zenity --error --title="Backup Failed" --text="The BIOS backup failed. The flashing process has been ABORTED to ensure safety.\n\nPlease try again." --width=400
			continue
		fi
	else
		zenity --question --title "Overclock Manager" --text \
			"You chose not to create a backup.\nCurrent BIOS will be updated to <b>$BIOS_Choice</b>!\n\nThis is a critical operation. DO NOT turn off your Steam Deck.\n\nProceed?" --width 400 --height 90
		if [ $? -eq 0 ]; then
			zenity --info --title="Flashing BIOS" --text="BIOS flashing will now begin for $BIOS_Choice.\n\nThe device will restart automatically upon completion.\n\nDO NOT turn off the device." --width=400
			block_bios_updates
			echo -e "$password" | sudo -S /usr/share/jupiter_bios_updater/h2offt ./BIOS/$BIOS_Choice -all
		else
			continue
		fi
	fi

elif [ "$Choice" == "TDP Value" ]; then
	clear
	zenity --forms \
		--title="Overclock Manager" \
    	--text="Enter the desired TDP value." \
    	--separator="," \
    	--add-entry="TDP value (in watts)" > ./extras/tdp.conf
	if [ $? -eq 1 ]; then
		continue
    else
		file1="/usr/share/steamos-manager/devices/jupiter.toml"
		file2="/usr/share/steamos-manager/platforms/jupiter.toml"
		if [ -f "$file1" ]; then
			CONFIG_FILE="./extras/tdp.conf"
			if [ ! -f "$CONFIG_FILE" ]; then
    			zenity --error --title "Overclock Manager" --text "File '$CONFIG_FILE' not found."
    			exit 1
			fi
			value=$(cat "$CONFIG_FILE")
			if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 2 ] || [ "$value" -gt 50 ]; then
    			zenity --error --title "Overclock Manager" --text ""$value" is incorrect. \
				\nIt should be between 2 and 50!" --width 400 --height 75
    			exit 1
			fi
			echo -e "$password" | sudo -S sed -i.bak '
			/\[tdp_limit\.range\]/ {
    			n
    			n
    			s/max = [0-9]\+/max = '"$value"'/
			}
			' "$file1"
			if [ $? -eq 0 ]; then
    			zenity --info --title "Overclock Manager" --text "Successfully set "$value"W TDP." --width 350 --height 75
    			rm -f ./extras/tdp.conf
			else
    			zenity --error --title "Overclock Manager" --text "Error when trying to set TDP!" \
						--width 350 --height 75
    			exit 1
			fi
		elif [ -f "$file2" ]; then
			CONFIG_FILE="./extras/tdp.conf"
			if [ ! -f "$CONFIG_FILE" ]; then
    			zenity --error --title "Overclock Manager" --text "File '$CONFIG_FILE' not found."
    			exit 1
			fi
			value=$(cat "$CONFIG_FILE")
			if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 2 ] || [ "$value" -gt 50 ]; then
    			zenity --error --title "Overclock Manager" --text ""$value" is incorrect. \
				\nIt should be between 2 and 50!" --width 400 --height 75
    			exit 1
			fi
			echo -e "$password" | sudo -S sed -i.bak '
			/\[tdp_limit]/ {
    			n
    			n
    			s/max = [0-9]\+/max = '"$value"'/
			}
			' "$file2"
			if [ $? -eq 0 ]; then
    			zenity --info --title "Overclock Manager" --text "Successfully set "$value"W TDP." --width 350 --height 75
    			rm -f ./extras/tdp.conf
			else
    			zenity --error --title "Overclock Manager" --text "Error when trying to set TDP!" \
						--width 350 --height 75
    			exit 1
			fi
		else
		zenity --error --title "Overclock Manager" --text \
			""$file1" was not found.\nThe system may be corrupted." --width 400 --height 75
		fi
    fi

elif [ "$Choice" == "GPU Clock" ]; then
	clear
	zenity --forms \
		--title="Overclock Manager" \
    	--text="Enter the desired GPU frequency." \
    	--separator="," \
    	--add-entry="GPU frequency (in MHz)" > ./extras/gpu.conf
	if [ $? -eq 1 ]; then
		continue
    else
    	file1="/usr/share/steamos-manager/devices/jupiter.toml"
		file2="/usr/share/steamos-manager/platforms/jupiter.toml"
		file3=""
		if [ -f "$file1" ]; then
			file3="$file1"
		elif [ -f "$file2" ]; then
			file3="$file2"
		fi
		if [ -f "$file3" ]; then
			CONFIG_FILE="./extras/gpu.conf"
			if [ ! -f "$CONFIG_FILE" ]; then
    			zenity --error --title "Overclock Manager" --text "File '$CONFIG_FILE' not found."
    			exit 1
			fi
			value=$(cat "$CONFIG_FILE")
			if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 200 ] || [ "$value" -gt 2400 ]; then
    			zenity --error --title "Overclock Manager" --text ""$value" is incorrect. \
				\nIt should be between 200 and 2300." --width 400 --height 75
    			exit 1
			fi
			echo -e "$password" | sudo -S sed -i.bak '
			/\[gpu_clocks]/ {
    			n
    			n
    			s/max = [0-9]\+/max = '"$value"'/
			}
			' "$file3"
			if [ $? -eq 0 ]; then
    			zenity --info --title "Overclock Manager" --text "GPU frequency of "$value"MHz has been successfully set." --width 350 --height 75
    			rm -f ./extras/gpu.conf
			else
    			zenity --error --title "Overclock Manager" --text "Error when trying to set GPU frequency." \
						--width 350 --height 75
    			exit 1
			fi
		else
			zenity --error --title "Overclock Manager" --text \
			""$file3" was not found.\nThe system may be corrupted." --width 400 --height 75
		fi
    fi

elif [ "$Choice" == "Power Tools" ]; then
	clear
	if [ -f /home/deck/homebrew/plugins/PowerTools/main.py ]; then
		zenity --forms \
		--title="Overclock Manager" \
    	--text="Enter the desired GPU frequency." \
    	--separator="," \
    	--add-entry="GPU frequency (in MHz)" > ./extras/pt.conf
		if [ $? -eq 1 ]; then
			continue
    	else
    		cp -f ./extras/limits_override.ron ./limits_override.ron
    		value=$(cat ./extras/pt.conf)
    		if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 200 ] && [ "$value" -le 2400 ]; then
      			sed -i "s/#freq/$value/g" ./limits_override.ron
      			cp -f ./limits_override.ron ~/homebrew/settings/PowerTools/limits_override.ron
      			zenity --info --title "Overclock Manager" --text "GPU frequency "$value"MHz successfully set in Power Tools configuration." --width 350 --height 75
      			rm -f ./extras/pt.conf
      			rm -f ./limits_override.ron
    		else
      			zenity --error --title "Overclock Manager" --text ""$value" is incorrect. \
				\nIt should be between 200 and 2300." --width 400 --height 75
				exit
    		fi
    	fi
	else
		zenity --error --title "Overclock Manager" --text \
		"Power Tools plugin is not installed" --width 400 --height 75
	fi

elif [ "$Choice" == "Smokeless Unlock" ]; then
	clear
	if [ "$MODEL" == "Galileo" ]; then
		zenity --error --title "Overclock Manager" --text "Steam Deck OLED can\'t be unlocked using Smokeless." --width 400 --height 75
	else
		if [ "$BIOS_VERSION" == "F7A0110" ] || [ "$BIOS_VERSION" == "F7A0113" ] || \
			[ "$BIOS_VERSION" == "F7A0115" ] || [ "$BIOS_VERSION" == "F7A0116" ]; then
			chmod +x ./extras/jupiter-bios-unlock
			echo -e "$password" | sudo -S ./extras/jupiter-bios-unlock
			zenity --info --title "Overclock Manager" --text "BIOS successfully unlocked with Smokeless. \
				\n\nYou can now access the AMD PBS/CBS menu in the BIOS." --width 400 --height 75
		else
			zenity --error --title "Overclock Manager" --text "BIOS $BIOS_VERSION can\'t be unlocked using Smokeless. \
				\n\nOnly BIOS versions 110-116 can be unlocked with Smokeless. Use SREP or flash the required BIOS verison." --width 420 --height 75
		fi
	fi

elif [ "$Choice" == "Block BIOS Update" ]; then
	clear
	# Blocking automatic BIOS update.
	block_bios_updates
	zenity --info --title "Overclock Manager" --text "Automatic BIOS update has been successfully blocked!" --width 400 --height 75

elif [ "$Choice" == "Unblock BIOS Update" ]; then
	clear
	echo -e "$password" | sudo -S steamos-readonly disable
	echo -e "$password" | sudo -S systemctl unmask jupiter-biosupdate
	echo -e "$password" | sudo -S rm -rf /foxnet &>/dev/null
	echo -e "$password" | sudo -S mv /usr/share/jupiter_bios/bak/F* /usr/share/jupiter_bios &>/dev/null
	echo -e "$password" | sudo -S rmdir /usr/share/jupiter_bios/bak &>/dev/null
	zenity --info --title "Overclock Manager" --text "Automatic BIOS update has been successfully unblocked!" --width 400 --height 75
fi
done
