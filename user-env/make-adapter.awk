/: error:/ { print dir "/" $0 > "/dev/stderr"; next}
/Entering directory / {
    split($0, p, /'/); dir = p[2]; print ; next
}
{ print }
