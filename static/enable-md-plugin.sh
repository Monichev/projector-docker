#!/bin/bash

#
# GNU General Public License version 2
#
# Copyright (C) 2019-2020 JetBrains s.r.o.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 2 only, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

set -e # Any command which returns non-zero exit code will cause this shell script to exit immediately

# First search for PATHS_SELECTOR:

# 2020.2+ (line like `PATHS_SELECTOR="IdeaIC2020.2"`):

idePathsSelectorRegex='PATHS_SELECTOR="(\S+)"'

idePathsSelectorCandidates=($(grep -ohrE --include=*.sh "$idePathsSelectorRegex" /projector/ide/bin || true))

# map candidates to the matches:
for i in "${!idePathsSelectorCandidates[@]}"; do
    if [[ ${idePathsSelectorCandidates[i]} =~ $idePathsSelectorRegex ]]; then
        idePathsSelectorCandidates[i]="${BASH_REMATCH[1]}"
    else
        unset 'idePathsSelectorCandidates[i]'
    fi
done

if [[ ${#idePathsSelectorCandidates[@]} != 1 ]]; then
  # 2020.1 and older (line like `-Didea.paths.selector=IntelliJIdea2020.1`):

  idePathsSelectorRegex='Didea\.paths\.selector=(\S+)'

  idePathsSelectorCandidates=($(grep -ohrE --include=*.sh "$idePathsSelectorRegex" /projector/ide/bin || true))

  # map candidates to the matches:
  for i in "${!idePathsSelectorCandidates[@]}"; do
      if [[ ${idePathsSelectorCandidates[i]} =~ $idePathsSelectorRegex ]]; then
          idePathsSelectorCandidates[i]="${BASH_REMATCH[1]}"
      else
          unset 'idePathsSelectorCandidates[i]'
      fi
  done

  if [[ ${#idePathsSelectorCandidates[@]} != 1 ]]; then
      echo "Can't find a single candidate to be IDE paths selector so can't select a single one:"
      echo "${idePathsSelectorCandidates[*]}"
      exit 1
  fi
fi

idePathsSelector=${idePathsSelectorCandidates[@]}

echo "Found IDE paths selector: $idePathsSelector"

if [ "${idePathsSelector#*2019}" != "$idePathsSelector" ];
then
  # 2019: https://www.jetbrains.com/help/idea/2019.3/tuning-the-ide.html
  # todo: support older versions
  configDir="$HOME/.$idePathsSelector/config";
  pluginsDir="$HOME/.$idePathsSelector/config/plugins";
else
  # 2020+: https://www.jetbrains.com/help/idea/2020.1/tuning-the-ide.html
  configDir="$HOME/.config/JetBrains/$idePathsSelector";
  pluginsDir="$HOME/.local/share/JetBrains/$idePathsSelector";
fi

echo "IDE config dir: $configDir"
echo "IDE plugins dir: $pluginsDir"

mdPluginEnablerFile="/projector/ide/bin/mdPluginEnablerFile.sh"
touch "$mdPluginEnablerFile"
chmod +x "$mdPluginEnablerFile"
echo "mkdir -p \"$configDir\"" >> "$mdPluginEnablerFile"
echo "cp /projector/disabled_plugins.txt $configDir/" >> "$mdPluginEnablerFile"
echo "mkdir -p \"$pluginsDir\"" >> "$mdPluginEnablerFile"
echo "rm -rf $pluginsDir/projector-markdown-plugin" >> "$mdPluginEnablerFile"
echo "cp -r /projector/projector-markdown-plugin $pluginsDir/projector-markdown-plugin" >> "$mdPluginEnablerFile"
."$mdPluginEnablerFile"
