#!/usr/bin/env bash

# Configuration & Colors

SAVE_FILE="./savegame.sav"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'


# Player Variables (Initial State)

NAME=""
LEVEL=1
XP=0
NEXT_XP=100
HP=100
MAX_HP=100
ATTACK=12
DEFENSE=4
GOLD=30
POTIONS=2
WEAPON="Rusty Dagger"
ARMOR="Cloth Tunic"
DUNGEON_FLOOR=1


# Save & Load System
save_game() {
    cat > "$SAVE_FILE" <<EOF
NAME="$NAME"
LEVEL=$LEVEL
XP=$XP
NEXT_XP=$NEXT_XP
HP=$HP
MAX_HP=$MAX_HP
ATTACK=$ATTACK
DEFENSE=$DEFENSE
GOLD=$GOLD
POTIONS=$POTIONS
WEAPON="$WEAPON"
ARMOR="$ARMOR"
DUNGEON_FLOOR=$DUNGEON_FLOOR
EOF
    echo -e "${GREEN}✔ Game saved successfully to $SAVE_FILE${NC}"
}

load_game() {
    if [ -f "$SAVE_FILE" ]; then
        # shellcheck disable=SC1090
        source "$SAVE_FILE"
        echo -e "${GREEN}✔ Welcome back, $NAME!${NC}"
        sleep 1
        return 0
    else
        echo -e "${RED}No saved game found.${NC}"
        sleep 1
        return 1
    fi
}


# Utilities & Progression

pause() {
    echo ""
    read -rp "Press [Enter] to continue..."
}

show_hp_bar() {
    local current=$1
    local maximum=$2
    local width=20
    local filled=$(( current * width / maximum ))
    [ $filled -lt 0 ] && filled=0
    local empty=$(( width - filled ))

    printf "["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d/%d HP" "$current" "$maximum"
}

level_up() {
    while [ "$XP" -ge "$NEXT_XP" ]; do
        XP=$(( XP - NEXT_XP ))
        LEVEL=$(( LEVEL + 1 ))
        NEXT_XP=$(( NEXT_XP + 50 ))
        MAX_HP=$(( MAX_HP + 20 ))
        HP=$MAX_HP
        ATTACK=$(( ATTACK + 4 ))
        DEFENSE=$(( DEFENSE + 2 ))

        echo -e "\n${YELLOW}★ YOU REACHED LEVEL $LEVEL! ★${NC}"
        echo "Max HP +20 | Attack +4 | Defense +2 (Health fully restored)"
    done
}

# Combat System

