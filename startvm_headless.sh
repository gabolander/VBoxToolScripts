#!/bin/bash
LANG="it_IT.UTF-8"
export LANG

PRG=`basename $0`
PRGBASE=`basename $0 .sh`
PRGDIR=`dirname $0`
VERSION="0.99.2"
LAST_UPD="25-03-2012"

COL_YELLOW="\033[1;33m";    COLESC_YELLOW=`echo -en "$COL_YELLOW"`
COL_BROWN="\033[0;33m";     COLESC_BROWN=`echo -en  "$COL_BROWN"`
COL_RED="\033[0;31m";       COLESC_RED=`echo -en    "$COL_RED"`
COL_LTRED="\033[1;31m";     COLESC_LTRED=`echo -en  "$COL_LTRED"`
COL_BLUE="\033[0;34m";      COLESC_BLUE=`echo -en   "$COL_BLUE"`
COL_LTBLUE="\033[1;34m";    COLESC_LTBLUE=`echo -en "$COL_LTBLUE"`
COL_GREEN="\033[0;32m";     COLESC_GREEN=`echo -en  "$COL_GREEN"`
COL_LTGREEN="\033[1;32m";   COLESC_LTGREEN=`echo -e "$COL_LTGREEN"`
COL_WHITE="\033[0;37m";     COLESC_WHITE=`echo -en  "$COL_WHITE"`
COL_LTWHITE="\033[1;37m";   COLESC_LTWHITE=`echo -en "$COL_LTWHITE"`
COL_RESET=`tput sgr0`;        COLESC_RESET=`echo -en  "$COL_RESET"`
COL_UL=`tput smul`
COL_BLINK=`tput blink`


ACTDIR=`pwd`
OGGI=`date +%Y%m%d`
OGGI_ITA=`date +%d-%m-%Y`
ORA_ITA=`date +%H:%M:%S`
if [ -z "$HOSTNAME" ]; then
  HOSTNAME=`hostname`
fi
TMPDIR=`mktemp -d /tmp/${PRGBASE}_temp_dir_XXXXX`
TMP1="$TMPDIR/${PRGBASE}-1_temp"
TMP2="$TMPDIR/${PRGBASE}-2_temp"
TMP3="$TMPDIR/${PRGBASE}-2_temp"
TEMPORANEI="$TMPDIR"

## Log
LOGDIR="/var/log"
LOGFILE="${LOGDIR}/${PRGBASE}.log"
LOGFILEXT="${LOGDIR}/${PRGBASE}-ext-${OGGI}.log"


# declare -a sms_errors=('child procs already',"lerrore di stocazzo")  #Per ora solo uno
Recipients="<gabriele.zappi@acantho.net>,<gabriele.zappi@comune.rimini.it>"
declare -a mat_escluse=("M01234" "M19099")  # array di matricole escluse


### Comandi
TAR=`type -p tar`
GREP=`type -p grep`
CAT=`type -p cat`
SSH=`type -p ssh`
SCP=`type -p scp`
SORT=`type -p sort`
UNIQ=`type -p uniq`
FDUPES=`type -p fdupes`
RSYNC=`type -p rsync`
EXIFTOOL=`type -p exiftool`
DIALOG=`type -p dialog`

######
# Libreria funzioni
if [ -f "$PRGDIR/bash_functions_lib.inc.sh" ]; then
  . "$PRGDIR/bash_functions_lib.inc.sh"
fi

####
#  Funzioni
#
function at_exit()
{
  if [ "$1" -gt 0 -a "$1" -lt 32 ]; then
    echo -n "Uscita irregolare per : "
  else
#     echo "Uscita regolare." # debug
      echo
  fi 
      
  case "$1" in
     1) 
      echo "SIGHUP    /* Hangup (POSIX).  */"
      ;;
     2) echo "SIGINT    /* Interrupt (ANSI).  */"
      ;;
     3) echo "SIGQUIT   /* Quit (POSIX).  */"
      ;;
     9) echo "SIGKILL   /* Kill, unblockable (POSIX).  */"
      ;;
     12) echo "SIGUSR2     /* User-defined signal 2 (POSIX).  */"
      ;;
     13) echo "SIGPIPE     /* Broken pipe (POSIX).  */"
      ;;
     15) echo "SIGTERM     /* Termination (ANSI).  */"
      ;;
  esac

  rm -rf "$TEMPORANEI"
  exit $1
}

