//+------------------------------------------------------------------+
//|                                            DS-BreakoutProfit.mq5 |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#property script_show_inputs

#include "Include\DKStdLib\Common\DKStdLib.mqh"
#include "Include\DKStdLib\Logger\CDKLogger.mqh"
#include "Include\DKStdLib\License\DKLicense.mqh";
#include "Include\DKStdLib\TradingManager\CDKTrade.mqh"

#include "CBreakoutProfitBot.mqh"

input     group                    "1. ОСНОВНЫЕ НАСТРОЙКИ"
input     ENUM_TIMEFRAME_CUSTOM    InpDKLevelFT                          = TIMEFRAME_CUSTOM_D1;                 // InpDKLevelFT: Таймфрейм уровней
input     ENUM_BOT_MODE            TYPE                                  = BOT_MODE_BREAKOUT;                   // TYPE: Режим работы
input     ENUM_TP_TYPE             TypeTpSL                              = TP_TYPE_POINT;                       // TypeTpSL: Тип TP SL
input     uint                     gTP1                                  = 200;                                 // gTP1: TP 1
input     uint                     SL                                    = 200;                                 // SL: SL
input     ENUM_TIMEFRAME_CUSTOM    AtrTf                                 = TIMEFRAME_CUSTOM_D1;                 // AtrTF: Период ATR
input     uint                     AtrPeriod                             = 200;                                 // AtrPeriod: Период ATR
input     double                   AtrRatioTp                            = 1.0;                                 // AtrRatioTp: Коэффициент ATR TP
input     double                   AtrRatioSl                            = 1.0;                                 // AtrRatioSl: Коэффициент ATR SL
input     uint                     OP_Shift                              = 200;                                 // OP_Shift: Отступ
input     double                   gLot                                  = 0.01;                                // gLot: Лот
input     ulong                    Magic_Number                          = 202406251;                           // Magic_Number: Магик

input     group                    "2. БЕЗУБЫТОК"
input     uint                     points_to_breakeven                   = 120;                                 // points_to_breakeven: Расстояние для перевода в безубыток, пункт (0-откл.)
input     uint                     breakeven                             = 100;                                 // breakeven: Безубыток

input     group                    "3. ТРЕЙЛИНГ СТОП"
input     uint                     TralStart                             = 120;                                 // TralStart: Старт работы трейлинг стопа, пункт (0-откл.)
input     uint                     TralStep                              = 100;                                 // TralStep: Шаг трейлинг стопа

input     group                    "4. ФИЛЬТРЫ"
input     uint                     InpDKMaxSpreadToPlaceOrder            = 100;                                 // InpDKMaxSpreadToPlaceOrder: Макс. спред для размещения ордера (0-откл.)

input     bool                     Close_at_the_end_of_the_day           = true;                                // Close_at_the_end_of_the_day: Закрывать в конце дня
input     uint                     Hour_closing                          = 20;                                  // Hour_closing: Час закрытия

input     bool                     gFlagDay1                             = true;                                // gFlagDay1: Торговать в понедельник
input     uint                     gDay1H1                               = 1;                                   // gDay1H1: Начало торгов понедельника
input     uint                     gDay1H2                               = 22;                                  // gDay1H2: Конец торгов понедельника

input     bool                     gFlagDay2                             = true;                                // gFlagDay2: Торговать во вторник
input     uint                     gDay2H1                               = 1;                                   // gDay2H1: Начало торгов вторника
input     uint                     gDay2H2                               = 22;                                  // gDay2H2: Конец торгов вторника

input     bool                     gFlagDay3                             = true;                                // gFlagDay3: Торговать в среду
input     uint                     gDay3H1                               = 1;                                   // gDay3H1: Начало торгов среды
input     uint                     gDay3H2                               = 22;                                  // gDay3H2: Конец торгов среды

input     bool                     gFlagDay4                             = true;                                // gFlagDay4: Торговать в четверг
input     uint                     gDay4H1                               = 1;                                   // gDay4H1: Начало торгов четверга
input     uint                     gDay4H2                               = 22;                                  // gDay4H2: Конец торгов четверга

input     bool                     gFlagDay5                             = true;                                // gFlagDay5: Торговать в пятницу
input     uint                     gDay5H1                               = 1;                                   // gDay5H1: Начало торгов пятницы
input     uint                     gDay5H2                               = 22;                                  // gDay5H2: Конец торгов пятницы

input     string                   CommentSet                            = "DSBOP";                             // CommentSet: Комментарий

input     group                    "5. ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ"
sinput    bool                     InpCommentEnable                      = true;                                // MS.CE: Comment Enable (turn off in tester for speed)
sinput    uint                     InpCommentIntervalSec                 = 1*60;                                // MS.CI: Comment Interval update, sec
sinput    LogLevel                 InpLL                                 = LogLevel(INFO);                      // MS.LL: Log Level


CBreakoutProfitBot                 bot;
CDKTrade                           trade;
CDKLogger                          logger;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){  
  logger.Init(CommentSet, InpLL);
  
  trade.Init(Symbol(), Magic_Number, 0, GetPointer(logger));
  bot.CommentEnable = InpCommentEnable;
  bot.CommentIntervalSec = InpCommentIntervalSec;
  bot.TYPE = TYPE;
  bot.TypeTpSL = TypeTpSL;
  bot.gTP1 = gTP1;
  bot.SL = SL;
  bot.AtrTf = EnumTimeframeCustomToDefault(AtrTf);
  bot.AtrPeriod = AtrPeriod;
  bot.AtrRatioTp = AtrRatioTp;
  bot.AtrRatioSl = AtrRatioSl;
  bot.OP_Shift = OP_Shift;
  bot.gLot = gLot;
  bot.Magic_Number = Magic_Number;
  bot.points_to_breakeven = points_to_breakeven;
  bot.breakeven = breakeven;
  bot.TralStart = TralStart;
  bot.TralStep = TralStep;
  bot.DKMaxSpreadToPlaceOrder = InpDKMaxSpreadToPlaceOrder;
  bot.Close_at_the_end_of_the_day = Close_at_the_end_of_the_day;
  bot.Hour_closing = Hour_closing;
  bot.gFlagDay1 = gFlagDay1;
  bot.gDay1H1 = gDay1H1;
  bot.gDay1H2 = gDay1H2;
  bot.gFlagDay2 = gFlagDay2;
  bot.gDay2H1 = gDay2H1;
  bot.gDay2H2 = gDay2H2;
  bot.gFlagDay3 = gFlagDay3;
  bot.gDay3H1 = gDay3H1;
  bot.gDay3H2 = gDay3H2;
  bot.gFlagDay4 = gFlagDay4;
  bot.gDay4H1 = gDay4H1;
  bot.gDay4H2 = gDay4H2;
  bot.gFlagDay5 = gFlagDay5;
  bot.gDay5H1 = gDay5H1;
  bot.gDay5H2 = gDay5H2;  
  bot.Init(Symbol(), EnumTimeframeCustomToDefault(InpDKLevelFT), Magic_Number, trade, GetPointer(logger));
  
  if (!bot.Check()) return(INIT_PARAMETERS_INCORRECT);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  {
//--- destroy timer
   EventKillTimer();
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()  {
  bot.OnTick();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()  {
  bot.OnTimer();
}

//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()  {
  bot.OnTrade();
}

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {

   
  }

