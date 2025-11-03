#!/bin/bash
# ===============================================
# ЛР4 — Интерактивное меню для запуска скриптов анализа
# ===============================================

# Определим папку, где лежит этот скрипт (scripts/)
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_FILE=""
SUBJECT=""

# ---------- Ввод пути и группы ----------
read -p "Введите путь к файловой системе преподавателя (например ./labfiles): " ROOT_DIR
if [ ! -d "$ROOT_DIR" ]; then
    echo "Ошибка: путь '$ROOT_DIR' не существует!"
    exit 1
fi

# Цикл ввода группы: пусто = все группы, иначе проверяем формат A-09-22 или Ae-21-21 (A или Ae)
while true; do
    read -p "Введите номер группы (например A-06-04, Enter — для всех групп): " GROUP
    if [ -z "$GROUP" ]; then
        # анализ по всем группы
        break
    fi
    if [[ "$GROUP" =~ ^(A|Ae)-[0-9]{2}-[0-9]{2}$ ]]; then
        break
    fi
    echo "Ошибка: номер группы введён неверно! Допустимые форматы: A-09-22 или Ae-21-21. Попробуйте снова."
done

# ---------- Выбор предмета ----------
while true; do
    read -p "Введите предмет (Поп-Культуроведение/Цирковое_Дело, Enter — оба предмета): " input_subject
    if [ -z "$input_subject" ]; then
        SUBJECT=""
        break
    elif [[ "$input_subject" == "Поп-Культуроведение" || "$input_subject" == "Цирковое_Дело" ]]; then
        # Проверяем существование папки предмета
        if find "$ROOT_DIR" -type d -name "$input_subject" | grep -q .; then
            SUBJECT="$input_subject"
            break
        else
            echo "Ошибка: предмет '$input_subject' не найден в указанной директории!"
        fi
    else
        echo "Ошибка: допустимые предметы: 'Поп-Культуроведение' или 'Цирковое_Дело'"
    fi
done

# ---------- Выбор вывода ----------
read -p "Выводить результаты в файл? (y/n): " save_to_file
if [[ "$save_to_file" =~ ^[YyДд]$ ]]; then
    read -p "Введите имя файла для сохранения результатов: " OUTPUT_FILE
fi

# ---------- Основное меню ----------
show_menu() {
    clear
    echo "==============================================="
    echo "       Лабораторная работа №4 — Анализ"
    echo "==============================================="
    echo "Путь к данным: $ROOT_DIR"
    if [ -n "$GROUP" ]; then
        echo "Текущая группа: $GROUP"
    else
        echo "Текущая группа: все группы"
    fi
    if [ -n "$SUBJECT" ]; then
        echo "Текущий предмет: $SUBJECT"
    else
        echo "Текущий предмет: оба предмета"
    fi
    if [ -n "$OUTPUT_FILE" ]; then
        echo "Вывод в файл: $OUTPUT_FILE"
    else
        echo "Вывод в консоль"
    fi
    echo "-----------------------------------------------"
    echo "1. Худшая посещаемость"
    echo "2. Лучший результат по тестам"
    echo "3. Min/Max посещаемость занятий"
    echo "4. Средняя оценка студента"
    echo "5. Полный анализ (lab4_analysis)"
    echo "6. Сменить группу/предмет/вывод"
    echo "7. Выход"
    echo "-----------------------------------------------"
}

# ---------- Вспомогательная функция для вызова скрипта ----------
call_script() {
    local script="$1"
    local extra_args="$2"
    # полный путь к целевому скрипту
    local target="$SCRIPTS_DIR/$script"
    if [ ! -f "$target" ]; then
        echo "Ошибка: скрипт '$target' не найден!"
        return 1
    fi
    if [ ! -x "$target" ]; then
        echo "Скрипт '$target' не исполняемый — пытаюсь добавить права..."
        chmod +x "$target" 2>/dev/null || { echo "Не удалось сделать исполняемым."; return 1; }
    fi

    echo
    echo ">>> Запуск $script ..."
    echo "-----------------------------------------------"
    
    # Если указан файл для вывода - перенаправляем вывод
    if [ -n "$OUTPUT_FILE" ]; then
        {
            echo "=== Результаты выполнения: $script ==="
            echo "Дата: $(date)"
            echo "Группа: ${GROUP:-все группы}"
            echo "Предмет: ${SUBJECT:-все предметы}"
            echo "-----------------------------------------------"
            # передаём аргументы: путь, группа, предмет, дополнительные аргументы
            "$target" "$ROOT_DIR" "$GROUP" "$SUBJECT" $extra_args
            echo "-----------------------------------------------"
        } >> "$OUTPUT_FILE"
        echo "Результаты сохранены в файл: $OUTPUT_FILE"
    else
        # передаём аргументы: путь, группа, предмет, дополнительные аргументы
        "$target" "$ROOT_DIR" "$GROUP" "$SUBJECT" $extra_args
    fi
    echo "-----------------------------------------------"
    return 0
}

# ---------- Смена группы и предмета ----------
change_settings() {
    # Смена группы
    while true; do
        read -p "Введите новый номер группы (Enter — для всех): " new_group
        if [ -z "$new_group" ]; then
            GROUP=""
            break
        fi
        if [[ "$new_group" =~ ^(A|Ae)-[0-9]{2}-[0-9]{2}$ ]]; then
            GROUP="$new_group"
            break
        fi
        echo "Ошибка: некорректный формат группы. Пример: A-06-04 или Ae-21-21."
    done
    
    # Смена предмета
    while true; do
        read -p "Введите предмет (Поп-Культуроведение/Цирковое_Дело, Enter — оба предмета): " new_subject
        if [ -z "$new_subject" ]; then
            SUBJECT=""
            break
        elif [[ "$new_subject" == "Поп-Культуроведение" || "$new_subject" == "Цирковое_Дело" ]]; then
            # Проверяем существование папки предмета
            if find "$ROOT_DIR" -type d -name "$new_subject" | grep -q .; then
                SUBJECT="$new_subject"
                break
            else
                echo "Ошибка: предмет '$new_subject' не найден в указанной директории!"
            fi
        else
            echo "Ошибка: допустимые предметы: 'Поп-Культуроведение' или 'Цирковое_Дело'"
        fi
    done
    
    # Смена вывода
    read -p "Выводить результаты в файл? (y/n): " save_to_file
    if [[ "$save_to_file" =~ ^[YyДд]$ ]]; then
        read -p "Введите имя файла для сохранения результатов: " OUTPUT_FILE
    else
        OUTPUT_FILE=""
    fi
}

# ---------- Основной цикл меню ----------
while true; do
    show_menu
    read -p "Выберите пункт меню (1-7): " choice
    echo

    case $choice in
        1)
            call_script "worst_attendance.sh"
            ;;
        2)
            call_script "best_results.sh"
            ;;
        3)
            call_script "class_extremes.sh"
            ;;
        4)
            read -p "Введите фамилию студента: " STUDENT_NAME
            call_script "student_average.sh" "$STUDENT_NAME"
            ;;
        5)
            call_script "lab4_analysis.sh"
            ;;
        6)
            change_settings
            ;;
        7)
            echo "Выход из программы..."
            exit 0
            ;;
        *)
            echo "Ошибка: выберите пункт от 1 до 7."
            ;;
    esac

    echo
    echo "-----------------------------------------------"
    read -p "Нажмите Enter для продолжения..."
done