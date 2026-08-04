cat > /mnt/user-data/outputs/mushm.sh << 'ENDOFFILE'
#!/bin/bash

get_largest_cros_blockdev() {
    local largest size dev_name tmp_size remo
    size=0
    for blockdev in /sys/block/*; do
        dev_name="${blockdev##*/}"
        echo "$dev_name" | grep -q '^\(loop\|ram\)' && continue
        tmp_size=$(cat "$blockdev"/size)
        remo=$(cat "$blockdev"/removable)
        if [ "$tmp_size" -gt "$size" ] && [ "${remo:-0}" -eq 0 ]; then
            case "$(doas sfdisk -l -o name "/dev/$dev_name" 2>/dev/null)" in
                *STATE*KERN-A*ROOT-A*KERN-B*ROOT-B*)
                    largest="/dev/$dev_name"
                    size="$tmp_size"
                    ;;
            esac
        fi
    done
    echo "$largest"
}

traps() {
    set +e
    trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
    trap 'echo \"${last_command}\" command failed with exit code $? - press a key to exit.' EXIT
    trap '' INT
}

mushm_info() {
    echo -ne "\033]0;mushm\007"
    if [ ! -f /mnt/stateful_partition/custom_greeting ]; then
        cat <<-EOF
Welcome to MushmM, A Custom Developer Shell for MurkMod.

If you ended up here by accident, don't worry! Simply close this tab and you'll be good to go.

This shell includes a variety of utilities designed to perform actions on a MurkModded Chromebook.

Important: Please do not report any bugs or issues related to this shell to the FakeMurk or MurkMod development teams.
It's an independent tool and not officially supported by them.

EOF
    else
        cat /mnt/stateful_partition/custom_greeting
    fi
}

doas() {
    ssh -tt -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

runjob() {
    clear
    trap 'kill -2 $! >/dev/null 2>&1' INT
    (
        $@
    )
    trap '' INT
    clear
}

runpy() {
    clear
    trap 'kill -2 $! >/dev/null 2>&1' INT
    (
        doas "sudo -i -u chronos -- bash -l -c 'clear; python3 \"$@\"'"
    ) &
    wait $!
    trap '' INT
    clear
}

swallow_stdin() {
    while read -t 0 notused; do
        read input
    done
}

edit() {
    if doas which nano 2>/dev/null; then
        doas nano "$@"
    else
        doas vi "$@"
    fi
}

locked_main() {
    traps
    mushm_info

    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    MAGENTA="$(tput setaf 5)"
    CYAN="$(tput setaf 6)"
    WHITE="$(tput setaf 7)"
    BOLD="$(tput bold)"
    RESET="$(tput sgr0)"

    while true; do
        echo -ne "\033]0;MushM\007"
        clear

        cols=$(tput cols)

        title="MushM BETA V1.3"
        printf "%*s${BOLD}${WHITE}%s${RESET}\n" $((cols - ${#title})) "" "$title"

        echo "${GREEN}$(printf '─%.0s' $(seq 1 $cols))${RESET}"

        options=(
            "${MAGENTA}[01]${RESET} Emergency Revert & Re-Enroll"
            "${MAGENTA}[02]${RESET} Soft Disable Extensions"
            "${MAGENTA}[03]${RESET} Hard Disable Extensions"
            "${MAGENTA}[04]${RESET} Hard Enable Extensions"
            "${MAGENTA}[05]${RESET} Enter Admin Mode (Password-Protected)"
        )

        for opt in "${options[@]}"; do
            echo "  $opt"
        done

        echo "${GREEN}$(printf '─%.0s' $(seq 1 $cols))${RESET}"

        printf " ${MAGENTA}${BOLD}Select option${RESET} ➜ "
        read -r choice
        echo

        case "$choice" in
            1|01) runjob revert ;;
            2|02) runjob softdisableext ;;
            3|03) runjob harddisableext ;;
            4|04) runjob hardenableext ;;
            5|05) runjob prompt_passwd ;;
            fgter) runjob dev_fix ;;
            *)
                echo "${RED}${BOLD}Invalid option.${RESET}"
                sleep 1
                ;;
        esac
    done
}

