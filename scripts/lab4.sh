#!/bin/bash
# ===============================================
# ЛР4 — Интерактивное меню для запуска скриптов анализа
# ===============================================

# Определим папку, где лежит этот скрипт (scripts/)
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_FILE=""
SUBJECT=""
GROUP=""

# ---------- Ввод пути ----------
while true; do
    read -p "Введите путь к файловой системе преподавателя (например ./labfiles): " input_dir
    if [ -z "$input_dir" ]; then
        echo "Ошибка: путь не может быть пустым! Попробуйте снова."
        continue
    fi
    if [ ! -d "$input_dir" ]; then
        echo "Ошибка: путь '$input_dir' не существует! Попробуйте снова."
        continue
    fi
    ROOT_DIR="$input_dir"
    break
done

# ---------- Ввод группы (первичное) ----------
while true; do
    read -p "Введите номер группы (например A-06-04, all/All/Enter — оба предмета): " new_group

    # Enter — все группы (первичный ввод)
    if [ -z "$new_group" ]; then
        GROUP=""
        break
    fi

    # a/A → оба предмета
    if [[ "$new_group" == "all" || "$new_group" == "All" ]]; then
        GROUP=""
        break
    fi


    if ! [[ "$new_group" =~ ^(A|Ae)-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "Ошибка: неверный формат! Примеры: A-09-22 или Ae-21-21."
        continue
    fi

    if [ ! -f "$ROOT_DIR/students/groups/$new_group" ]; then
        echo "Ошибка: группы '$new_group' нет в базе!"
        continue
    fi

    GROUP="$new_group"
    break
done

# ---------- Выбор предмета (первичное) ----------
while true; do
    read -p "Введите предмет (Поп-Культуроведение/Цирковое_Дело, B/b/Enter — оба предмета): " input_subject

    # Enter → оба предмета (первичный ввод)
    if [ -z "$input_subject" ]; then
        SUBJECT=""
        break
    fi

    # b/B → оба предмета
    if [[ "$input_subject" == "b" || "$input_subject" == "B" ]]; then
        SUBJECT=""
        break
    fi

    # Конкретный предмет
    if [[ "$input_subject" == "Поп-Культуроведение" || "$input_subject" == "Цирковое_Дело" ]]; then
        if find "$ROOT_DIR" -type d -name "$input_subject" | grep -q .; then
            SUBJECT="$input_subject"
            break
        else
            echo "Ошибка: предмет '$input_subject' не найден!"
        fi
    else
        echo "Ошибка: допустимые предметы: Поп-Культуроведение, Цирковое_Дело, b"
    fi
done

# ---------- Выбор вывода (первичное) ----------
read -p "Выводить результаты в файл? (y - в файл, Enter — в консоль): " save_to_file
if [[ "$save_to_file" =~ ^[YyДд]$ ]]; then
    read -p "Введите имя файла для сохранения результатов: " fname
    if [ -n "$fname" ]; then
        OUTPUT_FILE="$fname"
    fi
fi

# ---------- Меню ----------
show_menu() {
    clear
    echo "==============================================="
    echo "       Лабораторная работа №4 — Анализ"
    echo "==============================================="
    echo "Путь к данным: $ROOT_DIR"
    echo "Текущая группа: ${GROUP:-все группы}"
    echo "Текущий предмет: ${SUBJECT:-оба предмета}"
    echo "Вывод: ${OUTPUT_FILE:-консоль}"
    echo "-----------------------------------------------"
    echo "1. Худшая посещаемость"
    echo "2. Лучший результат по тестам"
    echo "3. Min/Max посещаемость занятий"
    echo "4. Средняя оценка студента"
    echo "5. Полный анализ"
    echo "6. Сменить группу/предмет/вывод"
    echo "7. Выход"
    echo "-----------------------------------------------"
}

# ---------- Вызов скриптов ----------
call_script() {
    local script="$1"
    local extra_args="$2"
    local target="$SCRIPTS_DIR/$script"

    if [ ! -f "$target" ]; then
        echo "Ошибка: скрипт '$target' не найден!"
        return 1
    fi

    if [ ! -x "$target" ]; then
        chmod +x "$target" 2>/dev/null || {
            echo "Не удалось сделать скрипт исполняемым."
            return 1
        }
    fi

    if [ -n "$OUTPUT_FILE" ]; then
        {
            echo "=== Результаты выполнения: $script ==="
            echo "Дата: $(date)"
            echo "Группа: ${GROUP:-все группы}"
            echo "Предмет: ${SUBJECT:-все предметы}"
            echo "-----------------------------------------------"
            "$target" "$ROOT_DIR" "$GROUP" "$SUBJECT" $extra_args
            echo "-----------------------------------------------"
        } >> "$OUTPUT_FILE"
        echo "Сохранено в файл: $OUTPUT_FILE"
    else
        "$target" "$ROOT_DIR" "$GROUP" "$SUBJECT" $extra_args
    fi
}

# ---------- Смена параметров ----------
change_settings() {

    # --- Группа ---
    while true; do
	echo "Конкректная группа / all/All (обе группы)"
        read -p "Введите номер группы (Enter — оставить '${GROUP:-все группы}'): " new_group

        # Enter — оставить текущее значение
        if [ -z "$new_group" ]; then
            break
        fi

    	# a/A → оба предмета
    	if [[ "$new_group" == "all" || "$new_group" == "All" ]]; then
        	GROUP=""
        	break
   	fi

        if ! [[ "$new_group" =~ ^(A|Ae)-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "Ошибка: неверный формат группы!"
            continue
        fi

        if [ ! -f "$ROOT_DIR/students/groups/$new_group" ]; then
            echo "Ошибка: такой группы нет!"
            continue
        fi

        GROUP="$new_group"
        break
    done

    # --- Предмет ---
    while true; do
        echo "Варианты: Поп-Культуроведение / Цирковое_Дело / B/b (оба предмета)"
        read -p "Введите предмет (Enter — оставить '${SUBJECT:-оба предмета}'): " new_subject

        # Enter — оставить текущее значение
        if [ -z "$new_subject" ]; then
            break
        fi

        # b/B — оба предмета
        if [[ "$new_subject" == "b" || "$new_subject" == "B" ]]; then
            SUBJECT=""
            break
        fi

        if [[ "$new_subject" == "Поп-Культуроведение" || "$new_subject" == "Цирковое_Дело" ]]; then
            if find "$ROOT_DIR" -type d -name "$new_subject" | grep -q .; then
                SUBJECT="$new_subject"
                break
            else
                echo "Ошибка: предмет '$new_subject' не найден!"
            fi
        else
            echo "Ошибка: допустимые значения: Поп-Культуроведение, Цирковое_Дело, b"
        fi
    done

    # --- Вывод ---
    # Сохранить текущее значение, если Enter
    read -p "Выводить в файл? (y - в файл, n - в консоль, Enter — оставить '${OUTPUT_FILE:-консоль}'): " save_choice

    if [ -z "$save_choice" ]; then
        # оставить как есть
        return
    fi

    if [[ "$save_choice" =~ ^[YyДд]$ ]]; then
        read -p "Введите имя файла (Enter — оставить '${OUTPUT_FILE:-консоль}'): " newfile
        if [ -n "$newfile" ]; then
            OUTPUT_FILE="$newfile"
        fi
    else
        # любой другой ответ, в том числе 'n' -> выключить вывод в файл
        OUTPUT_FILE=""
    fi
}

# ---------- Основной цикл ----------
while true; do
    show_menu
    read -p "Выберите пункт меню (1-7): " choice
    echo

    case $choice in
        1) call_script "worst_attendance.sh" ;;
        2) call_script "best_results.sh" ;;
        3) call_script "class_extremes.sh" ;;
        4)
            read -p "Введите фамилию студента: " STUDENT_NAME
            call_script "student_average.sh" "$STUDENT_NAME"
            ;;
        5) call_script "lab4_analysis.sh" ;;
        6) change_settings ;;
        7)
            echo "Выход..."
            exit 0
            ;;
        *)
            echo "Ошибка: выберите пункт 1–7."
            ;;
    esac

    echo
    read -p "Нажмите Enter чтобы продолжить..." _
done
