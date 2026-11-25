#!/usr/bin/env bash

# ==========================================
# Configuración y Colores
# ==========================================
ARCHIVO_GUARDADO="./partida.sav"

ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;36m'
MORADO='\033[0;35m'
SIN_COLOR='\033[0m'

# ==========================================
# Variables del Jugador (Estado inicial)
# ==========================================
NOMBRE=""
NIVEL=1
XP=0
XP_SIGUIENTE=100
HP=100
HP_MAX=100
ATAQUE=12
DEFENSA=4
ORO=30
POCIONES=2
ARMA="Daga oxidada"
ARMADURA="Ropa de tela"
PISO_MAZORRA=1

# ==========================================
# Sistema de Guardado y Carga
# ==========================================
guardar_partida() {
    cat > "$ARCHIVO_GUARDADO" <<EOF
NOMBRE="$NOMBRE"
NIVEL=$NIVEL
XP=$XP
XP_SIGUIENTE=$XP_SIGUIENTE
HP=$HP
HP_MAX=$HP_MAX
ATAQUE=$ATAQUE
DEFENSA=$DEFENSA
ORO=$ORO
POCIONES=$POCIONES
ARMA="$ARMA"
ARMADURA="$ARMADURA"
PISO_MAZORRA=$PISO_MAZORRA
EOF
    echo -e "${VERDE}✔ Partida guardada correctamente en $ARCHIVO_GUARDADO${SIN_COLOR}"
}

cargar_partida() {
    if [ -f "$ARCHIVO_GUARDADO" ]; then
        # shellcheck disable=SC1090
        source "$ARCHIVO_GUARDADO"
        echo -e "${VERDE}✔ ¡Bienvenido de nuevo, $NOMBRE!${SIN_COLOR}"
        sleep 1
        return 0
    else
        echo -e "${ROJO}No se encontró ninguna partida guardada.${SIN_COLOR}"
        sleep 1
        return 1
    fi
}

# ==========================================
# Utilidades y Progresión
# ==========================================
pausar() {
    echo ""
    read -rp "Presiona [Enter] para continuar..."
}

mostrar_barra_hp() {
    local actual=$1
    local maximo=$2
    local ancho=20
    local llenos=$(( actual * ancho / maximo ))
    [ $llenos -lt 0 ] && llenos=0
    local vacios=$(( ancho - llenos ))

    printf "["
    printf "%${llenos}s" | tr ' ' '#'
    printf "%${vacios}s" | tr ' ' '-'
    printf "] %d/%d HP" "$actual" "$maximo"
}

subir_nivel() {
    while [ "$XP" -ge "$XP_SIGUIENTE" ]; do
        XP=$(( XP - XP_SIGUIENTE ))
        NIVEL=$(( NIVEL + 1 ))
        XP_SIGUIENTE=$(( XP_SIGUIENTE + 50 ))
        HP_MAX=$(( HP_MAX + 20 ))
        HP=$HP_MAX
        ATAQUE=$(( ATAQUE + 4 ))
        DEFENSA=$(( DEFENSA + 2 ))

        echo -e "\n${AMARILLO}★ ¡SUBISTE AL NIVEL $NIVEL! ★${SIN_COLOR}"
        echo "HP Máximo +20 | Ataque +4 | Defensa +2 (Salud restaurada)"
    done
}

