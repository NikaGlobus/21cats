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

# ДОБАВЛЕНО: ассоциативные массивы для групп
declare -A group_sum
declare -A group_count

for file in $TEST_FILES; do
    while IFS=';' read -r grp name _ score _; do

        # Проверка фамилии
        [ "$name" != "$STUDENT" ] && continue
        
        # Проверка группы (если указана)
        if [ -n "$GROUP" ]; then
            [ "$grp" != "$GROUP" ] && continue
        fi
        
        # Проверка что score — число
        [[ "$score" =~ ^[0-9]+$ ]] || continue
        
        # Общие данные
        sum=$((sum + score))
        count=$((count + 1))

        # ПО ГРУППАМ
        group_sum["$grp"]=$(( group_sum["$grp"] + score ))
        group_count["$grp"]=$(( group_count["$grp"] + 1 ))

        # Извлекаем предмет
        tmp=${file%/tests/*}
        subject=${tmp##*/}
        subjects["$subject"]=1

    done < <(sed 's/\r//g' "$file")
done


if [ "$count" -gt 0 ]; then
    echo "Результаты по группам:"
    for grp in "${!group_sum[@]}"; do
        s=${group_sum["$grp"]}
        c=${group_count["$grp"]}
        avg_cents=$(( s * 100 / c ))
        avg_int=$(( avg_cents / 100 ))
        avg_dec=$(( avg_cents % 100 ))
        printf "Группа %s: %d.%02d правильных ответов (тестов: %d)\n" "$grp" "$avg_int" "$avg_dec" "$c"
    done

    echo
    echo -n "Предметы: "
    for s in "${!subjects[@]}"; do printf "%s " "$s"; done
    echo
else
    echo "Нет данных для студента $STUDENT"
fi