start_combat() {
    local enemy_name="$1"
    local enemy_hp="$2"
    local enemy_max_hp="$2"
    local enemy_atk="$3"
    local xp_reward="$4"
    local gold_reward="$5"

    while [ "$HP" -gt 0 ] && [ "$enemy_hp" -gt 0 ]; do
        clear
        echo -e "${RED}⚔️  COMBAT: $NAME vs $enemy_name ⚔️${NC}\n"
        echo -n "$NAME: "
        show_hp_bar "$HP" "$MAX_HP"
        echo -e " | Potions: ${GREEN}$POTIONS${NC}"

        echo -n "$enemy_name: "
        show_hp_bar "$enemy_hp" "$enemy_max_hp"
        echo -e "\n\n----------------------------------------"
        echo "1. Quick Attack (Reliable)"
        echo "2. Heavy Strike (High damage, can miss)"
        echo "3. Use Potion (+45 HP)"
        echo "4. Attempt to Flee"
        read -rp "Choose your action: " action

        echo ""
        case "$action" in
            1)
                local variance=$(( RANDOM % 5 - 2 ))
                local damage=$(( ATTACK + variance ))
                [ $damage -lt 1 ] && damage=1
                enemy_hp=$(( enemy_hp - damage ))
                echo -e "You strike with your $WEAPON and deal ${YELLOW}$damage damage${NC}."
                ;;
            2)
                local luck=$(( RANDOM % 100 ))
                if [ $luck -lt 65 ]; then
                    local damage=$(( ATTACK * 2 - 2 ))
                    enemy_hp=$(( enemy_hp - damage ))
                    echo -e "${GREEN}Critical hit!${NC} You deal ${YELLOW}$damage damage${NC}."
                else
                    echo -e "${RED}You missed your heavy strike!${NC}"
                fi
                ;;
            3)
                if [ "$POTIONS" -gt 0 ]; then
                    POTIONS=$(( POTIONS - 1 ))
                    HP=$(( HP + 45 ))
                    [ $HP -gt $MAX_HP ] && HP=$MAX_HP
                    echo -e "${GREEN}You drink a potion and recover health.${NC}"
                else
                    echo -e "${RED}No potions left! You waste a turn searching your bag.${NC}"
                fi
                ;;
            4)
                if [ $(( RANDOM % 100 )) -lt 50 ]; then
                    echo -e "${CYAN}You successfully escaped from battle.${NC}"
                    pause
                    return
                else
                    echo -e "${RED}The enemy blocked your escape!${NC}"
                fi
                ;;
            *)
                echo "You hesitated and lost your turn."
                ;;
        esac

 # Enemy turn if still alive

        if [ "$enemy_hp" -gt 0 ]; then
            local enemy_damage=$(( enemy_atk - DEFENSE + (RANDOM % 4) ))
            [ $enemy_damage -lt 1 ] && enemy_damage=1
            HP=$(( HP - enemy_damage ))
            echo -e "$enemy_name attacks you for ${RED}$enemy_damage damage${NC}."
        fi

        sleep 1.5
    done

    if [ "$HP" -le 0 ]; then
        clear
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}           YOU HAVE BEEN DEFEATED       ${NC}"
        echo -e "${RED}========================================${NC}"
        echo "You lose half your gold and wake up back at camp..."
        GOLD=$(( GOLD / 2 ))
        HP=$(( MAX_HP / 2 ))
        pause
    else
        echo -e "\n${GREEN}You defeated $enemy_name!${NC}"
        echo "Earned +$xp_reward XP and +$gold_reward Gold."
        XP=$(( XP + xp_reward ))
        GOLD=$(( GOLD + gold_reward ))
        level_up
        pause
    fi
}


# Exploration & Random Events

explore() {
    clear
    echo -e "${CYAN}🌲 Exploring Floor $DUNGEON_FLOOR...${NC}\n"
    sleep 1

    local event=$(( RANDOM % 100 ))
    local scaling=$(( DUNGEON_FLOOR * 6 ))

    if [ $event -lt 55 ]; then
        local type=$(( RANDOM % 3 ))
        case $type in
            0) start_combat "Acid Slime" $(( 35 + scaling )) $(( 7 + DUNGEON_FLOOR * 2 )) 35 15 ;;
            1) start_combat "Skeleton Guard" $(( 50 + scaling )) $(( 10 + DUNGEON_FLOOR * 2 )) 50 25 ;;
            2) start_combat "Shadow Wolf" $(( 45 + scaling )) $(( 12 + DUNGEON_FLOOR * 2 )) 45 20 ;;
        esac
    elif [ $event -lt 75 ]; then
        local found_gold=$(( 15 + RANDOM % 25 + DUNGEON_FLOOR * 5 ))
        GOLD=$(( GOLD + found_gold ))
        echo -e "${YELLOW}✨ You found an ancient treasure chest!${NC}"
        echo "You obtain $found_gold gold coins."
        pause
    elif [ $event -lt 90 ]; then
        local heal=30
        HP=$(( HP + heal ))
        [ $HP -gt $MAX_HP ] && HP=$MAX_HP
        echo -e "${GREEN}💧 You discover a crystal healing spring.${NC}"
        echo "You recover $heal HP."
        pause
    else
        local trap_damage=$(( 8 + DUNGEON_FLOOR * 2 ))
        HP=$(( HP - trap_damage ))
        [ $HP -lt 1 ] && HP=1
        echo -e "${RED}⚠️  You stepped on a spike trap!${NC}"
        echo "You lose $trap_damage HP."
        pause
    fi
}


# Shop & Camp