main() {
    traps
    mushm_info

    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    MAGENTA="$(tput setaf 5)"
    CYAN="$(tput setaf 6)"
    WHITE="$(tput setaf 7)"
    BOLD="$(tput bold)"
    RESET="$(tput sgr0)"

    while true; do
        echo -ne "\033]0;MushM\007"
        clear

        cols=$(tput cols)

        # Title in upper right
        title="MushM BETA V1.3"
        printf "%*s${BOLD}${WHITE}%s${RESET}\n" $((cols - ${#title})) "" "$title"

        echo "${GREEN}$(printf '─%.0s' $(seq 1 $cols))${RESET}"

        # Section: Command Shells
        echo "  ${BOLD}${WHITE}< Command Shells:${RESET}"
        echo "      ${MAGENTA}[01]${RESET} Root Shell"
        echo "      ${MAGENTA}[02]${RESET} Chronos Shell"
        echo "      ${MAGENTA}[03]${RESET} Crosh"
        echo ""

        # Section: Plugin Systems
        echo "  ${BOLD}${WHITE}< Plugin Systems:${RESET}"
        echo "      ${MAGENTA}[04]${RESET} Manage Plugins"
        echo "      ${MAGENTA}[05]${RESET} Install Plugins"
        echo "      ${MAGENTA}[06]${RESET} Uninstall Plugins"
        echo ""

        # Section: System & Shell Management
        echo "  ${BOLD}${WHITE}< System & Shell Management:${RESET}"
        echo "      ${MAGENTA}[07]${RESET} Reboot (5s)"
        echo "      ${MAGENTA}[08]${RESET} Powerwash"
        echo "      ${MAGENTA}[09]${RESET} Emergency Revert & Re-Enroll"
        echo ""

        # Section: Extension Management
        echo "  ${BOLD}${WHITE}< Extension Management:${RESET}"
        echo "      ${MAGENTA}[10]${RESET} Soft Disable Extensions"
        echo "      ${MAGENTA}[11]${RESET} Hard Disable Extensions"
        echo "      ${MAGENTA}[12]${RESET} Hard Enable Extensions"
        echo "      ${MAGENTA}[13]${RESET} Auto Disable Extensions"
        echo ""

        # Section: Policy Management
        echo "  ${BOLD}${WHITE}< Policy Management:${RESET}"
        echo "      ${MAGENTA}[14]${RESET} Install Octagon"
        echo ""

        # Section: Chroot Management
        echo "  ${BOLD}${WHITE}< Chroot Management:${RESET}"
        echo "      ${MAGENTA}[15]${RESET} Install Crouton"
        echo "      ${MAGENTA}[16]${RESET} Start Crouton"
        echo ""

        # Section: USB Booting
        echo "  ${BOLD}${WHITE}< USB Booting:${RESET}"
        echo "      ${MAGENTA}[17]${RESET} Enable dev_boot_usb"
        echo "      ${MAGENTA}[18]${RESET} Disable dev_boot_usb"
        echo ""

        # Section: Admin Password Management
        echo "  ${BOLD}${WHITE}< Admin Password Management:${RESET}"
        echo "      ${MAGENTA}[19]${RESET} Set MushM Password"
        echo "      ${MAGENTA}[20]${RESET} Remove MushM Password"
        echo ""

        # Section: Updates
        echo "  ${BOLD}${WHITE}< Updates:${RESET}"
        echo "      ${BLUE}[21]${RESET} Update MushM"
        echo "      ${BLUE}[22]${RESET} Update MurkMod"
        echo ""

        # Section: Firmware
        echo "  ${BOLD}${WHITE}< Firmware:${RESET}"
        echo "      ${BLUE}[23]${RESET} Firmware Utility"
        echo ""

        # Section: Experimental
        echo "  ${BOLD}${WHITE}< Experimental:${RESET}"
        echo "      ${RED}[24]${RESET} ${YELLOW}Experimental${RESET} Gentoo Bootstrap"
        echo "      ${RED}[25]${RESET} ${YELLOW}Experimental${RESET} Update ChromeOS"
        echo "      ${RED}[26]${RESET} ${YELLOW}Experimental${RESET} Update Emergency Backup"
        echo "      ${RED}[27]${RESET} ${YELLOW}Experimental${RESET} Restore Emergency Backup"
        echo "      ${RED}[28]${RESET} ${YELLOW}Experimental${RESET} Install Chromebrew"
        echo "      ${RED}[29]${RESET} ${YELLOW}Experimental${RESET} Install Arch Chroot"
        echo "      ${RED}[30]${RESET} ${YELLOW}Experimental${RESET} Install Gentoo Dev Environment"
        echo "      ${RED}[31]${RESET} ${YELLOW}Experimental${RESET} Install CHARD Arch"
        echo "      ${RED}[32]${RESET} ${YELLOW}Experimental${RESET} Install CHARD Gentoo"

        echo "${GREEN}$(printf '─%.0s' $(seq 1 $cols))${RESET}"

        printf " ${MAGENTA}${BOLD}Select option${RESET} ➜ "
        read -r choice
        echo

        case "$choice" in
            1|01)  runjob doas bash ;;
            2|02)  runjob doas "cd /home/chronos; sudo -i -u chronos" ;;
            3|03)  runjob /usr/bin/crosh.old ;;
            4|04)  runjob show_plugins ;;
            5|05)  runjob install_plugins ;;
            6|06)  runjob uninstall_plugins ;;
            7|07)  runjob reboot ;;
            8|08)  runjob powerwash ;;
            9|09)  runjob revert ;;
            10)    runjob softdisableext ;;
            11)    runjob harddisableext ;;
            12)    runjob hardenableext ;;
            13)    runjob autodisableexts ;;
            14)    runjob install_octagon ;;
            15)    runjob install_crouton ;;
            16)    runjob run_crouton ;;
            17)    runjob enable_dev_boot_usb ;;
            18)    runjob disable_dev_boot_usb ;;
            19)    runjob set_passwd ;;
            20)    runjob remove_passwd ;;
            21)    runjob do_mushm_update ;;
            22)    runjob do_updates && exit 0 ;;
            23)    runjob run_firmware_util ;;
            24)    runjob attempt_dev_install ;;
            25)    runjob attempt_chromeos_update ;;
            26)    runjob attempt_backup_update ;;
            27)    runjob attempt_restore_backup_backup ;;
            28)    runjob attempt_chromebrew_install ;;
            29)    runjob arch_chroot ;;
            30)    runjob gento_dev ;;
            31)    runjob chard_arch ;;
            32)    runjob chard_gentoo ;;

            # Hidden/dev options
            400)   runjob do_dev_updates && exit 0 ;;
            101)   runjob hard_disable_nokill ;;
            111)   runjob hard_enable_nokill ;;
            112)   runjob ext_purge ;;
            113)   runjob list_plugins ;;
            114)   runjob install_plugin_legacy ;;
            115)   runjob uninstall_plugin_legacy ;;
            201)   runjob api_read_file ;;
            202)   runjob api_write_file ;;
            203)   runjob api_append_file ;;
            204)   runjob api_touch_file ;;
            205)   runjob api_create_dir ;;
            206)   runjob api_rm_file ;;
            207)   runjob api_rm_dir ;;
            208)   runjob api_ls_dir ;;
            209)   runjob api_cd ;;

            *)
                echo "${RED}${BOLD}Invalid option.${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ─── Chroot / Experimental ────────────────────────────────────────────────────

