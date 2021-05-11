# tests="layer-00-bootstrap layer-00-default layer-01-minimal layer-02-maximus"

prep_compiler() {
case "$COMPILER" in
  gcc) CC="gcc"; CXX="g++";;
  clang) CC="clang"; CXX="clang++";;
  icc) CC="icc"; CXX="icpc";;
  *) echo "Unknown compiler set, aborting"; exit 1;;
esac
export CC CXX
}

prep_shareddirs() {
  persist_shareddir="$HOME/docker-images/homedir"
  persist_dir="$HOME/docker-images/${OS}"
  
  mapped_dirs="-v "$PWD:$PWD" -w "$PWD" "
  if test -d "$persist_shareddir"; then
    mapped_dirs="-v $persist_shareddir:/home/jenkins $mapped_dirs"
  elif test -d "$persist_dir"; then
    mapped_dirs="-v $persist_dir:/home/jenkins $mapped_dirs"
  fi
}