visit_shop() {
    while true; do
        clear
        echo -e "${YELLOW}🏪 CAMP MERCHANT${NC}"
        echo -e "Your Gold: ${YELLOW}$GOLD${NC} | Potions: ${GREEN}$POTIONS${NC}\n"
        echo "1. Buy Health Potion (20 gold)"
        echo "2. Upgrade Weapon (+5 Attack) - Cost: 50 gold"
        echo "3. Upgrade Armor (+3 Defense) - Cost: 50 gold"
        echo "4. Rest at the Inn (Full HP restore) - Cost: 15 gold"
        echo "5. Return to main menu"
        read -rp "Choose an option: " shop_op

        case "$shop_op" in
            1)
                if [ "$GOLD" -ge 20 ]; then
                    GOLD=$(( GOLD - 20 ))
                    POTIONS=$(( POTIONS + 1 ))
                    echo -e "${GREEN}You bought a health potion.${NC}"
                else
                    echo -e "${RED}Not enough gold.${NC}"
                fi
                sleep 1
                ;;
            2)
                if [ "$GOLD" -ge 50 ]; then
                    GOLD=$(( GOLD - 50 ))
                    ATTACK=$(( ATTACK + 5 ))
                    WEAPON="Forged Broadsword (+$ATTACK)"
                    echo -e "${GREEN}Your attack increased to $ATTACK!${NC}"
                else
                    echo -e "${RED}Not enough gold.${NC}"
                fi
                sleep 1
                ;;
            3)
                if [ "$GOLD" -ge 50 ]; then
                    GOLD=$(( GOLD - 50 ))
                    DEFENSE=$(( DEFENSE + 3 ))
                    ARMOR="Reinforced Chainmail (+$DEFENSE)"
                    echo -e "${GREEN}Your defense increased to $DEFENSE!${NC}"
                else
                    echo -e "${RED}Not enough gold.${NC}"
                fi
                sleep 1
                ;;
            4)
                if [ "$GOLD" -ge 15 ]; then
                    GOLD=$(( GOLD - 15 ))
                    HP=$MAX_HP
                    echo -e "${GREEN}You rested and restored all your health.${NC}"
                else
                    echo -e "${RED}Not enough gold.${NC}"
                fi
                sleep 1
                ;;
            5) break ;;
            *) echo "Invalid option."; sleep 1 ;;
        esac
    done
}

# Game Start

clear
echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}         TERMINAL QUEST - BASH RPG      ${NC}"
echo -e "${PURPLE}========================================${NC}\n"
echo "1. New Game"
echo "2. Load Game"
read -rp "Select: " start_choice

Usa el código con precaución.
if [ "$start_choice" == "2" ] && load_game; then
:
else
read -rp "Enter your hero's name: " NAME
[ -z "$NAME" ] && NAME="Adventurer"
fi



Main Game Loop


while true; do
clear
echo -e "${CYAN}========================================${NC}"
echo -e " Hero: ${YELLOW}$NAME${NC} | Level: ${GREEN}$LEVEL${NC} ($XP/$NEXT_XP XP)"
echo -n " Health: "
show_hp_bar "$HP" "$MAX_HP"
echo ""
echo -e " ATK: $ATTACK | DEF: $DEFENSE | Gold: ${YELLOW}$GOLD${NC} | Floor: $DUNGEON_FLOOR"
echo -e "${CYAN}========================================${NC}\n"
echo "1. Explore current floor"
echo "2. Challenge Floor Guardian (Advance floor)"
echo "3. Visit Shop / Inn"
echo "4. View Equipment & Inventory"
echo "5. Save Game"
echo "6. Exit"
echo ""
read -rp "What would you like to do? [1-6]: " menu
case "$menu" in
1) explore ;;
2)
boss_hp=$(( 90 + DUNGEON_FLOOR * 35 ))
boss_atk=$(( 14 + DUNGEON_FLOOR * 4 ))
start_combat "Floor $DUNGEON_FLOOR Guardian" "$boss_hp" "$boss_atk" $(( 80 * DUNGEON_FLOOR )) $(( 50 * DUNGEON_FLOOR ))
if [ "$HP" -gt 0 ]; then
DUNGEON_FLOOR=$(( DUNGEON_FLOOR + 1 ))
echo -e "${YELLOW}You unlocked Floor $DUNGEON_FLOOR!${NC}"
pause
fi
;;
3) visit_shop ;;
4)
clear
echo -e "${CYAN}=== EQUIPMENT & INVENTORY ===${NC}\n"
echo "Equipped Weapon: $WEAPON (ATK: $ATTACK)"
echo "Equipped Armor: $ARMOR (DEF: $DEFENSE)"
echo "Health Potions: $POTIONS"
echo "Gold Coins: $GOLD"
pause
;;
5) save_game; pause ;;
6) echo "Thanks for playing!"; exit 0 ;;
*) echo "Invalid option."; sleep 1 ;;
esac
done

