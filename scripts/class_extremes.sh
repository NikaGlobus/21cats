#!/bin/bash
# Находит занятия с минимальной и максимальной общей посещаемостью

ROOT_DIR="$1"
GROUP="$2"

if [ -z "$ROOT_DIR" ] || [ -z "$GROUP" ]; then
  echo "Использование: ./class_extremes.sh <путь_к_файлам_ЛР3> <номер_группы>"
  exit 1
fi

echo "=== Группа $GROUP ==="
echo "Поиск занятий с минимальной и максимальной посещаемостью..."

# Суммируем посещения по позициям (занятиям)
awk '
  /^[^#]/ && NF==2 {
    seq=$2
    for (i=1;i<=length(seq);i++) {
      if (substr(seq,i,1)=="1") count[i]++
    }
  }
  END {
    min=9999; max=0
    for (i in count) {
      if (count[i]<min) min=count[i]
      if (count[i]>max) max=count[i]
    }
    printf("Мин. посещаемость (%d студентов): ",min)
    for (i in count) if (count[i]==min) printf i " "
    print ""
    printf("Макс. посещаемость (%d студентов): ",max)
    for (i in count) if (count[i]==max) printf i " "
    print ""
  }' $(find "$ROOT_DIR" -type f -name "*-attendance")
