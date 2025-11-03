#!/bin/bash
# ЛР4 — Анализ тестов: студент с максимальным количеством правильных ответов

ROOT_DIR="$1"
GROUP="$2"
SUBJECT="$3"

if [ -z "$ROOT_DIR" ]; then
    echo "Ошибка: путь к данным не указан!"
    exit 1
fi

# Проверка наличия директории
if [ ! -d "$ROOT_DIR" ]; then
    echo "Ошибка: указанная директория '$ROOT_DIR' не существует!"
    exit 1
fi

echo
echo "=== Анализ результатов тестов ==="
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

# Поиск файлов тестов с учетом предмета и папки tests
if [ -n "$SUBJECT" ]; then
    FILES=$(find "$ROOT_DIR" -type f -path "*/$SUBJECT/tests/TEST-*" 2>/dev/null)
else
    FILES=$(find "$ROOT_DIR" -type f \( -path "*/Поп-Культуроведение/tests/TEST-*" -o -path "*/Цирковое_Дело/tests/TEST-*" \) 2>/dev/null)
fi

if [ -z "$FILES" ]; then
    echo "Файлы тестов не найдены!"
    exit 1
fi

awk -F';' -v grp="$GROUP" '
{
    if (NF>=4) {
        g=$1
        name=$2
        correct=$4
        if (correct~/^[0-9]+$/) {
            if (grp=="" || g==grp)
                total[name]+=correct
        }
    }
}
END {
    if (length(total)==0) {
        print "Нет данных о тестах."
        exit
    }
    max=0
    for (n in total) if (total[n]>max) max=total[n]
    print "Максимальное количество правильных ответов:", max
    for (n in total)
        if (total[n]==max)
            print "→", n, "-", total[n], "ответов"
}' $FILES