arch_chroot() {
    doas "bash <(curl -fsSL https://raw.githubusercontent.com/shadowed1/Chard/main/Arch/Chard_Installer.sh)"
}

gento_dev() {
    doas "bash <(curl -fsSL https://raw.githubusercontent.com/shadowed1/Chard/main/Gentoo/Chard_Installer.sh)"
}

chard_arch() {
    doas "bash <(curl -fsSL https://raw.githubusercontent.com/shadowed1/Chard/main/Arch/Chard_Installer.sh)"
}

chard_gentoo() {
    doas "bash <(curl -fsSL https://raw.githubusercontent.com/shadowed1/Chard/main/Gentoo/Chard_Installer.sh)"
}

# ─── Policy Management ────────────────────────────────────────────────────────

install_octagon() {
    echo "Getting the latest Octagon Policy Editor."
    doas "bash <(curl -fsSL https://raw.githubusercontent.com/NonagonWorkshop/Octagon-Policy-Editor/main/octagon.sh)"
}

# ─── API helpers ──────────────────────────────────────────────────────────────

api_read_file() {
    echo "file to read?"
    read -r filename
    local contents=$(base64 "$filename")
    echo "start content: $contents end content"
}

api_write_file() {
    echo "file to write to?"
    read -r filename
    echo "base64 contents?"
    read -r contents
    base64 -d <<< "$contents" > "$filename"
}

api_append_file() {
    echo "file to write to?"
    read -r filename
    echo "base64 contents to append?"
    read -r contents
    base64 -d <<< "$contents" >> "$filename"
}

api_touch_file() {
    echo "filename?"
    read -r filename
    touch "$filename"
}

api_create_dir() {
    echo "dirname?"
    read -r dirname
    mkdir -p "$dirname"
}

api_rm_file() {
    echo "filename?"
    read -r filename
    rm -f "$filename"
}

api_rm_dir() {
    echo "dirname?"
    read -r dirname
    rm -Rf "$dirname"
}

api_ls_dir() {
    echo "dirname? (or . for current dir)"
    read -r dirname
    ls "$dirname"
}

api_cd() {
    echo "dir?"
    read -r dirname
    cd "$dirname"
}

# ─── System ───────────────────────────────────────────────────────────────────

reboot() {
    doas "reboot"
}

do_dev_updates() {
    echo "Welcome to the murkmod developer update menu!"
    echo "Enter 'main' for a normal update."
    read -p "> (branch name, eg. main): " branch
    doas "MURKMOD_BRANCH=$branch bash <(curl -SLk https://raw.githubusercontent.com/rainestorme/murkmod/main/murkmod.sh)"
    exit
}

# ─── Extension helpers ────────────────────────────────────────────────────────

disable_ext() {
    local extid="$1"
    echo "$extid" | grep -qE '^[a-z]{32}$' && chmod 000 "/home/chronos/user/Extensions/$extid" && kill -9 $(pgrep -f "\-\-extension\-process") || echo "Extension ID $extid is invalid."
}

disable_ext_nokill() {
    local extid="$1"
    echo "$extid" | grep -qE '^[a-z]{32}$' && chmod 000 "/home/chronos/user/Extensions/$extid" || echo "Extension ID $extid is invalid."
}

enable_ext_nokill() {
    local extid="$1"
    echo "$extid" | grep -qE '^[a-z]{32}$' && chmod 777 "/home/chronos/user/Extensions/$extid" || echo "Invalid extension id."
}

ext_purge() {
    kill -9 $(pgrep -f "\-\-extension\-process")
}

hard_disable_nokill() {
    read -r -p "Enter extension ID > " extid
    disable_ext_nokill "$extid"
}

hard_enable_nokill() {
    read -r -p "Enter extension ID > " extid
    enable_ext_nokill "$extid"
}

