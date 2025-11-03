#!/bin/bash
# Среднее количество правильных ответов студента по предмету

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

# Находим файлы тестов с учетом предмета и папки tests
if [ -n "$SUBJECT" ]; then
    TEST_FILES=$(find "$ROOT_DIR" -type f -path "*/$SUBJECT/tests/TEST-*" 2>/dev/null)
else
    TEST_FILES=$(find "$ROOT_DIR" -type f \( -path "*/Поп-Культуроведение/tests/TEST-*" -o -path "*/Цирковое_Дело/tests/TEST-*" \) 2>/dev/null)
fi

if [ -z "$TEST_FILES" ]; then
    echo "Файлы тестов не найдены!"
    exit 1
fi

awk -F';' -v name="$STUDENT" -v grp="$GROUP" '
{
    if ($2==name && $4~/^[0-9]+$/) {
        if (grp=="" || $1==grp) {
            sum+=$4
            n++
            # Собираем информацию о предметах
            subject = FILENAME
            sub(".*/", "", subject)
            sub("/tests/TEST-.*", "", subject)
            subjects[subject]++
        }
    }
}
END {
    if (n>0) {
        printf("Средний результат %s: %.2f правильных ответов\n", name, sum/n)
        printf("Всего тестов: %d\n", n)
        printf("Предметы: ")
        first=1
        for (subj in subjects) {
            if (!first) printf(", ")
            printf("%s", subj)
            first=0
        }
        print ""
    } else {
        print "Нет данных для студента", name
        if (grp != "") print "Проверьте правильность группы и фамилии"
    }
}' $TEST_FILES