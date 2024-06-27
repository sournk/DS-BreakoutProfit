# DS-BreakoutProfit
Советник для MetaTrader 5. Торгует пробои или отскоки от дневных минимумов/максимумов.

* Разработчик: Denis Kislitsyn | denis@kislitsyn.me | [kislitsyn.me](https://kislitsyn.me)
* Версия: 0.0.1

## Установка
1. Убедитесь, что ваш терминал MetaTrader 5 обновлен до последней версии. Для тестирования советников рекомендуется обновить терминал до самой последней бета-версии. Для этого запустите обновление из главного меню `Help->Check For Updates->Latest Beta Version`. На прошлых версиях советник может не запускаться, потому что скомпилирован на последней версии терминала. В этом случае вы увидите сообщения на вкладке `Journal` об этом.
2. Скопируйте исполняемый файл бота `*.ex5` в каталог данных терминала `MQL5\Experts\`.
3. Откройте график пары.
4. Переместите советника из окна Навигатор на график.
5. Установите в настройках бота галочку `Allow Auto Trading`.
6. Включите режим автоторговли в терминале, нажав кнопку `Algo Trading` на главной панели инструментов.

## Стратегия
Советник основан на торговой стратегии советника [BreakoutProfit](https://www.youtube.com/watch?v=N93miZ-gFiE) для MT4.

> **ВНИМАНИЕ! ВАЖНО:** 
> 1. Пресеты от исходного советника для MT4 могут быть загружены и в эту версию советника.
> 2. ==Для некоторых торговых пар настройки для MT4 могут сильно отличаться в MT5 или для вашего конкретного брокера.== Например, настройки исходного советника для XAUUSD сделаны с учетом 2-х знаков после запятой в MT4. Большая часть брокеров перешла на 3-и знака для золота. Поэтому все расстояния из настроек в пунктах должны быть пересчитаны в x10 раз.

## Как работает бот?

-
-
-
-

## Недостатки


## Настройки

### 1. Основные настройки
- [x] `TYPE`: Режим работы
    - [x] `На отбой` 
    - [x] `На пробой`
- [x] `TypeTpSL`: Тип TP SL
    - [x] `По пунктам (ориг. пипсам)` 
    - [x] `По ATR`
- [x] `gTP1`: TP 1
- [x] `SL`: SL
- [x] `AtrTf`: Период ATR
- [x] `AtrPeriod`: Период ATR
- [x] `AtrRatioTp`: Коэффициент ATR TP
- [x] `AtrRatioSl`: Коэффициент ATR SL
- [x] `OP_Shift`: Отступ
- [x] `gLot`: Лот
- [x] `Magic_Number`: Магик

### 2. Безубыток
- [x] `points_to_breakeven`: Расстояние для перевода в безубыток, пункт (0-откл.)
- [x] `breakeven`: Безубыток

### 3. Трейлинг стоп
- [x] `TralStart`: Старт работы трейлинг стопа, пункт (0-откл.)
- [x] `TralStep`: Шаг трейлинг стопа

### 4. Фильтр
- [ ] `Close_at_the_end_of_the_day`: Закрывать в конце дня
- [ ] `Hour_closing`: Час закрытия
- [x] `gFlagDay1`: Торговать в понедельник
- [x] `gDay1H1`: Начало торгов понедельника
- [x] `gDay1H2`: Конец торгов понедельника
- [x] `gFlagDay2`: Торговать во вторник
- [x] `gDay2H1`: Начало торгов вторника
- [x] `gDay2H2`: Конец торгов вторника
- [x] `gFlagDay3`: Торговать в среду
- [x] `gDay3H1`: Начало торгов среды
- [x] `gDay3H2`: Конец торгов среды
- [x] `gFlagDay4`: Торговать в четверг
- [x] `gDay4H1`: Начало торгов четверга
- [x] `gDay4H2`: Конец торгов четверга
- [x] `gFlagDay5`: Торговать в пятницу
- [x] `gDay5H1`: Начало торгов пятницы
- [x] `gDay5H2`: Конец торгов пятницы
- [ ] `CommentSet`: Комментарий

### Основные фичи
- [x] Если цена в момент размещения ордеров вне диапазона, то бот ни один открывает ни один ордер (XAUUSD, 2017-03-27).

### Доп. фичи
