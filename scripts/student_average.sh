#!/bin/bash
# Среднее количество правильных ответов студента по предмету

ROOT_DIR="$1"
SUBJECT="$2"
STUDENT="$3"

if [ -z "$ROOT_DIR" ] || [ -z "$SUBJECT" ] || [ -z "$STUDENT" ]; then
  echo "Использование: ./student_average.sh <путь_к_файлам_ЛР3> <название_предмета> <фамилия>"
  exit 1
fi

SUBJ_DIR=$(find "$ROOT_DIR" -type d -name "$SUBJECT" 2>/dev/null | head -n1)
if [ -z "$SUBJ_DIR" ]; then
  echo "Предмет $SUBJECT не найден."
  exit 1
fi

awk -F';' -v name="$STUDENT" '
  $2==name && $4~/^[0-9]+$/ { sum+=$4; n++ }
  END {
    if (n>0) printf("Средний результат %s по предмету: %.2f (из %d тестов)\n", name, sum/n, n)
    else print "Нет данных для студента", name
  }' $(find "$SUBJ_DIR" -type f -name "TEST-*")
