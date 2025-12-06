# Overclock Manager by SDWEAK

📄 [RUSSIAN README](README.md)

## Installation
### Installation Steps:

1. Switch to **Desktop Mode**.
2. Open **Konsole**.
3. Set a `sudo` password (if you haven’t already):

   ```bash
   passwd
   ```

4. Download the [installation shortcut](https://raw.githubusercontent.com/Taskerer/Overclock-Manager/refs/heads/main/OC-Manager-installer.desktop):  
   Right-click on the link → **Save As...** and save to your desktop (if using Firefox, remove the .download at the end of the file).  
   Then double click the file and the installation will begin.

5. After installation, launch the `Overclock Manager` shortcut from the desktop.

## Updating

1. Run the previously downloaded `Install Overclock Manager` shortcut.  
   The script will install the latest version over the current one.
2. After the update, run the `Overclock Manager` shortcut again.

## Donate

If you enjoy Overclock Manager and want to support its development:

- 💳 [Support via Tinkoff](https://www.tinkoff.ru/cf/8HHVDNi8VMS)

Thank you for using Overclock Manager!

## Functions and Usage

### **Backup BIOS** - backup the current BIOS
The backup is saved to the BIOS_BACKUP folder in the home directory.

### **SREP Configuration** - configuration of BIOS unlocking with SREP

- **Standart SREP** - SREP installation with standard configuration.
- **Custom SREP** - Set SREP with custom underwinding values. Opposite the standard undervolting values write the values you need (from 10 to 99 inclusive).
- **Delete SREP** - Deletes SREP files.

### **Download BIOS** - download current BIOS versions
It is necessary to manually flash the BIOS version you need.

### **Flash BIOS**
Flashes the pre-downloaded BIOS version you need. Also allows you to back up the current BIOS before flashing. Automatically blocks BIOS auto-update.

### **TDP Value** - change maximum TDP available in Steam QAM
Enter your desired maximum TDP value for the TDP slider in Steam QAM. **IMPORTANT!** **You need to raise the TDP in the BIOS beforehand so raising the TDP above 15W will work (Detailed instructions in the [guide](http://deckoc.notion.site/STEAM-DECK-RUS-76e43eacaf8b400ab130692d2d099a02?pvs=4)).**

### **GPU Clock** - change the maximum GPU frequency available in Steam QAM
Enter your desired maximum GPU frequency value for the GPU frequency slider in Steam QAM. **IMPORTANT!** **You need to raise the maximum GPU frequency in BIOS beforehand so that fixing GPU frequency above 1600MHz will work (Detailed instructions in the [guide](http://deckoc.notion.site/STEAM-DECK-RUS-76e43eacaf8b400ab130692d2d099a02?pvs=4)).**

### **Power Tools** - change the maximum GPU frequency available in Power Tools
**The Power Tools plugin must be installed beforehand for this feature to work!** Enter the maximum GPU frequency value you want in Power Tools.

### **Smokeless Unlock** - **For LCD and BIOS versions 110-116 only**
Unlock CBS/PBS menu on old BIOS for LCD.

### **Block BIOS Update**
Blocking the automatic BIOS update is necessary if you want to use an older BIOS version.

### **Unblock BIOS Update**
Unblock automatic BIOS update.

## Recommendations

Additional tips to enhance Steam Deck performance:

- ⭐ [SDWEAK](https://github.com/Taskerer/SDWEAK) - SteamOS optimization to improve performance in games on Steam Deck
- 🔧 [My overclocking & optimization guide](http://deckoc.notion.site/STEAM-DECK-RUS-76e43eacaf8b400ab130692d2d099a02?pvs=4)
- ⚡ [Decky-Undervolt](https://github.com/totallynotbakadestroyer/Decky-Undervolt) — a plugin for undervolting CPU directly from the system (available in Decky Loader Store)
- 🎮 [ECLIPSE mods](https://t.me/kf4fr/850467) — targeted game tweaks that can significantly boost performance and FPS

## Thanks

- 💬 A **huge thank you** to our [Telegram community](https://t.me/steamdeckoverclock) for testing and development support!  
  All new features are developed and discussed there — join us!
- **To the developer of [SteamDeck-BIOS-Manager](https://github.com/ryanrudolfoba/SteamDeck-BIOS-Manager)** — for the great project that formed the basis and inspired me to create Overclock Manager.
- **SmokelessCPU** for creating SREP and Smokeless Unlock.

## Feedback

- Create an **issue** describing your problem
- Message me on Telegram: **@biddbb**
- Or write in our [Telegram group](https://t.me/steamdeckoverclock) — we're happy to help!

## Contributing

Pull requests are welcome!  
For major changes, please open an issue first to discuss what you'd like to do.

## License

[MIT License](https://choosealicense.com/licenses/mit/)
