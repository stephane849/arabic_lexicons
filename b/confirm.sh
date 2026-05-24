if [ -d "$bd" ]; then
  printf "Delete $bd [y/N] "
  read -r p
  if [ "$p" = "y" ] || [ "$p" = "Y" ]; then
    printf "rm $bd\n\n"
    rm -r "$bd"
  else
    printf "Keeping $bd\n\n"
  fi
fi

if [ ! -d "$bd" ];then
  mkdir "$bd"
fi
