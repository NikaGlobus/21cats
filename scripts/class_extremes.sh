#!/bin/bash
# Находит занятия с минимальной и максимальной посещаемостью
# Если предмет не указан — делает анализ по двум предметам отдельно

ROOT_DIR="$1"
GROUP="$2"
SUBJECT="$3"

if [ -z "$ROOT_DIR" ]; then
    echo "Использование: ./class_extremes.sh <путь_к_файлам_ЛР3> [группа] [предмет]"
    exit 1
fi

# ---------- Функция анализа для ОДНОГО предмета ----------
analyze_subject() {
    local SUBJECT_NAME="$1"

    echo
    echo "=============================================="
    echo "Анализ предмета: $SUBJECT_NAME"
    echo "=============================================="

    if [ -n "$GROUP" ]; then
        echo "Группа: $GROUP"
    else
        echo "Группа: все группы"
    fi
    echo

    # Поиск файлов посещаемости только для этого предмета
    ATTENDANCE_FILES=$(find "$ROOT_DIR" -type f -path "*/$SUBJECT_NAME/*-attendance" 2>/dev/null)

    if [ -z "$ATTENDANCE_FILES" ]; then
        echo "Файлы посещаемости не найдены для предмета '$SUBJECT_NAME'!"
        return
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
            return
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
        seq=$2

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
            if (count[i] < min) min=count[i]
            if (count[i] > max) max=count[i]
        }

        printf("Занятия с МИНИМАЛЬНОЙ посещаемостью (%d студентов): ", min)
        first=1
        for (i in count) {
            if (count[i]==min) {
                if (!first) printf(", ")
                printf("занятие %d", i)
                first=0
            }
        }
        print ""

        printf("Занятия с МАКСИМАЛЬНОЙ посещаемостью (%d студентов): ", max)
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

    rm -f "$TMP_STUDENTS"
}

# ---------- ОСНОВНАЯ ЛОГИКА ----------
if [ -n "$SUBJECT" ]; then
    # Один предмет → обычный вариант
    analyze_subject "$SUBJECT"
else
    # Оба предмета → анализ каждого отдельно
    analyze_subject "Поп-Культуроведение"
    analyze_subject "Цирковое_Дело"
fi