# ==========================================
# Sistema de Combate por Turnos
# ==========================================
iniciar_combate() {
    local enemigo_nombre="$1"
    local enemigo_hp="$2"
    local enemigo_hp_max="$2"
    local enemigo_atk="$3"
    local recompensa_xp="$4"
    local recompensa_oro="$5"

    while [ "$HP" -gt 0 ] && [ "$enemigo_hp" -gt 0 ]; do
        clear
        echo -e "${ROJO}⚔️  COMBATE: $NOMBRE vs $enemigo_nombre ⚔️${SIN_COLOR}\n"
        echo -n "$NOMBRE: "
        mostrar_barra_hp "$HP" "$HP_MAX"
        echo -e " | Pociones: ${VERDE}$POCIONES${SIN_COLOR}"

        echo -n "$enemigo_nombre: "
        mostrar_barra_hp "$enemigo_hp" "$enemigo_hp_max"
        echo -e "\n\n----------------------------------------"
        echo "1. Ataque rápido (Seguro)"
        echo "2. Golpe pesado (Más daño, puede fallar)"
        echo "3. Usar poción (+45 HP)"
        echo "4. Intentar huir"
        read -rp "Elige tu acción: " accion

        echo ""
        case "$accion" in
            1)
                local variacion=$(( RANDOM % 5 - 2 ))
                local dano=$(( ATAQUE + variacion ))
                [ $dano -lt 1 ] && dano=1
                enemigo_hp=$(( enemigo_hp - dano ))
                echo -e "Atacas con tu $ARMA e infliges ${AMARILLO}$dano de daño${SIN_COLOR}."
                ;;
            2)
                local suerte=$(( RANDOM % 100 ))
                if [ $suerte -lt 65 ]; then
                    local dano=$(( ATAQUE * 2 - 2 ))
                    enemigo_hp=$(( enemigo_hp - dano ))
                    echo -e "${VERDE}¡Golpe crítico!${SIN_COLOR} Infliges ${AMARILLO}$dano de daño${SIN_COLOR}."
                else
                    echo -e "${ROJO}¡Fallaste el golpe pesado!${SIN_COLOR}"
                fi
                ;;
            3)
                if [ "$POCIONES" -gt 0 ]; then
                    POCIONES=$(( POCIONES - 1 ))
                    HP=$(( HP + 45 ))
                    [ $HP -gt $HP_MAX ] && HP=$HP_MAX
                    echo -e "${VERDE}Bebes una poción y recuperas salud.${SIN_COLOR}"
                else
                    echo -e "${ROJO}¡No te quedan pociones! Pierdes el turno buscando en tu mochila.${SIN_COLOR}"
                fi
                ;;
            4)
                if [ $(( RANDOM % 100 )) -lt 50 ]; then
                    echo -e "${AZUL}Lograste escapar del combate.${SIN_COLOR}"
                    pausar
                    return
                else
                    echo -e "${ROJO}¡El enemigo bloqueó tu escape!${SIN_COLOR}"
                fi
                ;;
            *)
                echo "Dudaste demasiado y perdiste tu turno."
                ;;
        esac

        # Turno del enemigo si sigue vivo
        if [ "$enemigo_hp" -gt 0 ]; then
            local dano_enemigo=$(( enemigo_atk - DEFENSA + (RANDOM % 4) ))
            [ $dano_enemigo -lt 1 ] && dano_enemigo=1
            HP=$(( HP - dano_enemigo ))
            echo -e "$enemigo_nombre te ataca y recibes ${ROJO}$dano_enemigo de daño${SIN_COLOR}."
        fi

        sleep 1.5
    done

    if [ "$HP" -le 0 ]; then
        clear
        echo -e "${ROJO}========================================${SIN_COLOR}"
        echo -e "${ROJO}           HAS SIDO DERROTADO           ${SIN_COLOR}"
        echo -e "${ROJO}========================================${SIN_COLOR}"
        echo "Pierdes la mitad de tu oro y despiertas en el campamento..."
        ORO=$(( ORO / 2 ))
        HP=$(( HP_MAX / 2 ))
        pausar
    else
        echo -e "\n${VERDE}¡Has derrotado a $enemigo_nombre!${SIN_COLOR}"
        echo "Ganas +$recompensa_xp XP y +$recompensa_oro de Oro."
        XP=$(( XP + recompensa_xp ))
        ORO=$(( ORO + recompensa_oro ))
        subir_nivel
        pausar
    fi
}

