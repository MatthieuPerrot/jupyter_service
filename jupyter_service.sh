#!/usr/bin/env bash

function usage()
{
    echo "Usage: jupyter_service [cmd]"
    echo
    echo "[cmd]:"
    echo " - 'start':    launch service"
    echo " - 'stop':     stop service"
    echo " - 'restart':  start and stop service"
    echo " - 'status':   status"
}

if [ $# -ne 1 ];
then
    echo "wrong number of arguments"
    echo
    usage;
    exit;
fi

cmd=$1;
JUPYTER=jupyter
CONFIG="$HOME/.jupyter/jupyter_notebook_config.py"

function get_port()
{
    cat $CONFIG| grep "c.NotebookApp.port[ =]" | sed 's/.*= *\([0-9]*\)/\1/g'
}

function get_jupyter_status()
{
    	port=$(get_port)
        $JUPYTER notebook list 2> /dev/null | grep $port > /dev/null
	echo $?
}

function start()
{
    if [ -n "$(type -t $JUPYTER)" ];
    then
        jupyter_status=$(get_jupyter_status)
	if [ "${jupyter_status}" -eq "1" ];
	then
            echo -en "starting... "
	    $JUPYTER notebook --no-browser ${JUPYTER_NOTEBOOKS_DIR} &> /dev/null &
            let i=0;
            while [ "$(get_jupyter_status)" -eq "1" -a $i -lt 5 ];
            do
                sleep 1;
                let i=$i+1;
            done
            jupyter_status2=$(get_jupyter_status)
            if [ "${jupyter_status2}" -eq "1" ];
	    then
    	        echo "failed!"
            else
    	        echo "ok"
	    fi
        else
            echo "a notebook is already started"
	fi
    else
        echo "can't start service, command 'jupyter' not found"
    fi
}

function stop()
{
    port=$(get_port)
    before_kill=$(fuser "$port"/tcp 2>&1 | wc -l)
    if [ "${before_kill}" -eq "0" ];
    then
        echo "nothing to do"
    else
        echo -en "stopping... "
        fuser -k "$port"/tcp &> /dev/null
        after_kill=$(fuser "$port"/tcp 2>&1 | wc -l)

        if [ "${before_kill}" -eq "${after_kill}" ];
        then
            echo "failed!"
        else
            echo "ok"
        fi
    fi
}

function restart()
{
    stop;
    start;
}

function status()
{
    if [ -n "$(type -t $JUPYTER)" ];
    then
        jupyter_status=$(get_jupyter_status)
	if [ "${jupyter_status}" -eq "1" ];
	then
    	    echo "nothing found"
        else
    	    echo "Jupyter found:"
	    echo $($JUPYTER notebook list 2> /dev/null)
	fi
    else
        echo "command 'jupyter' not found"
    fi

}

function unknown()
{
    echo "unknown command '$1'"
    usage;
}

case $cmd in
"start")
    start;
    ;;
"stop")
    stop;
    ;;
"restart")
    restart;
    ;;
"status")
    status;
    ;;
*)
    unknown $cmd;
    ;;
esac;
