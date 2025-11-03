#!/bin/bash
# ЛР4 — Анализ посещаемости: студент с наихудшей посещаемостью

ROOT_DIR="$1"
GROUP="$2"
SUBJECT="$3"

if [ -z "$ROOT_DIR" ]; then
    echo "Ошибка: путь к данным не указан!"
    exit 1
fi

# Проверка директории
if [ ! -d "$ROOT_DIR" ]; then
    echo "Ошибка: директория '$ROOT_DIR' не найдена!"
    exit 1
fi

echo
echo "=== Анализ посещаемости ==="
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

# Находим файлы посещаемости с учетом предмета
if [ -n "$SUBJECT" ]; then
    FILES=$(find "$ROOT_DIR" -type f -path "*/$SUBJECT/*-attendance" 2>/dev/null)
else
    FILES=$(find "$ROOT_DIR" -type f \( -path "*/Поп-Культуроведение/*-attendance" -o -path "*/Цирковое_Дело/*-attendance" \) 2>/dev/null)
fi

if [ -z "$FILES" ]; then
    echo "Файлы посещаемости не найдены!"
    exit 1
fi

# Если указана группа — создаём временный список допустимых студентов
TMP_STUDENTS=$(mktemp)
if [ -n "$GROUP" ]; then
    GROUP_FILE=$(find "$ROOT_DIR" -type f -path "*/students/groups/$GROUP" 2>/dev/null | head -n1)
    if [ -f "$GROUP_FILE" ]; then
        cat "$GROUP_FILE" | tr -d '\r' | sort | uniq > "$TMP_STUDENTS"
    else
        echo "Группа '$GROUP' не найдена!"
        rm -f "$TMP_STUDENTS"
        exit 1
    fi
else
    echo "" > "$TMP_STUDENTS" # пустой (все студенты допускаются)
fi

awk -v grp="$GROUP" -v groupfile="$TMP_STUDENTS" '
BEGIN {
    # Загружаем список студентов группы, если есть
    while ((getline s < groupfile) > 0) {
        gsub(/\r/,"",s)
        gsub(/^\s+|\s+$/,"",s)
        if (s!="") allowed[s]=1
    }
}
{
    if (NF==2) {
        name=$1
        seq=$2
        gsub(/[^01]/,"",seq)
        c=gsub(/1/,"1",seq)

        # Если группы нет — считаем всех
        # Если группа указана — только разрешённых студентов
        if (grp=="" || name in allowed)
            total[name]+=c
    }
}
END {
    if (length(total)==0) {
        print "Нет данных о посещаемости."
        exit
    }
    min=99999
    for (n in total)
        if (total[n]<min) min=total[n]
    print "Минимальное количество посещений:", min
    for (n in total)
        if (total[n]==min)
            print "→", n, "-", total[n], "занятий"
}' $FILES

# Удаляем временный файл
rm -f "$TMP_STUDENTS"