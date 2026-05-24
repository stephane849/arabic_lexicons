if [ -d "$bd" ]; then
  printf "Delete $bd [Y/n] "
  read -r p
  if [ -z "$p" ] || [ "$p" = "y" ] || [ "$p" = "Y" ]; then
    printf "rm $bd\n\n"
    rm -r "$bd"
  else
    printf "Keeping $bd\n\n"
  fi
fi

[ ! -d "$bd" ] && mkdir "$bd"
