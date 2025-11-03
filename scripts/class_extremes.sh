#!/bin/bash
# Находит занятия с минимальной и максимальной общей посещаемостью

ROOT_DIR="$1"
GROUP="$2"
SUBJECT="$3"

if [ -z "$ROOT_DIR" ]; then
    echo "Использование: ./class_extremes.sh <путь_к_файлам_ЛР3> [группа] [предмет]"
    exit 1
fi

echo "=== Анализ посещаемости занятий ==="
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
echo "Поиск занятий с минимальной и максимальной посещаемостью..."
echo

# Находим файлы посещаемости с учетом предмета
if [ -n "$SUBJECT" ]; then
    ATTENDANCE_FILES=$(find "$ROOT_DIR" -type f -path "*/$SUBJECT/*-attendance" 2>/dev/null)
else
    ATTENDANCE_FILES=$(find "$ROOT_DIR" -type f \( -path "*/Поп-Культуроведение/*-attendance" -o -path "*/Цирковое_Дело/*-attendance" \) 2>/dev/null)
fi

if [ -z "$ATTENDANCE_FILES" ]; then
    echo "Файлы посещаемости не найдены!"
    exit 1
fi

# Если указана группа — создаём временный список студентов
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
    echo "" > "$TMP_STUDENTS"
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
/^[^#]/ && NF==2 {
    name=$1
    seq=$2
    
    # Если группа указана - проверяем студента
    if (grp=="" || name in allowed) {
        for (i=1;i<=length(seq);i++) {
            if (substr(seq,i,1)=="1") {
                count[i]++
            }
        }
    }
}
END {
    if (length(count)==0) {
        print "Нет данных о посещаемости."
        exit
    }
    
    min=9999; max=0
    for (i in count) {
        if (count[i]<min) min=count[i]
        if (count[i]>max) max=count[i]
    }
    
    printf("Занятия с минимальной посещаемостью (%d студентов): ", min)
    first=1
    for (i in count) {
        if (count[i]==min) {
            if (!first) printf(", ")
            printf("занятие %d", i)
            first=0
        }
    }
    print ""
    
    printf("Занятия с максимальной посещаемостью (%d студентов): ", max)
    first=1
    for (i in count) {
        if (count[i]==max) {
            if (!first) printf(", ")
            printf("занятие %d", i)
            first=0
        }
    }
    print ""
}' $ATTENDANCE_FILES

# Удаляем временный файл
rm -f "$TMP_STUDENTS"