sino()
{
  SINO=""
  DEF=""
  TMP=""
  MSG=`echo "$1" | cut -c1`
  if [ "$MSG" = "-" ]; then
    MSG=""
  else
    MSG="$1"
  fi

  if [ -z "$2" ]; then
    TMP="$1"
  else
    TMP="$2"
  fi
  TMP=`echo $TMP | tr [:lower:] [:upper:]`
  DEF=`echo $TMP | cut -c1`
  if [ -n "$MSG" -a -n "$DEF" ]; then
	MSG="$MSG [def=$DEF]"
  fi

  while [ "$SINO" != "S" -a  "$SINO" != "N" ]; do
    echo -n "$MSG :"
    read SINO
    [ -z "$SINO" ] && SINO=$DEF
    SINO=`echo $SINO | tr [:lower:] [:upper:]`
    if [ "$SINO" != "S" -a  "$SINO" != "N" ]; then
	echo "Prego rispondere con S o N."
    fi
  done
}

askint()
{
  NUMBER=""

  MIN="$1"
  MAX="$2"

  while [ "$NUMBER" = "" ]; do
    echo -n "$MSG :"
    read NUMBER
    

    if ! [[ "$NUMBER" =~ ^[0-9]+$ ]]; then
        echo "Please enter a number (only digit!)."
        NUMBER=""
        continue
    fi
    NUMBER=$((NUMBER+0)) # integer Conversion
    if [ -n "$MIN" ] && [ $NUMBER -lt "$MIN" ]; then
        echo "IERR: Input number less than minimum allowed ($MIN)"
        NUMBER=""
        continue
    fi
    if [ -n "$MAX" ] && [ $NUMBER -gt "$MAX" ]; then
        echo "IERR: Input number greater than maximum allowed ($MAX)"
        NUMBER=""
        continue
    fi

  done
}

proseguo()
{
  RISP=""
  while [ "$RISP" != "S" ]; do
    echo -ne "\n Proseguo ('S' per Si, CTRL+C per interrompere) : "
    read RISP
#   RISP=`echo $RISP | tr [:lower:] [:upper:]`
  done
}

pinvio()
{
  echo -ne "\n Premere [INVIO] per continuare. "
  read RISP
  echo " "
}



function agg_ora()
{
  OGGI=`date +%Y%m%d`
  OGGI_ITA=`date +%d-%m-%Y`
  ORA_ITA=`date +%H:%M:%S`
  DATAIERI=`date -d yesterday +%Y%m%d`
}

function help()
{
  cat<<!EOM
 Uso $PRG : 
     $PRG <parametri>
          parametri:
          -h | --help  =  Questo help
!EOM
#           -q | --quiet = Non vengono inviati messaggi di stato in output,
#                          ma viene scritto solo il log in $LOGFILE
  at_exit 0
}

function logga()
{
	[ -n "$QUIET" ] || echo "$1"
	echo "$1" >> $LOGFILE
	[ -z "$DEBUG" ] || echo "$1" >> $LOGFILEXT
}


function valuta_parametri() {
#!/bin/sh
# scansione_1.sh

# Si raccoglie la stringa generata da getopt.
# STRINGA_ARGOMENTI=`getopt -o aB:c:: -l a-lunga,b-lunga:,c-lunga:: -- "$@"`
STRINGA_ARGOMENTI=`getopt -o hB:Sfy -l help,repo-dir:,repobase-directory:,simulate,fdupes,yes -- "$@"`


# Inizializzazione parametri di default
REPOBASE_DIR=""
SIMULATE=""
USE_FDUPES=""
ANS_YES=""

# Si trasferisce nei parametri $1, $2,...
eval set -- "$STRINGA_ARGOMENTI"

while true ; do
#		echo "Param = $1" # debug
    case "$1" in
#        -a|--a-lunga)
#            echo "Opzione a" # debug
#            shift
#            ;;
	-h|--help)
			shift
			help
			;;
	-f|--fdupes)
			shift
			USE_FDUPES="yes"
			;;
	-y|--yes)
			shift
			ANS_YES="yes"
			;;
        -B|--repo-dir*|--repobase-dir*)
            # echo "Opzione b, argomento «$2»" # debug
						[ -z "$2" ] && at_exit 99
						REPOBASE_DIR="$2"
            shift 2
            ;;
#        -c|--c-lunga)
#            case "$2" in
#                "") echo "Opzione c, senza argomenti" # debug
#                    shift 2
#                    ;;
#                *)  echo "Opzione c, argomento «$2»" # debug
#                    shift 2
#                    ;;
#            esac
#            ;;
				-S|--simulate) 
						SIMULATE="S"
						shift
						;;
				-N|--no-delete-user*)
						NODELUSER="S"
						shift
						;;
        --) shift
            break
            ;;
        *)  echo "Errore imprevisto!"
            exit 1
            ;;
        esac
done

# echo "Argomenti rimanenti:" # debug

# DEBUG
#echo "Prima di ARG_RESTANTI"
ARG_RESTANTI=()
for i in `seq 1 $#`
do
    eval a=\$$i
#    echo "$i) $a"
    ARG_RESTANTI[$i]="$a"
done

#ARG_RESTANTI="$@"
# for argomento in "$@"
# do
#     echo "$argomento"
# done

