rgb_to_escape() {
  local -a INPUT=($@)
  local -a OUTPUT
  local -a intermediate
  local -i n

  # remove leading and trailing whitespace; split on non-digit
  for i in "${INPUT[@]}"; do

    # seperated to indiviual elements
    intermediate=($(echo $i | tr -d '[:space:]'))

    # for each element, extract numeric values
    for j in "${intermediate[@]}"; do

      n=$(echo $j | grep -o '[0-9]\+')
      # if no number, then skip
      if [[ -z $n ]]; then
        continue
      fi

      # check int in range 0-255
      if [[ $n -lt 0 || $n -gt 255 ]]; then
        echo "Error: Invalid color code. Please provide r, g, and b values."
        exit 1
      fi
      OUTPUT+=($n)
    done
    echo
  done

  # check args in OUTPUT
  if [[ ${#OUTPUT[@]} -ne 3 ]]; then
    echo "Error: Invalid color code. Please provide r, g, and b values."
    exit 1
  fi

  # \e[38;2;⟨r⟩;⟨g⟩;⟨b⟩m
  echo "\033[38;2;${OUTPUT[0]};${OUTPUT[1]};${OUTPUT[2]}m"
  return 0
}

rgb_to_escape "218 112 214"
