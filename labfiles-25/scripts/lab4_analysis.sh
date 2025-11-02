#!/bin/bash
# ЛР4. Анализ посещаемости и результатов тестов

ROOT_DIR="$1"     # путь к файловой системе преподавателя
GROUP="$2"        # номер группы, например A-06-22

if [ -z "$ROOT_DIR" ] || [ -z "$GROUP" ]; then
  echo "Использование: ./lab4_analysis.sh <путь_к_файлам_ЛР3> <номер_группы>"
  exit 1
fi

echo "=== Анализ группы $GROUP ==="

# ----------- 1. Студент с наихудшей посещаемостью ------------
echo
echo "Студент с наихудшей посещаемостью:"
awk '
  /^[^#]/ && NF==2 {
    name=$1
    gsub(/[^01]/,"",$2)
    c=gsub(/1/,"1",$2)
    total[name]+=c
  }
  END {
    min=99999
    for (n in total) {
      if (total[n]<min) {min=total[n]}
    }
    for (n in total) {
      if (total[n]==min) print n, "-", total[n], "посещений"
    }
  }' $(find "$ROOT_DIR" -type f -name "*-attendance")

# ----------- 2. Студент с макс. количеством правильных ответов ------------
echo
echo "Студент с максимальным количеством правильных ответов:"
awk -F';' -v grp="$GROUP" '
  $1==grp {
    correct=$4
    if (correct~/^[0-9]+$/)
      total[$2]+=$4
  }
  END {
    max=0
    for (n in total) {
      if (total[n]>max) max=total[n]
    }
    for (n in total) {
      if (total[n]==max) print n, "-", total[n], "правильных ответов"
    }
  }' $(find "$ROOT_DIR" -type f -name "TEST-*")
