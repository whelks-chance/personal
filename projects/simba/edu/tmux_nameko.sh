#!/usr/bin/env bash
usage() {
  echo ""
  echo "$0 usage:"
  echo "  -g :: Run API Gateway"
  echo "  -a :: Run auth service"
  echo "  -c :: Run content service"
  echo "  -e :: Run events service"
  echo ""
  echo "Available presets"
  echo "  -all   :: Run All"
  echo ""
  echo "Combine arguments to run specific services, e.g."
  echo ""
  echo "  $0 -a -c -e"
  echo ""
  echo "To run all Services"
  echo ""
  exit 1
}
options=("-all", "-a", "-c", "-e")

function list_include_item {
  local item="$1"   # Save first argument in a variable
  echo $item
  shift            # Shift all arguments to the left (original $1 gets lost)
  local list=$@
  echo $@
  if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
    # yes, list include item
    result=0
  else
    result=1
  fi
  return $result
}

gateway=0;
auth=0;
content=0;
event=0;

for i in "$@" ; do
#  if list_include_item $i "${options[@]}" ; then
#    echo $i
#  else
#    echo "Argument" $i "not recognised."
#    usage
#  fi

  if [[ $i == "-g" || $i == "-all" ]] ;
  then
    gateway=1
    echo "Selected run API Gateway"
  fi

  if [[ $i == "-a" || $i == "-all" ]] ;
  then
    auth=1
    echo "Selected run auth service"
  fi

  if [[ $i == "-c" || $i == "-all" ]] ;
  then
    content=1
    echo "Selected run content service"
  fi

  if [[ $i == "-e" || $i == "-all" ]] ;
  then
    event=1
    echo "Selected run event service"
  fi

done


python3 --version; which python3;


echo ''
echo 'Content Service'
cd services/content/edu_content_service

