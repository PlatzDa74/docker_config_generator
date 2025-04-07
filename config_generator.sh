#!/bin/bash
# Pfad zur YAML-Datei
YAML_FILE="/run/secrets/tomcat_secrets"
DEBUG="true"

# Funktion zum Parsen und Bearbeiten der Dateien
parse_and_edit() {
  local yaml_file="$1"

  grep -A 3 "^file_" "$yaml_file" | while read -r line; do
    if [[ $line == absolute_filename* ]]; then
      file=$(echo "$line" | awk -F': ' '{print $2}')
      [ ${DEBUG} = "true" ] && echo -e "\nProcessing file: $file"
    elif [[ $line == search_content* ]]; then
      search=$(echo "$line" | awk -F': ' '{print $2}' | sed 's/^"//;s/"$//')
      [ ${DEBUG} = "true" ] && echo "Search pattern: $search"
    elif [[ $line == change_content* ]]; then
      change=$(echo "$line" | awk -F': ' '{print $2}' | sed 's/^"//;s/"$//')
      [ ${DEBUG} = "true" ] && echo "Replacement content: $change" 
      if [[ -f "$file" ]]; then
        sed -i "s|${search}|${change}|g" "$file"
      else
        [ ${DEBUG} = "true" ] && echo -e "\nERROR file does not exist: $file\n"
      fi
    fi
  done
}

# Funktion zum Ausführen des Kommandos im Execute-Block
execute_command() {
  local yaml_file="$1"

  # Extrahiere das Kommando und die Argumente
  command=$(grep -A 1 "^Execute:" "$yaml_file" | grep "command:" | awk -F':' '{print $2}')
  args=$(grep -A 2 "^Execute:" "$yaml_file" | grep "args" | awk -F':' '{print $2}' | sed 's/"//' | tr '\n' ' ')

  # Führe das Kommando aus
  [ ${DEBUG} = "true" ] && echo -e "\nExecuting command: $command $args\n"
  $command $args
}

# Hauptlogik
parse_and_edit "$YAML_FILE"
execute_command "$YAML_FILE"