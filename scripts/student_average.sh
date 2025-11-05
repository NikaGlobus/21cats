#!/bin/bash

ROOT_DIR="$1"
GROUP="$2"
SUBJECT="$3"
STUDENT="$4"

if [ -z "$ROOT_DIR" ] || [ -z "$STUDENT" ]; then
    echo "Использование: ./student_average.sh <путь_к_файлам_ЛР3> [группа] [предмет] <фамилия>"
    exit 1
fi

echo
echo "=== Средний результат студента ==="
echo "Студент: $STUDENT"
[ -n "$GROUP" ] && echo "Группа: $GROUP" || echo "Группа: все группы"
[ -n "$SUBJECT" ] && echo "Предмет: $SUBJECT" || echo "Предмет: оба предмета"
echo

if [ -n "$SUBJECT" ]; then
    TEST_FILES=$(find "$ROOT_DIR" -type f -path "*/$SUBJECT/tests/TEST-*" 2>/dev/null)
else
    TEST_FILES=$(find "$ROOT_DIR" -type f \( -path "*/Поп-Культуроведение/tests/TEST-*" -o -path "*/Цирковое_Дело/tests/TEST-*" \) 2>/dev/null)
fi

if [ -z "$TEST_FILES" ]; then
    echo "Файлы тестов не найдены!"
    exit 1
fi

sum=0
count=0
declare -A subjects

for file in $TEST_FILES; do
    while IFS=';' read -r grp name _ score _; do

        # Проверка фамилии
        [ "$name" != "$STUDENT" ] && continue
        
        # Проверка группы (если указана)
        [ -n "$GROUP" ] && [ "$grp" != "$GROUP" ] && continue
        
        # Проверка, что score — число
        [[ "$score" =~ ^[0-9]+$ ]] || continue
        
        sum=$((sum + score))
        count=$((count + 1))

        # Извлекаем предмет из пути
        tmp=${file%/tests/*}
        subject=${tmp##*/}
        subjects["$subject"]=1

    done < <(sed 's/\r//g' "$file")
done

if [ "$count" -gt 0 ]; then
    avg_cents=$(( sum * 100 / count ))     # среднее ×100 (целое число)
    avg_int=$(( avg_cents / 100 ))         # целая часть
    avg_dec=$(( avg_cents % 100 ))         # дробная часть
    printf "Средний результат %s: %d.%02d правильных ответов\n" "$STUDENT" "$avg_int" "$avg_dec"

    echo "Всего тестов: $count"
    echo -n "Предметы: "
    for s in "${!subjects[@]}"; do printf "%s " "$s"; done
    echo
else
    echo "Нет данных для студента $STUDENT"
fi
