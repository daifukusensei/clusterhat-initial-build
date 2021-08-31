#!/bin/sh
# tmux file for starting the Cluster HAT and providing paned access to all nodes in a single terminal window from the controller
tmux new-session -s cluster \; \
split-window -v -p 50 "sleep 100 ; ssh p1" \; \
split-window -v -p 50 "sleep 100 ; ssh p3" \; \
select-pane -t :.- \; \
split-window -h -p 50 "sleep 100 ; ssh p2" \; \
select-pane -t :.+ \; \
split-window -h -p 50 "sleep 100 ; ssh p4" \; \
select-pane -t :.+ \; \
send-key "clusterhat on" Enter \; \
set -g mouse on \; \
attach