# ==========================================
# Exploración y Eventos Aleatorios
# ==========================================
explorar() {
    clear
    echo -e "${AZUL}🌲 Explorando el Piso $PISO_MAZORRA...${SIN_COLOR}\n"
    sleep 1

    local evento=$(( RANDOM % 100 ))
    local escala=$(( PISO_MAZORRA * 6 ))

    if [ $evento -lt 55 ]; then
        # Encuentro con enemigo escalado según el piso
        local tipo=$(( RANDOM % 3 ))
        case $tipo in
            0) iniciar_combate "Slime Ácido" $(( 35 + escala )) $(( 7 + PISO_MAZORRA * 2 )) 35 15 ;;
            1) iniciar_combate "Esqueleto Guardia" $(( 50 + escala )) $(( 10 + PISO_MAZORRA * 2 )) 50 25 ;;
            2) iniciar_combate "Lobo Sombrío" $(( 45 + escala )) $(( 12 + PISO_MAZORRA * 2 )) 45 20 ;;
        esac
    elif [ $evento -lt 75 ]; then
        # Cofre del tesoro
        local oro_encontrado=$(( 15 + RANDOM % 25 + PISO_MAZORRA * 5 ))
        ORO=$(( ORO + oro_encontrado ))
        echo -e "${AMARILLO}✨ ¡Encontraste un cofre antiguo!${SIN_COLOR}"
        echo "Obtienes $oro_encontrado monedas de oro."
        pausar
    elif [ $evento -lt 90 ]; then
        # Fuente curativa
        local cura=30
        HP=$(( HP + cura ))
        [ $HP -gt $HP_MAX ] && HP=$HP_MAX
        echo -e "${VERDE}💧 Descubres una fuente cristalina.${SIN_COLOR}"
        echo "Recuperas $cura puntos de salud."
        pausar
    else
        # Trampa
        local dano_trampa=$(( 8 + PISO_MAZORRA * 2 ))
        HP=$(( HP - dano_trampa ))
        [ $HP -lt 1 ] && HP=1
        echo -e "${ROJO}⚠️  ¡Pisaste una trampa de pinchos!${SIN_COLOR}"
        echo "Pierdes $dano_trampa HP."
        pausar
    fi
}

# ==========================================
# Tienda y Campamento
# ==========================================
visitar_tienda() {
    while true; do
        clear
        echo -e "${AMARILLO}🏪 MERCADER DEL CAMPAMENTO${SIN_COLOR}"
        echo -e "Tu Oro: ${AMARILLO}$ORO${SIN_COLOR} | Pociones: ${VERDE}$POCIONES${SIN_COLOR}\n"
        echo "1. Comprar Poción de Salud (20 oro)"
        echo "2. Mejorar Arma (+5 Ataque) - Costo: 50 oro"
        echo "3. Mejorar Armadura (+3 Defensa) - Costo: 50 oro"
        echo "4. Descansar en la posada (Restaura todo el HP) - Costo: 15 oro"
        echo "5. Volver al menú principal"
        read -rp "Elige una opción: " op_tienda

        case "$op_tienda" in
            1)
                if [ "$ORO" -ge 20 ]; then
                    ORO=$(( ORO - 20 ))
                    POCIONES=$(( POCIONES + 1 ))
                    echo -e "${VERDE}Compraste una poción.${SIN_COLOR}"
                else
                    echo -e "${ROJO}No tienes suficiente oro.${SIN_COLOR}"
                fi
                sleep 1
                ;;
            2)
                if [ "$ORO" -ge 50 ]; then
                    ORO=$(( ORO - 50 ))
                    ATAQUE=$(( ATAQUE + 5 ))
                    ARMA="Espada Forjada (+$ATAQUE)"
                    echo -e "${VERDE}¡Tu ataque aumentó a $ATAQUE!${SIN_COLOR}"
                else
                    echo -e "${ROJO}No tienes suficiente oro.${SIN_COLOR}"
                fi
                sleep 1
                ;;
            3)
                if [ "$ORO" -ge 50 ]; then
                    ORO=$(( ORO - 50 ))
                    DEFENSA=$(( DEFENSA + 3 ))
                    ARMADURA="Cota Reforzada (+$DEFENSA)"
                    echo -e "${VERDE}¡Tu defensa aumentó a $DEFENSA!${SIN_COLOR}"
                else
                    echo -e "${ROJO}No tienes suficiente oro.${SIN_COLOR}"
                fi
                sleep 1
                ;;
            4)
                if [ "$ORO" -ge 15 ]; then
                    ORO=$(( ORO - 15 ))
                    HP=$HP_MAX
