# ComDig-Test-Task

### Тестовое задание:
> Написать sql-скрипт, который пройдет по всем таблицам всей БД и изменит поле row_num с varchar(10) на int4 и сделает его not null. БД - Postgresql.

### Описание решения:

Решение разработано для более общего случая: поля могут иметь тип `varchar` произвольной длины, значения полей могут быть засорены посторонними символами, либо значения числа строки выходит из диапазона значений 4-байтного `int4`