IN=`poetry show -v | grep 'Using virtualenv';`
arrIN=(${IN//'Using virtualenv:'/ })

echo Poetry reports venv as ${arrIN[0]}
content_service_venv_activate=${arrIN[0]}/bin/activate
echo Activate script should be at ${content_service_venv_activate}

if [ -r "$content_service_venv_activate" ]; then
  echo "Found Content Service venv. Using ${content_service_venv_activate} for VENV..."
else
  echo "Error: ${content_service_venv_activate} (Content Service VENV) not found. Can not continue."
  exit 1
fi

echo ''
echo 'Returning to root dir'
cd ../../../
pwd

echo ''
echo 'Auth Service'
cd services/auth/edu_auth_service

IN=`poetry show -v | grep 'Using virtualenv';`
arrIN=(${IN//'Using virtualenv:'/ })

echo Poetry reports venv as ${arrIN[0]}
auth_service_venv_activate=${arrIN[0]}/bin/activate
echo Activate script should be at ${auth_service_venv_activate}

if [ -r "$auth_service_venv_activate" ]; then
  echo "Found Auth Service venv. Using ${auth_service_venv_activate} for VENV..."
else
  echo "Error: ${auth_service_venv_activate} (Auth Service VENV) not found. Can not continue."
  exit 1
fi

echo ''
echo 'Returning to root dir'
cd ../../../
pwd

echo ''
echo 'Event Service'
cd services/events/edu_events_service

IN=`poetry show -v | grep 'Using virtualenv';`
arrIN=(${IN//'Using virtualenv:'/ })

echo Poetry reports venv as ${arrIN[0]}
event_service_venv_activate=${arrIN[0]}/bin/activate
echo Activate script should be at ${event_service_venv_activate}

if [ -r "$event_service_venv_activate" ]; then
  echo "Found Event Service venv. Using ${event_service_venv_activate} for VENV..."
else
  echo "Error: ${event_service_venv_activate} (Event Service VENV) not found. Can not continue."
  exit 1
fi

echo ''
echo 'Returning to root dir'
cd ../../../
pwd


echo ''
echo 'API Gateway'
cd services/api_gateway/edu_api_gateway

IN=`poetry show -v | grep 'Using virtualenv';`
arrIN=(${IN//'Using virtualenv:'/ })

echo Poetry reports venv as ${arrIN[0]}
api_gateway_venv_activate=${arrIN[0]}/bin/activate
echo Activate script should be at ${api_gateway_venv_activate}

if [ -r "$api_gateway_venv_activate" ]; then
  echo "Found API Gateway venv. Using ${api_gateway_venv_activate} for VENV..."
else
  echo "Error: ${api_gateway_venv_activate} (API Gateway VENV) not found. Can not continue."
  exit 1
fi

echo ''
echo 'Returning to root dir'
cd ../../../
pwd


# Set up the tmux script. Put tmux settings here
the_cmd=$"tmux "
the_cmd+=$"set -g mouse on \;  "
the_cmd+=$"set -g pane-border-status top \; "
the_cmd+=$"set-option -g history-limit 3000 \; "
#the_cmd+=$"bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe \"xclip -selection clipboard -i\" \; send -X clear-selection \; "
the_cmd+=$"set-hook -g after-kill-pane 'select-layout tiled' \; set-hook -g pane-exited 'select-layout tiled' \; "

# New session, either build docker or don't,
# either way the 'wait-for -S docker' must be called
# The 'sleep 2' ensures all the panes are ready before sending the signal

the_cmd+=$'new-session '
the_cmd+=$"\""
the_cmd+=$"printf '\033]2;%s\033\\' 'Docker'; "
the_cmd+=$"python3 --version; which python3; sleep 2; "

echo "Running with a pause"
the_cmd+=$"python3 --version; which python3; sleep 2; "
the_cmd+=$"tmux wait-for -S docker; echo 'Finished pause'; read;"


the_cmd+=$"\" "
the_cmd+="select-layout tiled \; "

# Run all other Services here



if [[ auth -eq 1 ]]; then
  echo "Auth Service"
#  the_cmd+=$"select-pane -t 0 \; "
  the_cmd+=$"split-window -h "
  the_cmd+=$"\"printf '\033]2;%s\033\\' 'Auth Service'; "
  the_cmd+=$"echo 'Waiting for Docker to complete'; pwd; tmux wait docker; "
  the_cmd+=$"source ${auth_service_venv_activate}; python3 --version; which python3;"
  the_cmd+=$"cd ./services/auth/edu_auth_service; pwd; nameko run service; read -n1 ; read;"
  the_cmd+=$"\" "
  the_cmd+="select-layout tiled \; "
fi

if [[ content -eq 1 ]]; then
  echo "Content Service"
#  the_cmd+=$"select-pane -t 0 \; "
  the_cmd+=$"split-window -h "
  the_cmd+=$"\"printf '\033]2;%s\033\\' 'Content Service'; "
  the_cmd+=$"echo 'Waiting for Docker to complete'; pwd; tmux wait docker; "
  the_cmd+=$"source ${content_service_venv_activate}; python3 --version; which python3;"
  the_cmd+=$"cd ./services/content/edu_content_service; pwd; nameko run service; read -n1 ; read;"
  the_cmd+=$"\" "
  the_cmd+="select-layout tiled \; "
fi

if [[ event -eq 1 ]]; then
  echo "event"
#  the_cmd+=$"select-pane -t 0 \; "
  the_cmd+=$"split-window -h "
  the_cmd+=$"\"printf '\033]2;%s\033\\' 'Event Service'; "
  the_cmd+=$"echo 'Waiting for Docker to complete'; pwd; tmux wait docker; "
  the_cmd+=$"source ${event_service_venv_activate}; python3 --version; which python3;"
  the_cmd+=$"cd ./services/events/edu_events_service; pwd; nameko run service; read -n1 ; read;"
  the_cmd+=$"\" "
  the_cmd+="select-layout tiled \; "
fi

if [[ auth -eq 1 ]]; then
  echo "Gateway Service"
#  the_cmd+=$"select-pane -t 0 \; "
  the_cmd+=$"split-window -h "
  the_cmd+=$"\"printf '\033]2;%s\033\\' 'Gateway Service'; "
  the_cmd+=$"echo 'Waiting for Docker to complete'; pwd; tmux wait docker; "
  the_cmd+=$"source ${api_gateway_venv_activate}; python3 --version; which python3;"
  the_cmd+=$"cd ./services/api_gateway; pwd; python3 ./edu_api_gateway/main.py; read -n1 ; read;"
  the_cmd+=$"\" "
  the_cmd+="select-layout tiled \; "
fi

printf '%s' "$the_cmd"
eval $the_cmd