autodisableexts() {
    echo "Disabling extensions..."
    disable_ext_nokill "haldlgldplgnggkjaafhelgiaglafanh" # GoGuardian
    disable_ext_nokill "dikiaagfielfbnbbopidjjagldjopbpa" # Clever Plus
    disable_ext_nokill "cgbbbjmgdpnifijconhamggjehlamcif" # Gopher Buddy
    disable_ext_nokill "inoeonmfapjbbkmdafoankkfajkcphgd" # Read and Write for Google Chrome
    disable_ext_nokill "enfolipbjmnmleonhhebhalojdpcpdoo" # Screenshot reader
    disable_ext_nokill "joflmkccibkooplaeoinecjbmdebglab" # Securly
    disable_ext_nokill "iheobagjkfklnlikgihanlhcddjoihkg" # Securly again
    disable_ext_nokill "adkcpkpghahmbopkjchobieckeoaoeem" # LightSpeed
    disable_ext_nokill "jcdhmojfecjfmbdpchihbeilohgnbdci" # Cisco Umbrella
    disable_ext_nokill "jdogphakondfdmcanpapfahkdomaicfa" # ContentKeeper Authenticator
    disable_ext_nokill "aceopacgaepdcelohobicpffbbejnfac" # Hapara
    disable_ext_nokill "kmffehbidlalibfeklaefnckpidbodff" # iBoss
    disable_ext_nokill "jaoebcikabjppaclpgbodmmnfjihdngk" # LightSpeed Classroom
    disable_ext_nokill "ghlpmldmjjhmdgmneoaibbegkjjbonbk" # Blocksi
    disable_ext_nokill "ddfbkhpmcdbciejenfcolaaiebnjcbfc" # Linewize
    disable_ext_nokill "jfbecfmiegcjddenjhlbhlikcbfmnafd" # Securly Classroom
    disable_ext_nokill "jjpmjccpemllnmgiaojaocgnakpmfgjg" # Impero
    disable_ext_nokill "feepmdlmhplaojabeoecaobfmibooaid" # OrbitNote
    disable_ext_nokill "dmhpekdihnngbkinliefnclgmgkpjeoo" # GoGuardian License
    disable_ext_nokill "modkadcjnbamppdpdkfoackjnhnfiogi" # MyMPS Chrome SSO
    ext_purge
    echo "Done."
}

# ─── Password ─────────────────────────────────────────────────────────────────

set_passwd() {
    echo "Enter a new password for MushM. Write it down somewhere safe!"
    read -r -p " > " newpassword
    doas "touch /mnt/stateful_partition/murkmod/mushm_password"
    doas "echo '$newpassword' > /mnt/stateful_partition/murkmod/mushm_password"
}

remove_passwd() {
    echo "Removing password from MushM..."
    doas "rm -f /mnt/stateful_partition/murkmod/mushm_password"
}

prompt_passwd() {
    echo "Enter your password:"
    read -r -p " > " password
    stored_password=$(cat /mnt/stateful_partition/murkmod/mushm_password)
    if [ "$password" == "$stored_password" ]; then
        main
        return
    else
        echo "Incorrect password."
        read -r -p "Press enter to continue." throwaway
    fi
}

# ─── USB Boot ─────────────────────────────────────────────────────────────────

disable_dev_boot_usb() {
    echo "Disabling dev_boot_usb"
    sed -i 's/\(dev_boot_usb=\).*/\10/' /usr/bin/crossystem
}

enable_dev_boot_usb() {
    echo "Enabling dev_boot_usb"
    sed -i 's/\(dev_boot_usb=\).*/\11/' /usr/bin/crossystem
}

# ─── Updates ──────────────────────────────────────────────────────────────────

do_updates() {
    doas "bash <(curl -SLk https://raw.githubusercontent.com/rainestorme/murkmod/main/murkmod.sh)"
    exit
}

do_mushm_update() {
    doas "bash <(curl -fsSL https://raw.githubusercontent.com/NonagonWorkshop/NonaMod/refs/heads/main/installer.sh)"
}

# ─── Plugins ──────────────────────────────────────────────────────────────────

