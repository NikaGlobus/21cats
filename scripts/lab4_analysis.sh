#!/bin/bash
# ЛР4. Анализ посещаемости и результатов тестов

ROOT_DIR="$1"     # путь к файловой системе преподавателя
GROUP="$2"        # номер группы, например A-06-22
SUBJECT="$3"      # предмет

if [ -z "$ROOT_DIR" ]; then
    echo "Использование: ./lab4_analysis.sh <путь_к_файлам_ЛР3> [номер_группы] [предмет]"
    exit 1
fi

echo "=== Полный анализ ==="
if [ -n "$GROUP" ]; then
    echo "Группа: $GROUP"
else
    echo "Группа: все группы"
fi
if [ -n "$SUBJECT" ]; then
    echo "Предмет: $SUBJECT"
else
    echo "Предмет: оба предмета"
fi
echo

# ----------- 1. Студент с наихудшей посещаемостью ------------
echo "1. Студент с наихудшей посещаемостью:"

# Находим файлы посещаемости с учетом предмета
if [ -n "$SUBJECT" ]; then
    ATTENDANCE_FILES=$(find "$ROOT_DIR" -type f -path "*/$SUBJECT/*-attendance" 2>/dev/null)
else
    ATTENDANCE_FILES=$(find "$ROOT_DIR" -type f \( -path "*/Поп-Культуроведение/*-attendance" -o -path "*/Цирковое_Дело/*-attendance" \) 2>/dev/null)
fi

if [ -z "$ATTENDANCE_FILES" ]; then
    echo "   Файлы посещаемости не найдены!"
else
    # Если указана группа — создаём временный список студентов
    TMP_STUDENTS=$(mktemp)
    if [ -n "$GROUP" ]; then
        GROUP_FILE=$(find "$ROOT_DIR" -type f -path "*/students/groups/$GROUP" 2>/dev/null | head -n1)
        if [ -f "$GROUP_FILE" ]; then
            cat "$GROUP_FILE" | tr -d '\r' | sort | uniq > "$TMP_STUDENTS"
        else
            echo "   Группа '$GROUP' не найдена!"
            rm -f "$TMP_STUDENTS"
            exit 1
        fi
    else
        echo "" > "$TMP_STUDENTS"
    fi

    awk -v grp="$GROUP" -v groupfile="$TMP_STUDENTS" '
    BEGIN {
        while ((getline s < groupfile) > 0) {
            gsub(/\r/,"",s)
            gsub(/^\s+|\s+$/,"",s)
            if (s!="") allowed[s]=1
        }
    }
    /^[^#]/ && NF==2 {
        name=$1
        gsub(/[^01]/,"",$2)
        c=gsub(/1/,"1",$2)
        if (grp=="" || name in allowed) {
            total[name]+=c
        }
    }
    END {
        if (length(total)==0) {
            print "   Нет данных о посещаемости."
            exit
        }
        min=99999
        for (n in total) {
            if (total[n]<min) min=total[n]
        }
        for (n in total) {
            if (total[n]==min) print "   → " n " - " total[n] " посещений"
        }
    }' $ATTENDANCE_FILES

    rm -f "$TMP_STUDENTS"
fi

# ----------- 2. Студент с макс. количеством правильных ответов ------------
echo
echo "2. Студент с максимальным количеством правильных ответов:"

# Находим файлы тестов с учетом предмета и папки tests
if [ -n "$SUBJECT" ]; then
    TEST_FILES=$(find "$ROOT_DIR" -type f -path "*/$SUBJECT/tests/TEST-*" 2>/dev/null)
else
    TEST_FILES=$(find "$ROOT_DIR" -type f \( -path "*/Поп-Культуроведение/tests/TEST-*" -o -path "*/Цирковое_Дело/tests/TEST-*" \) 2>/dev/null)
fi

if [ -z "$TEST_FILES" ]; then
    echo "   Файлы тестов не найдены!"
else
    awk -F';' -v grp="$GROUP" '
    {
        if (NF>=4) {
            correct=$4
            if (correct~/^[0-9]+$/) {
                if (grp=="" || $1==grp) {
                    total[$2]+=correct
                }
            }
        }
    }
    END {
        if (length(total)==0) {
            print "   Нет данных о тестах."
            exit
        }
        max=0
        for (n in total) {
            if (total[n]>max) max=total[n]
        }
        for (n in total) {
            if (total[n]==max) print "   → " n " - " total[n] " правильных ответов"
        }
    }' $TEST_FILES
fi