#!/usr/bin/env bash
# Visible Rift items are display-qualified and are created by rift_render.sh.
sketchybar --add item rift_workspace_renderer left \
  --set rift_workspace_renderer drawing=off script="$PLUGIN_DIR/rift_render.sh" \
  --subscribe rift_workspace_renderer rift_workspace_change rift_topology_change system_woke

sketchybar --add item rift_topology_sync left \
  --set rift_topology_sync drawing=off update_freq=15 script="$PLUGIN_DIR/rift_topology.sh" \
  --subscribe rift_topology_sync rift_workspace_change system_woke