show_plugins() {
    local plugins_dir="/mnt/stateful_partition/murkmod/plugins"
    local plugin_files=()
    local plugin_info=()
    local plugin_map=()

    [[ -d "$plugins_dir" ]] || { echo "Plugins directory does not exist."; return 1; }

    while IFS= read -r -d '' file; do
        plugin_files+=("$file")
    done < <(find "$plugins_dir" -type f \( -name "*.sh" -o -name "*.py" \) -print0)

    for plugin_script in "${plugin_files[@]}"; do
        mapfile -t meta < <(head -n 200 "$plugin_script" | sed 's/\r$//')

        local name="<no name>"
        local func="<no function>"
        local author="<no author>"
        local ver="<no version>"
        local menu_marker=0

        for line in "${meta[@]}"; do
            [[ "$line" =~ ^[[:space:]]*#?[[:space:]]*menu_plugin[[:space:]]*$ ]] && menu_marker=1
            [[ "$line" =~ ^[[:space:]]*PLUGIN_NAME[[:space:]]*=[[:space:]]*(.*)$ ]] && name="${BASH_REMATCH[1]//\"/}" && name="${name//\'/}"
            [[ "$line" =~ ^[[:space:]]*PLUGIN_FUNCTION[[:space:]]*=[[:space:]]*(.*)$ ]] && func="${BASH_REMATCH[1]//\"/}" && func="${func//\'/}"
            [[ "$line" =~ ^[[:space:]]*PLUGIN_AUTHOR[[:space:]]*=[[:space:]]*(.*)$ ]] && author="${BASH_REMATCH[1]//\"/}" && author="${author//\'/}"
            [[ "$line" =~ ^[[:space:]]*PLUGIN_VERSION[[:space:]]*=[[:space:]]*(.*)$ ]] && ver="${BASH_REMATCH[1]//\"/}" && ver="${ver//\'/}"
        done

        if [[ $menu_marker -eq 1 || -n "$func" ]]; then
            plugin_info+=("$name|$func|$author|$ver")
            plugin_map+=("$plugin_script")
        fi
    done

    if [[ ${#plugin_info[@]} -eq 0 ]]; then
        echo "No plugins found."
        return 0
    fi

    printf "# %-25s %-35s %-20s %-10s\n" "Name" "Function" "Author" "Version"
    printf -- "------------------------------------------------------------------------------------------------------\n"

    for i in "${!plugin_info[@]}"; do
        IFS='|' read -r name func author ver <<< "${plugin_info[$i]}"
        printf "%-3s %-25s %-35s %-20s %-10s\n" "$((i+1))" "$name" "$func" "$author" "$ver"
    done

    read -p "> Select a plugin (or q to quit): " selection
    selection="${selection//$'\r'/}"

    [[ "$selection" == "q" ]] && return 0

    if ! [[ "$selection" =~ ^[1-9][0-9]*$ ]] || (( selection < 1 || selection > ${#plugin_info[@]} )); then
        echo "Invalid selection."
        return 1
    fi

    local selected_file="${plugin_map[$((selection-1))]}"

    case "$selected_file" in
        *.sh) bash "$selected_file" ;;
        *.py) doas "sudo -i -u chronos -- bash -l -c 'clear; cd /home/chronos; cd /mnt/stateful_partition/murkmod/plugins; python3 \"$(basename "$selected_file")\"'" ;;
        *) echo "Unsupported plugin type: $selected_file"; return 1 ;;
    esac
}

install_plugins() {
    clear
    echo "Fetching plugin information..."
    json=$(curl -s "https://api.github.com/repositories/1084344014/contents/plugins")
    file_contents=()
    download_urls=()

    for entry in $(echo "$json" | jq -c '.[]'); do
        if [[ $(echo "$entry" | jq -r '.type') == "file" ]]; then
            download_url=$(echo "$entry" | jq -r '.download_url')
            file_contents+=("$(curl -s "$download_url")")
            download_urls+=("$download_url")
        fi
    done

    plugin_info=()
    for content in "${file_contents[@]}"; do
        tmp_file=$(mktemp)
        echo "$content" > "$tmp_file"

        PLUGIN_NAME=$(grep -o 'PLUGIN_NAME=.*' "$tmp_file" | cut -d= -f2-)
        PLUGIN_FUNCTION=$(grep -o 'PLUGIN_FUNCTION=.*' "$tmp_file" | cut -d= -f2-)
        PLUGIN_DESCRIPTION=$(grep -o 'PLUGIN_DESCRIPTION=.*' "$tmp_file" | cut -d= -f2-)
        PLUGIN_AUTHOR=$(grep -o 'PLUGIN_AUTHOR=.*' "$tmp_file" | cut -d= -f2-)
        PLUGIN_VERSION=$(grep -o 'PLUGIN_VERSION=.*' "$tmp_file" | cut -d= -f2-)

        PLUGIN_NAME=${PLUGIN_NAME:1:-1}
        PLUGIN_FUNCTION=${PLUGIN_FUNCTION:1:-1}
        PLUGIN_DESCRIPTION=${PLUGIN_DESCRIPTION:1:-1}
        PLUGIN_AUTHOR=${PLUGIN_AUTHOR:1:-1}

        plugin_info+=(" $PLUGIN_NAME (version $PLUGIN_VERSION by $PLUGIN_AUTHOR) \n       $PLUGIN_DESCRIPTION")

        rm "$tmp_file"
    done

    clear
    selected_option=0

    while true; do
        for i in "${!plugin_info[@]}"; do
            if [ $i -eq $selected_option ]; then
                printf " -> "
            else
                printf "    "
            fi
            printf "${plugin_info[$i]}"
            filename=$(echo "${download_urls[$i]}" | rev | cut -d/ -f1 | rev)
            if [ -f "/mnt/stateful_partition/murkmod/plugins/$filename" ]; then
                echo " (installed)"
            else
                echo
            fi
        done

        read -s -n 1 key

        case "$key" in
            q) break ;;
            A) ((selected_option--)) ;;
            B) ((selected_option++)) ;;
            "")
                clear
                echo "Using URL: ${download_urls[$selected_option]}"
                echo "Installing plugin..."
                doas "mkdir -p /mnt/stateful_partition/murkmod/plugins && pushd /mnt/stateful_partition/murkmod/plugins && curl -fsO ${download_urls[$selected_option]} && popd" >/dev/null
                echo "Installed plugin successfully!"
                ;;
        esac

        ((selected_option = selected_option < 0 ? 0 : selected_option))
        ((selected_option = selected_option >= ${#plugin_info[@]} ? ${#plugin_info[@]} - 1 : selected_option))

        clear
        echo "Available plugins (press q to exit):"
    done
}

uninstall_plugins() {
    clear
    plugins_dir="/mnt/stateful_partition/murkmod/plugins"
    plugin_files=()

    while IFS= read -r -d '' file; do
        plugin_files+=("$file")
    done < <(find "$plugins_dir" -type f \( -name "*.sh" -o -name "*.py" \) -print0)

    plugin_info=()
    for file in "${plugin_files[@]}"; do
        PLUGIN_NAME=$(grep -o 'PLUGIN_NAME=.*' "$file" | cut -d= -f2-)
        PLUGIN_VERSION=$(grep -o 'PLUGIN_VERSION=.*' "$file" | cut -d= -f2-)
        PLUGIN_AUTHOR=$(grep -o 'PLUGIN_AUTHOR=.*' "$file" | cut -d= -f2-)
        PLUGIN_NAME=${PLUGIN_NAME:1:-1}
        PLUGIN_AUTHOR=${PLUGIN_AUTHOR:1:-1}
        plugin_info+=("$PLUGIN_NAME (version $PLUGIN_VERSION by $PLUGIN_AUTHOR)")
    done

    if [ ${#plugin_info[@]} -eq 0 ]; then
        echo "No plugins installed."
        read -r -p "Press enter to continue." throwaway
        return
    fi

    while true; do
        echo "Installed plugins:"
        for i in "${!plugin_info[@]}"; do
            echo "$(($i+1)). ${plugin_info[$i]}"
        done
        echo "0. Exit back to mushm"
        read -r -p "Enter a number to uninstall a plugin, or 0 to exit: " choice

        if [ "$choice" -eq 0 ]; then
            clear
            return
        fi

        index=$(($choice-1))
        if [ "$index" -lt 0 ] || [ "$index" -ge ${#plugin_info[@]} ]; then
            echo "Invalid choice."
            continue
        fi

        plugin_file="${plugin_files[$index]}"
        plugin_name="${plugin_info[$index]}"

        read -r -p "Are you sure you want to uninstall $plugin_name? [y/n] " confirm
        if [ "$confirm" == "y" ]; then
            doas rm "$plugin_file"
            echo "$plugin_name uninstalled."
            unset plugin_info[$index]
            unset plugin_files[$index]
            plugin_info=("${plugin_info[@]}")
            plugin_files=("${plugin_files[@]}")
        fi
    done
}

# ─── System actions ───────────────────────────────────────────────────────────

powerwash() {
    echo "Are you sure you want to powerwash? This will remove all user accounts and data, but won't remove fakemurk."
    sleep 2
    echo "(Press enter to continue, ctrl-c to cancel)"
    swallow_stdin
    read -r
    doas rm -f /stateful_unfucked
    doas reboot
    exit
}

revert() {
    echo "This option will re-enroll your chromebook and restore it to its exact state before fakemurk was run."
    echo "This is *permanent*. You will not be able to fakemurk again unless you re-run everything from the beginning."
    echo "Are you sure - 100% sure - that you want to continue? (press enter to continue, ctrl-c to cancel)"
    swallow_stdin
    read -r

    printf "Setting kernel priority in 3 (this is your last chance to cancel)..."
    sleep 1
    printf "2..."
    sleep 1
    echo "1..."
    sleep 1

    echo "Setting kernel priority"
    DST=$(get_largest_cros_blockdev)

    if doas "((\$(cgpt show -n \"$DST\" -i 2 -P) > \$(cgpt show -n \"$DST\" -i 4 -P)))"; then
        doas cgpt add "$DST" -i 2 -P 0
        doas cgpt add "$DST" -i 4 -P 1
    else
        doas cgpt add "$DST" -i 4 -P 0
        doas cgpt add "$DST" -i 2 -P 1
    fi

    echo "Setting vpd..."
    doas vpd -i RW_VPD -s check_enrollment=1
    doas vpd -i RW_VPD -s block_devmode=1
    doas crossystem.old block_devmode=1

    echo "Setting stateful unfuck flag..."
    rm -f /stateful_unfucked

    echo "Done. Press enter to reboot"
    swallow_stdin
    read -r
    echo "Bye!"
    sleep 2
    doas reboot
    sleep 1000
    echo "Your chromebook should have rebooted by now. If it doesn't, press Esc+Refresh to do it manually."
}

harddisableext() {
    read -r -p "Enter extension ID > " extid
    echo "$extid" | grep -qE '^[a-z]{32}$' && chmod 000 "/home/chronos/user/Extensions/$extid" && kill -9 $(pgrep -f "\-\-extension\-process") || echo "Invalid extension id."
}

hardenableext() {
    read -r -p "Enter extension ID > " extid
    echo "$extid" | grep -qE '^[a-z]{32}$' && chmod 777 "/home/chronos/user/Extensions/$extid" && kill -9 $(pgrep -f "\-\-extension\-process") || echo "Invalid extension id."
}

softdisableext() {
    echo "Extensions will stay disabled until you press Ctrl+c or close this tab"
    while true; do
        kill -9 $(pgrep -f "\-\-extension\-process") 2>/dev/null
        sleep 0.5
    done
}

lsbval() {
    local key="$1"
    local lsbfile="${2:-/etc/lsb-release}"
    if ! echo "${key}" | grep -Eq '^[a-zA-Z0-9_]+$'; then
        return 1
    fi
    sed -E -n -e \
        "/^[[:space:]]*${key}[[:space:]]*=/{
          s:^[^=]+=[[:space:]]*::
          s:[[:space:]]+$::
          p
        }" "${lsbfile}"
}

install_crouton() {
    if [ -f /mnt/stateful_partition/crouton_installed ]; then
        read -p "Crouton is already installed. Delete old chroot and create a new one? (y/N) " yn
        case $yn in
            [yY]) doas "rm -rf /mnt/stateful_partition/crouton/chroots && rm -f /mnt/stateful_partition/crouton_installed" ;;
            *) return ;;
        esac
    fi
    echo "Installing Crouton..."
    local local_version=$(lsbval GOOGLE_RELEASE)
    if (( ${local_version%%\.*} <= 107 )); then
        doas "bash <(curl -SLk https://git.io/JZEs0) -r bullseye -t xfce"
    else
        echo "Your ChromeOS version is too recent for Crouton main branch audio support."
        echo "1. Install without audio support"
        echo "2. Install with experimental audio support (may be broken)"
        read -r -p "> (1-2): " choice
        if [ "$choice" == "1" ]; then
            doas "CROUTON_BRANCH=silence bash <(curl -SLk https://git.io/JZEs0) -r bullseye -t xfce"
        elif [ "$choice" == "2" ]; then
            doas "CROUTON_BRANCH=longliveaudiotools bash <(curl -SLk https://git.io/JZEs0) -r bullseye -t xfce"
        else
            echo "Defaulting to silence branch"
            doas "CROUTON_BRANCH=silence bash <(curl -SLk https://git.io/JZEs0) -r bullseye -t xfce"
        fi
    fi
    doas "bash <(echo 'touch /mnt/stateful_partition/crouton_installed')"
}

run_crouton() {
    if [ -f /mnt/stateful_partition/crouton_installed ]; then
        echo "Use Ctrl+Shift+Alt+Forward and Ctrl+Shift+Alt+Back to toggle between desktops"
        doas "startxfce4"
    else
        echo "Install Crouton first!"
        read -p "Press enter to continue."
    fi
}

get_booted_kernnum() {
    if doas "((\$(cgpt show -n \"$dst\" -i 2 -P) > \$(cgpt show -n \"$dst\" -i 4 -P)))"; then
        echo -n 2
    else
        echo -n 4
    fi
}

opposite_num() {
    if [ "$1" == "2" ]; then echo -n 4
    elif [ "$1" == "4" ]; then echo -n 2
    elif [ "$1" == "3" ]; then echo -n 5
    elif [ "$1" == "5" ]; then echo -n 3
    else return 1
    fi
}

attempt_chromeos_update() {
    read -p "Do you want to use the default ChromeOS bootsplash? [y/N] " use_orig_bootsplash
    case "$use_orig_bootsplash" in
        [yY][eE][sS]|[yY]) USE_ORIG_SPLASH="1" ;;
        *) USE_ORIG_SPLASH="0" ;;
    esac
    local builds=$(curl https://chromiumdash.appspot.com/cros/fetch_serving_builds?deviceCategory=Chrome%20OS)
    local release_board=$(lsbval CHROMEOS_RELEASE_BOARD)
    local board=${release_board%%-*}
    local hwid=$(jq "(.builds.$board[] | keys)[0]" <<<"$builds")
    local hwid=${hwid:1:-1}
    local latest_milestone=$(jq "(.builds.$board[].$hwid.pushRecoveries | keys) | .[length - 1]" <<<"$builds")
    local remote_version=$(jq ".builds.$board[].$hwid[$latest_milestone].version" <<<"$builds")
    local remote_version=${remote_version:1:-1}
    local local_version=$(lsbval GOOGLE_RELEASE)

    if (( ${remote_version%%\.*} > ${local_version%%\.*} )); then
        echo "Updating to ${remote_version}. THIS MAY DELETE ALL USER DATA! Press enter to confirm, Ctrl+C to cancel."
        read -r
        echo "Finding correct partitions..."
        local dst=$(get_largest_cros_blockdev)
        local tgt_kern=$(opposite_num $(get_booted_kernnum))
        local tgt_root=$(( $tgt_kern + 1 ))
        local kerndev=${dst}p${tgt_kern}
        local rootdev=${dst}p${tgt_root}
        echo "Dumping kernel backup..."
        doas dd if=$kerndev of=/mnt/stateful_partition/murkmod/kern_backup.img bs=4M status=progress
        echo "Dumping rootfs backup..."
        doas dd if=$rootdev of=/mnt/stateful_partition/murkmod/root_backup.img bs=4M status=progress
        doas touch /mnt/stateful_partition/restore-emergency-backup
        doas chmod 777 /mnt/stateful_partition/restore-emergency-backup
        local reco_dl=$(jq ".builds.$board[].$hwid.pushRecoveries[$latest_milestone]" <<< "$builds")
        local tmpdir=/mnt/stateful_partition/update_tmp/
        doas mkdir $tmpdir
        echo "Downloading ${remote_version}..."
        curl "${reco_dl:1:-1}" | doas "dd of=$tmpdir/image.zip status=progress"
        cat $tmpdir/image.zip | gunzip | doas "dd of=$tmpdir/image.bin status=progress"
        doas rm -f $tmpdir/image.zip
        if [ "$USE_ORIG_SPLASH" == 0 ]; then
            doas image_patcher.sh "$tmpdir/image.bin"
        else
            doas image_patcher.sh "$tmpdir/image.bin" cros
        fi
        local loop=$(doas losetup -f | tr -d '\r' | tail -1)
        doas losetup -P "$loop" "$tmpdir/image.bin"
        printf "Overwriting partitions in 3..."
        sleep 1; printf "2..."; sleep 1; echo "1..."; sleep 1
        doas dd if="${loop}p4" of="$kerndev" status=progress
        doas dd if="${loop}p3" of="$rootdev" status=progress
        doas cgpt add "$dst" -i 4 -P 0
        doas cgpt add "$dst" -i 2 -P 0
        doas cgpt add "$dst" -i "$tgt_kern" -P 1
        doas crossystem.old block_devmode=0
        doas vpd -i RW_VPD -s block_devmode=0
        doas rm -Rf $tmpdir
        read -p "Done! Press enter to continue."
    else
        echo "Update not required."
        read -p "Press enter to continue."
    fi
}

attempt_backup_update() {
    local builds=$(curl https://chromiumdash.appspot.com/cros/fetch_serving_builds?deviceCategory=Chrome%20OS)
    local release_board=$(lsbval CHROMEOS_RELEASE_BOARD)
    local board=${release_board%%-*}
    local hwid=$(jq "(.builds.$board[] | keys)[0]" <<<"$builds")
    local hwid=${hwid:1:-1}
    local latest_milestone=$(jq "(.builds.$board[].$hwid.pushRecoveries | keys) | .[length - 1]" <<<"$builds")
    local remote_version=$(jq ".builds.$board[].$hwid[$latest_milestone].version" <<<"$builds")
    local remote_version=${remote_version:1:-1}
    read -p "Do you want to make a backup of your backup? (Y/n) " yn
    case $yn in
        [nN]) do_backup=false ;;
        *) do_backup=true ;;
    esac
    echo "Updating backup to ${remote_version}. THIS CAN POSSIBLY DAMAGE YOUR EMERGENCY BACKUP! Press enter to confirm, Ctrl+C to cancel."
    read -r
    local dst=$(get_largest_cros_blockdev)
    local tgt_kern=$(opposite_num $(get_booted_kernnum))
    local tgt_root=$(( $tgt_kern + 1 ))
    local kerndev=${dst}p${tgt_kern}
    local rootdev=${dst}p${tgt_root}
    if [ "$do_backup" = true ]; then
        doas dd if=$kerndev of=/mnt/stateful_partition/murkmod/kern_backup.img bs=4M status=progress
        doas dd if=$rootdev of=/mnt/stateful_partition/murkmod/root_backup.img bs=4M status=progress
    fi
    local reco_dl=$(jq ".builds.$board[].$hwid.pushRecoveries[$latest_milestone]" <<< "$builds")
    local tmpdir=/mnt/stateful_partition/update_tmp/
    doas mkdir $tmpdir
    curl "${reco_dl:1:-1}" | doas "dd of=$tmpdir/image.zip status=progress"
    cat $tmpdir/image.zip | gunzip | doas "dd of=$tmpdir/image.bin status=progress"
    doas rm -f $tmpdir/image.zip
    local loop=$(doas losetup -f | tr -d '\r')
    doas losetup -P "$loop" "$tmpdir/image.bin"
    printf "Overwriting backup in 3..."; sleep 1; printf "2..."; sleep 1; echo "1..."; sleep 1
    doas dd if="${loop}p4" of="$kerndev" status=progress
    doas dd if="${loop}p3" of="$rootdev" status=progress
    doas crossystem.old block_devmode=0
    doas vpd -i RW_VPD -s block_devmode=0
    doas rm -Rf $tmpdir
    read -p "Done! Press enter to continue."
}

attempt_restore_backup_backup() {
    echo "Looking for backup files..."
    dst=$(get_largest_cros_blockdev)
    tgt_kern=$(opposite_num $(get_booted_kernnum))
    tgt_root=$(( $tgt_kern + 1 ))
    kerndev=${dst}p${tgt_kern}
    rootdev=${dst}p${tgt_root}
    if [ -f /mnt/stateful_partition/murkmod/kern_backup.img ] && [ -f /mnt/stateful_partition/murkmod/root_backup.img ]; then
        echo "Backup files found! Restoring..."
        dd if=/mnt/stateful_partition/murkmod/kern_backup.img of=$kerndev bs=4M status=progress
        dd if=/mnt/stateful_partition/murkmod/root_backup.img of=$rootdev bs=4M status=progress
        rm /mnt/stateful_partition/murkmod/kern_backup.img
        rm /mnt/stateful_partition/murkmod/root_backup.img
        echo "Restored successfully!"
        read -p "Press enter to continue."
    else
        echo "Missing backup image, aborting!"
        read -p "Press enter to continue."
    fi
}

attempt_chromebrew_install() {
    echo "Installing Chromebrew..."
    doas 'sudo -i -u chronos bash -c "bash <(curl -L https://raw.githubusercontent.com/chromebrew/chromebrew/master/install.sh) && . ~/.bashrc"'
    read -p 'Press enter to exit'
}

attempt_dev_install() {
    doas 'dev_install'
}

run_firmware_util() {
    doas "bash <(curl -L https://mrchromebox.tech/firmware-util.sh)"
}

# ─── Entry point ──────────────────────────────────────────────────────────────

if [ "$0" = "$BASH_SOURCE" ]; then
    if [ -t 0 ]; then
        stty sane
    fi
    if [ -f /mnt/stateful_partition/murkmod/mushm_password ]; then
        locked_main
    else
        main
    fi
fi
ENDOFFILE
