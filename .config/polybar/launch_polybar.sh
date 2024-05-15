# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -x polybar >/dev/null; do sleep 0.2; done

if type "xrandr"; then
  for m in $(xrandr --listactivemonitors | grep -oP '(?<=\s)[a-zA-Z0-9-]+(?=$)' | tail -n +2); do
    echo "launching on monitor $m"
    MONITOR=$m polybar --config=/home/karlie/.config/polybar/config.ini --reload top-bar &
  done
else
  polybar --config=/home/karlie/.config/polybar/config.ini --reload top-bar &
fi