# [ -z "$ARG_RESTANTI" ] && help "$PRG: ${COL_LTRED}ERRORE${COL_RESET}: pochi parametri!\n" 99
# [ "${#ARG_RESTANTI[*]}" -eq 0 ] && help "$PRG: ${COL_LTRED}ERRORE${COL_RESET}: pochi parametri!\n" 99

}



#############################################################
# INIZIO SCRIPT                                             #
#############################################################

# Trappiamo i segnali
for ac_signal in 1 2 13 15; do
  trap 'ac_signal='$ac_signal'; at_exit $ac_signal;' $ac_signal
done
ac_signal=0


#-- Valutazione dei parametri (argomenti - e --) e elborazione restanti - inizio
# come da script "rsync_dedup_repo.sh"
valuta_parametri "$@"
newparams=""
for i in `seq 1 ${#ARG_RESTANTI[*]}`
do
 newparams="$newparams '${ARG_RESTANTI[$i]}'"
# echo "Ciclo $i) ARG_RESTANTI[$i] = ${ARG_RESTANTI[$i]} "
done
#echo "\$newparams = $newparams"

# set -- "${ARG_RESTANTI[*]}"
# set -- "$(for i in `seq 1 ${#ARG_RESTANTI[*]}`;do echo "${ARG_RESTANTI[$i]}"; done)"
eval "set -- $newparams"
# Ora li valuto normalmente come $1, $2, ... $n

### Da usare nel caso si vogliano imporre argomenti
# if [ -z "$1" ]; then
#	echo "$PRG: No argomenti?"
#	at_exit 99
#fi
#-- Valutazione dei parametri (argomenti - e --) e elborazione restanti - fine

## sino "Proseguo con l'elaborazione?" "N"
## if [ $SINO = "S" ]; then
## :
## else
## at_exit 99
## fi
## echo

/usr/bin/VBoxManage list vms | sed "s/\" /\"|/" | sed "s/$/|/" > "$TMP1"
/usr/bin/VBoxManage list runningvms | sed "s/\" /\"|/" > "$TMP2"

declare -a vmids
declare -a vmnames

echo "VIRTUAL MACHINES AVAILABLE :"
echo "============================"
c=0
while read -r line
do
    vmname=$(echo $line | cut -f1 -d"|")
    vmid=$(echo $line | cut -f2 -d"|")
    vmstatus=$(echo $line | cut -f3 -d"|")

    if (grep -q "^${vmname}|" "$TMP2"); then
        vmstatus='(***RUNNING***)'
        printf "     "
    else
        vmids[$c]="$vmid"
        vmnames[$c]="$vmname"
        ((c=$c+1))
        printf " %3d)" $c
    fi

    # echo " $c) | ${vmname} | ${vmid} | ${vmstatus} "
    echo " ${vmname}  ${vmstatus} "
    
done < "$TMP1"
quanti=${#vmids[@]}

echo 
if [ "$quanti" -eq 0 ]; then
    echo "Sorry, no VM to launch. Quitting."
    echo
    at_exit 0
fi

MSG=" Enter a choice (1 - $quanti, 0 = Exit)"
askint 0 $quanti

# echo " Hai scelto il num : $NUMBER "

echo 

if [ "$NUMBER" -eq 0 ]; then
    echo "Ok, exiting. Goodbye .."
    echo
    at_exit 0
fi
vmnum=$((NUMBER-1))
echo "RUNNING MACHINE "${vmnames[$vmnum]}" ..."


# echo -n "press a key... "; read a

# VBoxManage startvm "$vm" --type headless
/usr/bin/VBoxHeadless --startvm ${vmids[$vmnum]} &

echo
echo -n "Waiting 40 seconds for the network to come up, so I can retrive IP ... "
sleep 40
echo
echo

# Provato a conoscere l'ip nei seguenti modi: 
#  VBoxManage --nologo guestcontrol "openSuSE 11.3 64bit" execute --image "/sbin/ifconfig"  --username user --password password --wait-exit --wait-stdout -- -a
# VBoxManage list bridgedifs
# ....

givenIP=`VBoxManage guestproperty enumerate ${vmnames[$vmnum]} | grep -o "Net.*IP.*value: [0-9\.]*" | cut -f2 -d ":" | sed "s/^\s*//" | sed "s/\s*$//"`

if [ -n "$givenIP" ]; then
	echo -e "\n IP Attribuito alla VM \"$vm\" = $givenIP \n"
	retval=0
else
	echo -e "\n WARNING: Non rilevo IP della VM \"$vm\". Probabilmente non sono"
	echo -e "installate le ultime Guest Addons di Virtual Box nella VM\n"
  retval=1
fi

at_exit $retval




# ex: nohls ts=4 sts=4 sw=4 et mouse-=a