Usa el código con precaución.
echo -e "${VERDE}Descansaste y recuperaste toda tu salud.${SIN_COLOR}"
else
echo -e "${ROJO}No tienes suficiente oro.${SIN_COLOR}"
fi
sleep 1
;;
5) break ;;
*) echo "Opción inválida."; sleep 1 ;;
esac
done
}

==========================================


 #Inicio del Juego


==========================================

clear
echo -e "${MORADO}========================================${SIN_COLOR}"
echo -e "${MORADO}         TERMINAL QUEST - BASH RPG      ${SIN_COLOR}"
echo -e "${MORADO}========================================${SIN_COLOR}\n"
echo "1. Nueva Partida"
echo "2. Cargar Partida"
read -rp "Selecciona: " inicio
if [ "$inicio" == "2" ] && cargar_partida; then
:
else
read -rp "Ingresa el nombre de tu héroe: " NOMBRE
[ -z "$NOMBRE" ] && NOMBRE="Aventurero"
fi




#ucle Principal

while true; do
clear
echo -e "${AZUL}========================================${SIN_COLOR}"
echo -e " Héroe: ${AMARILLO}$NOMBRE${SIN_COLOR} | Nivel: ${VERDE}$NIVEL${SIN_COLOR} ($XP/$XP_SIGUIENTE XP)"
echo -n " Salud: "
mostrar_barra_hp "$HP" "$HP_MAX"
echo ""
echo -e " ATK: $ATAQUE | DEF: $DEFENSA | Oro: ${AMARILLO}$ORO${SIN_COLOR} | Piso: $PISO_MAZORRA"
echo -e "${AZUL}========================================${SIN_COLOR}\n"
echo "1. Explorar zona actual"
echo "2. Desafiar al Guardián del Piso (Subir de piso)"
echo "3. Ir a la Tienda / Posada"
echo "4. Ver Inventario y Equipo"
echo "5. Guardar Partida"
echo "6. Salir"
echo ""
read -rp "¿Qué deseas hacer? [1-6]: " menu
case "$menu" in
1) explorar ;;
2)
local_hp_jefe=$(( 90 + PISO_MAZORRA * 35 ))
local_atk_jefe=$(( 14 + PISO_MAZORRA * 4 ))
iniciar_combate "Guardián del Piso $PISO_MAZORRA" "$local_hp_jefe" "$local_atk_jefe" $(( 80 * PISO_MAZORRA )) $(( 50 * PISO_MAZORRA ))
if [ "$HP" -gt 0 ]; then
PISO_MAZORRA=$(( PISO_MAZORRA + 1 ))
echo -e "${AMARILLO}¡Has desbloqueado el Piso $PISO_MAZORRA!${SIN_COLOR}"
pausar
fi
;;
3) visitar_tienda ;;
4)
clear
echo -e "${AZUL}=== EQUIPO E INVENTARIO ===${SIN_COLOR}\n"
echo "Arma equipada: $ARMA (ATK: $ATAQUE)"
echo "Armadura equipada: $ARMADURA (DEF: $DEFENSA)"
echo "Pociones de salud: $POCIONES"
echo "Monedas de oro: $ORO"
pausar
;;
5) guardar_partida; pausar ;;
6) echo "¡Gracias por jugar!"; exit 0 ;;
*) echo "Opción inválida."; sleep 1 ;;
esac
done

