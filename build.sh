set -e

program=$1

if [ -z "$program" ]; then
    echo "Usage: $0 <program>"
    exit 1
fi

mkdir -p ./build/$program

for file in $program/*.asm; do
    nasm -g -f elf64 -F dwarf -O0 $file -o ./build/$program/$(basename $file .asm).o
done

linker=${LINK_WITH:-ld}
ldflags=$LD_FLAGS

$linker $ldflags ./build/$program/*.o -o ./build/$program/$(basename $program)
